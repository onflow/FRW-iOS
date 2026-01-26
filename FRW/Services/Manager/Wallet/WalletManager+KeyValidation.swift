//
//  WalletManager+KeyValidation.swift
//  FRW
//
//  Created by Claude on 2026/01/19.
//

import Flow
import FlowWalletKit
import Foundation

// MARK: - Key Validation State

/// Tracks the state during key provider validation process
private struct KeyValidationState {
  var hasAnyKeys = false
  var loadedAnyProvider = false
  var foundProviderWithoutAccount: (any KeyProtocol)? = nil
  var revokedKeyIds: [String] = []

  mutating func recordRevokedKey(_ keyId: String) {
    revokedKeyIds.append(keyId)
  }

  mutating func recordProviderWithoutAccount(_ provider: any KeyProtocol) {
    if foundProviderWithoutAccount == nil {
      foundProviderWithoutAccount = provider
    }
  }
}

// MARK: - Key Validation

extension WalletManager {

  /// Find valid key provider for a user ID (validates on-chain)
  /// Used for account switching - finds the first key that has a valid mainnet account
  /// Returns KeyProviderResult indicating success, provider without account, or no valid provider
  func findKeyProvider(uid: String) async -> KeyProviderResult {
    let keyTypes = determineKeyTypePriority(uid: uid)
    let password = KeyProvider.password(with: uid)

    var validationState = KeyValidationState()

    for keyType in keyTypes {
      let storage = getStorage(for: keyType)
      let allKeys = KeyProvider.keys(with: uid, in: storage)

      guard !allKeys.isEmpty else { continue }

      validationState.hasAnyKeys = true
      log.info("[KeyValidation] Checking \(allKeys.count) keys in \(keyType) for uid: \(uid)")

      for keyId in allKeys {
        guard let provider = try? loadKeyProvider(
          keyId: keyId,
          keyType: keyType,
          password: password,
          storage: storage
        ) else {
          continue
        }

        validationState.loadedAnyProvider = true

        if let result = await validateKeyProvider(
          provider: provider,
          keyId: keyId,
          keyType: keyType,
          uid: uid,
          state: &validationState
        ) {
          return result
        }
      }
    }

    return buildFinalResult(state: validationState, uid: uid)
  }

  // MARK: - Private Helper Methods

  /// Determine key type checking priority based on userStore
  private func determineKeyTypePriority(uid: String) -> [FlowWalletKit.KeyType] {
    if let userStore = userStore(with: uid) {
      let prioritized = [userStore.keyType] + [.seedPhrase, .privateKey, .secureEnclave]
        .filter { $0 != userStore.keyType }
      log.info("[KeyValidation] Prioritizing keyType from userStore: \(userStore.keyType)")
      return prioritized
    }
    return [.seedPhrase, .privateKey, .secureEnclave]
  }

  /// Validate a single key provider against on-chain data
  /// Returns KeyProviderResult if validation is conclusive, nil to continue searching
  private func validateKeyProvider(
    provider: any KeyProtocol,
    keyId: String,
    keyType: FlowWalletKit.KeyType,
    uid: String,
    state: inout KeyValidationState
  ) async -> KeyProviderResult? {
    let wallet = FlowWalletKit.Wallet(type: .key(provider), networks: [.mainnet])

    do {
      try await wallet.fetchAccount()

      guard let accounts = wallet.accounts?[.mainnet],
            let validAccount = accounts.first(where: { $0.hasFullWeightKey }),
            let fullWeightKey = validAccount.fullWeightKey else {
        // Provider exists but no on-chain account yet
        log.info("[KeyValidation] ⏳ Provider exists but no mainnet account yet: \(keyId)")
        state.recordProviderWithoutAccount(provider)
        return nil
      }

      // Check if key is revoked
      if fullWeightKey.revoked {
        log.warning("[KeyValidation] ❌ Key is REVOKED: \(keyId), address: \(validAccount.address.hexAddr)")
        state.recordRevokedKey(keyId)
        return nil
      }

      // Found valid active key!
      log.info("[KeyValidation] ✅ Found valid active key for uid: \(uid) (keyId: \(keyId), address: \(validAccount.address.hexAddr))")

      updateUserStore(
        provider: provider,
        keyType: keyType,
        accountKey: fullWeightKey,
        address: validAccount.address.hexAddr,
        uid: uid
      )

      return .success(KeyProviderData(
        provider: provider,
        accountKey: fullWeightKey,
        address: validAccount.address.hexAddr,
        wallet: wallet,
        accounts: accounts
      ))
    } catch {
      // Network error or account not indexed yet
      log.warning("[KeyValidation] ⏳ Failed to fetch account for key: \(keyId), error: \(error)")
      state.recordProviderWithoutAccount(provider)
      return nil
    }
  }

  /// Update userStore with validated on-chain account info
  private func updateUserStore(
    provider: any KeyProtocol,
    keyType: FlowWalletKit.KeyType,
    accountKey: Flow.AccountKey,
    address: String,
    uid: String
  ) {
    let publicKey = provider.publicKey(signAlgo: accountKey.signAlgo)?.hexString ?? ""
    let updatedStore = UserManager.StoreUser(
      publicKey: publicKey,
      address: address,
      userId: uid,
      keyType: keyType,
      account: accountKey.toStoreKey()
    )
    LocalUserDefaults.shared.addUser(user: updatedStore)
    log.info("[KeyValidation] Updated userStore with publicKey: \(publicKey.prefix(8))")
  }

  /// Build final result based on validation state
  private func buildFinalResult(state: KeyValidationState, uid: String) -> KeyProviderResult {
    // Priority 1: Provider without account (async creation in progress)
    if let provider = state.foundProviderWithoutAccount {
      log.info("[KeyValidation] Returning provider without account (async creation in progress)")
      return .providerWithoutAccount(provider)
    }

    // Priority 2: Revoked keys
    if !state.revokedKeyIds.isEmpty {
      log.error("[KeyValidation] Found only revoked keys for uid: \(uid), keyIds: \(state.revokedKeyIds)")
      return .noValidProvider(.allKeysRevoked(revokedKeyIds: state.revokedKeyIds))
    }

    // Priority 3: Keys exist but couldn't load
    if state.hasAnyKeys && !state.loadedAnyProvider {
      log.error("[KeyValidation] Keys exist but failed to load for uid: \(uid)")
      return .noValidProvider(.keysCorrupted)
    }

    // Priority 4: No keys at all
    log.error("[KeyValidation] No keys found for uid: \(uid)")
    return .noValidProvider(.noKeys)
  }

  // MARK: - Helper Functions

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

  // MARK: - KeyIndexer Polling

  /// Wait for keyIndexer to index a new key with polling
  /// Returns true if key was indexed successfully, false if timeout
  /// Default timeout: 45 attempts * 2 seconds = 90 seconds
  func waitForKeyIndexer(provider: any KeyProtocol, maxAttempts: Int = 45) async -> Bool {
    log.info("[KeyIndexer] Waiting for keyIndexer to index new key (max \(maxAttempts * 2) seconds)...")
    let tempWallet = FlowWalletKit.Wallet(type: .key(provider), networks: [.mainnet])
    var attempt = 0

    while attempt < maxAttempts {
      do {
        try await tempWallet.fetchAccount()
        if let accounts = tempWallet.accounts?[.mainnet],
           let flowAccount = accounts.first,
           flowAccount.hasFullWeightKey {
          // Successfully fetched from keyIndexer
          await MainActor.run {
            self.mainAccount = flowAccount
            log.info("[KeyIndexer] ✅ New key indexed after \(attempt + 1) attempts - mainAccount updated with keyIndex: \(flowAccount.keyIndex)")
          }
          return true
        } else {
          // KeyIndexer returned but no valid account yet
          attempt += 1
          if attempt < maxAttempts {
            log.debug("[KeyIndexer] Not ready (attempt \(attempt)/\(maxAttempts)), retrying in 2s...")
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
          }
        }
      } catch {
        // KeyIndexer error, retry
        attempt += 1
        if attempt < maxAttempts {
          log.debug("[KeyIndexer] Error (attempt \(attempt)/\(maxAttempts)): \(error), retrying in 2s...")
          try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
      }
    }

    log.warning("[KeyIndexer] ⚠️ Timeout after \(maxAttempts) attempts - key is on-chain but not indexed yet")
    return false
  }
}

// MARK: - Key Creation Time Tracking (Debug Only)

#if DEBUG
extension WalletManager {

  /// Get key creation time from UserDefaults (debug only)
  func getKeyCreationTime(keyId: String) -> Date? {
    let key = "keyCreationTime.\(keyId)"
    if let timestamp = UserDefaults.standard.object(forKey: key) as? TimeInterval {
      return Date(timeIntervalSince1970: timestamp)
    }
    return nil
  }

  /// Save key creation time to UserDefaults (debug only)
  func saveKeyCreationTime(keyId: String) {
    let key = "keyCreationTime.\(keyId)"
    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key)
    log.debug("[KeyValidation] Saved creation time for key: \(keyId)")
  }
}
#endif
