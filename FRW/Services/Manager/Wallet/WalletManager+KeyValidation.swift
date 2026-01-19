//
//  WalletManager+KeyValidation.swift
//  FRW
//
//  Created by Claude on 2026/01/19.
//

import Flow
import FlowWalletKit
import Foundation

// MARK: - Key Validation Result

enum KeyValidationResult {
  case active(Flow.AccountKey)      // Key is active on-chain
  case revoked                       // Key is revoked on-chain
  case pendingAccount                // Account not on-chain yet (newly created)
  case noAccountOldKey               // No account found and key is old
}

// MARK: - Key Validation

extension WalletManager {

  /// Find active key for a user ID (for login/switch profile)
  /// Returns the active account key and key provider, or throws if no active key found
  func findActiveKeyAndAccount(uid: String) async throws -> (Flow.AccountKey, any KeyProtocol) {
    guard let userStore = userStore(with: uid) else {
      throw LLError.accountNotFound
    }

    // Get main account address for validation
    // Don't use userStore.address as it might be child account or EVM address
    let mainAddress = getPrimaryWalletAddress()

    if let result = try await findActiveKeyForProfile(uid: uid, keyType: userStore.keyType, address: mainAddress) {
      // Update userStore with the correct active key's publicKey
      let publicKey = result.1.publicKey(signAlgo: .ECDSA_P256)?.hexString ??
                      result.1.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString ?? ""

      if userStore.publicKey != publicKey {
        log.info("[KeyValidation] Updating userStore with correct active key publicKey")
        let updatedStore = UserManager.StoreUser(
          publicKey: publicKey,
          address: userStore.address,
          userId: uid,
          keyType: userStore.keyType,
          account: result.0.toStoreKey()
        )
        LocalUserDefaults.shared.addUser(user: updatedStore)
      }

      return result
    } else {
      throw LLError.cannotFindFlowAccount
    }
  }

  /// Find and initialize wallet with an active key from local storage
  func initWalletWithActiveKey() async {
    guard let uid = UserManager.shared.activatedUID,
          let userStore = userStore(with: uid) else {
      log.error("[KeyValidation] User not found")
      return
    }

    // Check if this is a newly created key (within last 5 minutes)
    // For new keys, skip validation and use fallback behavior to avoid false "No active key" errors
    let storage = getStorage(for: userStore.keyType)
    let allKeys = KeyProvider.keys(with: uid, in: storage)

    if let latestKey = allKeys.last,
       let keyCreationTime = getKeyCreationTime(keyId: latestKey) {
      let timeSinceCreation = Date().timeIntervalSince(keyCreationTime)

      // If key was created in last 5 minutes, skip validation (new account not yet on-chain)
      if timeSinceCreation < 5 * 60 {
        log.info("[KeyValidation] ⏭️ Skipping validation for newly created key (\(Int(timeSinceCreation))s ago)")
        await fallbackToOldBehavior(uid: uid)
        return
      }
    }

    do {
      // Get main account address for validation
      // Don't use userStore.address as it might be child account or EVM address
      let mainAddress = getPrimaryWalletAddress()

      // Find active key from local storage
      if let (activeKey, activeProvider) = try await findActiveKeyForProfile(
        uid: uid,
        keyType: userStore.keyType,
        address: mainAddress
      ) {
        // Initialize wallet with active key
        await initializeWithKey(
          provider: activeProvider,
          accountKey: activeKey,
          uid: uid,
          userStore: userStore
        )
      } else {
        // No active key found
        log.error("[KeyValidation] No active key found")
        await notifyWalletKeyInvalid(uid: uid, reason: "No active key found")
      }
    } catch {
      log.error("[KeyValidation] Error: \(error)")
      await fallbackToOldBehavior(uid: uid)
    }
  }

  /// Find active key by checking all local keys against mainnet
  private func findActiveKeyForProfile(
    uid: String,
    keyType: FlowWalletKit.KeyType,
    address: String?
  ) async throws -> (Flow.AccountKey, any KeyProtocol)? {

    // Get storage and all keys
    let storage = getStorage(for: keyType)
    let allKeys = KeyProvider.keys(with: uid, in: storage)
    let pw = KeyProvider.password(with: uid)

    log.info("[KeyValidation] Checking \(allKeys.count) local keys for uid: \(uid)")
    log.debug("[KeyValidation] Keys: \(allKeys.joined(separator: ", "))")

    var revokedKeyIds: [String] = []
    var pendingProvider: (any KeyProtocol)? = nil

    for keyId in allKeys {
      log.debug("[KeyValidation] Checking key: \(keyId)")
      // Load key provider
      guard let provider = try loadKeyProvider(
        keyId: keyId,
        keyType: keyType,
        password: pw,
        storage: storage
      ) else {
        continue
      }

      // Validate this key on mainnet
      let result = await validateKeyOnMainnet(provider: provider, keyId: keyId, address: address)

      switch result {
      case .active(let accountKey):
        log.info("[KeyValidation] ✅ Found active key: \(keyId)")
        return (accountKey, provider)

      case .revoked:
        log.warning("[KeyValidation] ❌ Key revoked: \(keyId)")
        revokedKeyIds.append(keyId)

      case .pendingAccount:
        log.info("[KeyValidation] ⏳ Account pending for key: \(keyId)")
        // Save this key, use it if no active key found
        if pendingProvider == nil {
          pendingProvider = provider
        }

      case .noAccountOldKey:
        log.warning("[KeyValidation] ❓ Old key with no account: \(keyId)")
        // Don't remove yet, might be manually recoverable
      }
    }

    // Move only explicitly revoked keys to isolated storage
    if !revokedKeyIds.isEmpty {
      log.info("[KeyValidation] Moving \(revokedKeyIds.count) revoked keys to isolated storage")
      await moveKeysToRevokedStorage(
        keyIds: revokedKeyIds,
        keyType: keyType,
        uid: uid
      )
    }

    // If no active key found but have pending key, use it (new account still pending on-chain)
    if let provider = pendingProvider {
      log.info("[KeyValidation] No active key on-chain yet, using pending key (new account)")
      // Return with a dummy account key for pending accounts
      // The wallet will be initialized and can be used once the account is on-chain
      let dummyAccountKey = Flow.AccountKey(
        index: 0,
        publicKey: Flow.PublicKey(data: provider.publicKey(signAlgo: .ECDSA_P256) ?? provider.publicKey(signAlgo: .ECDSA_SECP256k1)!),
        signAlgo: .ECDSA_P256,
        hashAlgo: .SHA2_256,
        weight: 1000,
        sequenceNumber: 0,
        revoked: false
      )
      return (dummyAccountKey, provider)
    }

    return nil
  }

  /// Validate a single key on mainnet
  private func validateKeyOnMainnet(
    provider: any KeyProtocol,
    keyId: String,
    address: String?
  ) async -> KeyValidationResult {
    do {
      var account: Flow.Account
      var accountAddress: String

      // If main account address is provided, use it directly (avoids key indexer delay)
      if let addr = address, !addr.isEmpty {
        log.debug("[KeyValidation] Using main account address: \(addr)")
        accountAddress = addr
        account = try await FlowNetwork.getAccountAtLatestBlock(address: addr)
      } else {
        // Fallback: use key indexer to find account
        log.debug("[KeyValidation] No main address available, using key indexer")
        let tempWallet = FlowWalletKit.Wallet(
          type: .key(provider),
          networks: supportNetworks
        )

        try await tempWallet.fetchAccount()

        // Get mainnet account
        guard let mainnetAccount = tempWallet.accounts?[.mainnet]?.first else {
          // Account not found - classify whether it's pending or old
          return classifyNoAccount(keyId: keyId)
        }

        account = mainnetAccount.account
        accountAddress = mainnetAccount.address.hexAddr
      }

      log.debug("[KeyValidation] Checking key for address: \(accountAddress)")

      // Check if key is active on-chain
      if let activeKey = KeyProvider.findMatchingActiveKey(for: provider, in: account) {
        return .active(activeKey)
      } else {
        // Key exists in account but is revoked
        return .revoked
      }

    } catch {
      log.error("[KeyValidation] Failed to validate key: \(error)")
      return classifyNoAccount(keyId: keyId)
    }
  }

  /// Classify a key when account is not found
  private func classifyNoAccount(keyId: String) -> KeyValidationResult {
    // Check key creation time
    if let keyCreationTime = getKeyCreationTime(keyId: keyId) {
      let timeSinceCreation = Date().timeIntervalSince(keyCreationTime)
      log.debug("[KeyValidation] Key \(keyId) was created \(Int(timeSinceCreation))s ago")

      // If created in last 5 minutes, consider it pending
      if timeSinceCreation < 5 * 60 {
        log.info("[KeyValidation] ⏳ Key created recently (\(Int(timeSinceCreation))s ago), account may be pending")
        return .pendingAccount
      }

      // Give 1 hour grace period for slow transactions
      if timeSinceCreation < 60 * 60 {
        log.warning("[KeyValidation] ⏳ Key created \(Int(timeSinceCreation/60))m ago, account still pending?")
        return .pendingAccount
      }

      // Too old - should have been on-chain by now
      log.warning("[KeyValidation] ❓ Key created \(Int(timeSinceCreation/60))m ago but no account found")
      return .noAccountOldKey
    } else {
      // No creation time found - could be old key from before we started tracking
      log.warning("[KeyValidation] ❓ No creation time found for key: \(keyId) - assuming old key")
      return .noAccountOldKey
    }
  }

  /// Get storage for key type
  public func getStorage(for keyType: FlowWalletKit.KeyType) -> FlowWalletKit.KeychainStorage {
    switch keyType {
    case .seedPhrase:
      return SeedPhraseKey.seedPhraseStorage
    case .privateKey, .keyStore:
      return FlowWalletKit.PrivateKey.PKStorage
    case .secureEnclave:
      return SecureEnclaveKey.KeychainStorage
    }
  }

  /// Load key provider from storage
  private func loadKeyProvider(
    keyId: String,
    keyType: FlowWalletKit.KeyType,
    password: String,
    storage: FlowWalletKit.KeychainStorage
  ) throws -> (any KeyProtocol)? {
    switch keyType {
    case .seedPhrase:
      return try? SeedPhraseKey.get(id: keyId, password: password, storage: storage)
    case .privateKey, .keyStore:
      return try? FlowWalletKit.PrivateKey.get(id: keyId, password: password, storage: storage)
    case .secureEnclave:
      return try? SecureEnclaveKey.get(id: keyId, password: password, storage: storage)
    }
  }

  /// Initialize wallet with the correct active key
  private func initializeWithKey(
    provider: any KeyProtocol,
    accountKey: Flow.AccountKey,
    uid: String,
    userStore: UserManager.StoreUser
  ) async {
    let publicKey = provider.publicKey(signAlgo: .ECDSA_P256)?.hexString ??
                    provider.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString ?? ""

    log.info("[KeyValidation] Initializing wallet with key: \(publicKey.prefix(8))")

    // Update userStore if needed
    if userStore.publicKey != publicKey {
      let updatedStore = UserManager.StoreUser(
        publicKey: publicKey,
        address: userStore.address,
        userId: uid,
        keyType: userStore.keyType,
        account: accountKey.toStoreKey()
      )
      LocalUserDefaults.shared.addUser(user: updatedStore)
    }

    await MainActor.run {
      keyProvider = provider
      updateKeyProvider(provider: provider)
      // Clear mainAccount before creating new walletEntity to keep state consistent
      // This prevents showing stale linked accounts (COA/childs) from old wallet
      mainAccount = nil
      walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
    }

    do {
      try await walletEntity?.fetchAccount()
      ProfileManager.shared.update(uid: uid, keyProvider: provider, with: walletEntity)
      log.info("[KeyValidation] ✅ Wallet initialized successfully")
    } catch {
      log.error("[KeyValidation] Failed to fetch account: \(error)")

      // For pending accounts (newly created, not yet indexed by key indexer),
      // try using the known address from userStore if available
      if let address = userStore.address, !address.isEmpty, !isEVMAddress(address) {
        log.info("[KeyValidation] Attempting direct account fetch with known address: \(address.prefix(8))")

        do {
          // Try to fetch account directly by address (bypasses key indexer delay)
          let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)
          log.info("[KeyValidation] ✅ Successfully fetched account by address")

          // Force a refresh to repopulate walletEntity with the account data
          await MainActor.run {
            reloadWalletInfo()
          }
        } catch {
          log.error("[KeyValidation] Direct address fetch failed: \(error)")

          // Start retry mechanism to poll until account appears
          await MainActor.run {
            log.info("[KeyValidation] Starting retry mechanism for pending account")
            reloadWalletInfo()
          }
        }
      } else {
        // No known address or it's an EVM/child address - start retry mechanism
        await MainActor.run {
          log.info("[KeyValidation] Starting retry mechanism for pending account")
          reloadWalletInfo()
        }
      }
    }
  }

  /// Notify that wallet key is invalid
  private func notifyWalletKeyInvalid(uid: String, reason: String) async {
    await MainActor.run {
      NotificationCenter.default.post(
        name: .walletKeyInvalid,
        object: nil,
        userInfo: ["uid": uid, "reason": reason]
      )
    }
  }

  /// Fallback to old behavior if new validation fails
  private func fallbackToOldBehavior(uid: String) async {
    log.warning("[KeyValidation] Falling back to old behavior")
    keyProvider = keyProvider(with: uid)
    if let provider = keyProvider {
      await MainActor.run {
        updateKeyProvider(provider: provider)
        walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
      }
      let _ = try? await walletEntity?.fetchAllNetworkAccounts()
    }
  }

  /// Check if address is an EVM address (COA - Cadence Owned Account)
  /// EVM addresses have many leading zeros: 0x00000000000000000000000203e18d5934842eca
  /// Flow addresses are shorter: 0x203e18d5934842eca
  private func isEVMAddress(_ address: String) -> Bool {
    var addr = address
    // Remove 0x prefix
    if addr.hasPrefix("0x") || addr.hasPrefix("0X") {
      addr = String(addr.dropFirst(2))
    }

    // EVM addresses (COA) are 40 characters (20 bytes) with many leading zeros
    // Flow addresses are typically 16 characters (8 bytes) or less
    return addr.count > 16
  }
}

// MARK: - Key Creation Time Tracking

extension WalletManager {

  /// Get key creation time from UserDefaults
  func getKeyCreationTime(keyId: String) -> Date? {
    let key = "keyCreationTime.\(keyId)"
    if let timestamp = UserDefaults.standard.object(forKey: key) as? TimeInterval {
      return Date(timeIntervalSince1970: timestamp)
    }
    return nil
  }

  /// Save key creation time to UserDefaults
  func saveKeyCreationTime(keyId: String) {
    let key = "keyCreationTime.\(keyId)"
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key)
    log.debug("[KeyValidation] Saved creation time for key: \(keyId)")
  }
}
