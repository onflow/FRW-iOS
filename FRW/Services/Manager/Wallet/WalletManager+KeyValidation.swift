//
//  WalletManager+KeyValidation.swift
//  FRW
//
//  Created by Claude on 2026/01/19.
//

import Flow
import FlowWalletKit
import Foundation

// MARK: - Key Validation

extension WalletManager {

  /// Find valid key provider for a user ID (validates on-chain)
  /// Used for account switching - finds the first key that has a valid mainnet account
  /// Returns tuple of (keyProvider, accountKey, address, wallet, accounts) or nil if no valid key found
  /// The wallet and accounts are already fetched to avoid duplicate network requests
  func findKeyProvider(uid: String) async -> (provider: any KeyProtocol, accountKey: Flow.AccountKey, address: String, wallet: FlowWalletKit.Wallet, accounts: [FlowWalletKit.Account])? {
    // Prioritize userStore keyType if available (reduces unnecessary network requests)
    let keyTypes: [FlowWalletKit.KeyType]
    if let userStore = userStore(with: uid) {
      // Try userStore keyType first, then fallback to others
      keyTypes = [userStore.keyType] + [.seedPhrase, .privateKey, .secureEnclave].filter { $0 != userStore.keyType }
      log.info("[KeyValidation] Prioritizing keyType from userStore: \(userStore.keyType)")
    } else {
      keyTypes = [.seedPhrase, .privateKey, .secureEnclave]
    }

    let pw = KeyProvider.password(with: uid)

    for keyType in keyTypes {
      let storage = getStorage(for: keyType)
      let allKeys = KeyProvider.keys(with: uid, in: storage)

      if allKeys.isEmpty {
        continue
      }

      log.info("[KeyValidation] Checking \(allKeys.count) keys in \(keyType) for uid: \(uid)")

      // Try each key in this storage type
      for keyId in allKeys {
        guard let provider = try? loadKeyProvider(
          keyId: keyId,
          keyType: keyType,
          password: pw,
          storage: storage
        ) else {
          continue
        }

        // Check if this key has a valid mainnet account
        let wallet = FlowWalletKit.Wallet(type: .key(provider), networks: [.mainnet])
        do {
          try await wallet.fetchAccount()

          // Check if we have accounts on mainnet with full weight key that is NOT revoked
          if let accounts = wallet.accounts?[.mainnet],
             let validAccount = accounts.first(where: { $0.hasFullWeightKey }),
             let fullWeightKey = validAccount.fullWeightKey {

            // IMPORTANT: Check if key is revoked
            if fullWeightKey.revoked {
              log.warning("[KeyValidation] ❌ Key is REVOKED: \(keyId), address: \(validAccount.address.hexAddr)")
              continue
            }

            log.info("[KeyValidation] ✅ Found valid active key for uid: \(uid) (keyId: \(keyId), address: \(validAccount.address.hexAddr), signAlgo: \(fullWeightKey.signAlgo), hashAlgo: \(fullWeightKey.hashAlgo), revoked: false)")

            // Update userStore with correct publicKey and account info
            let correctPublicKey = provider.publicKey(signAlgo: fullWeightKey.signAlgo)?.hexString ?? ""
            let updatedStore = UserManager.StoreUser(
              publicKey: correctPublicKey,
              address: validAccount.address.hexAddr,
              userId: uid,
              keyType: keyType,
              account: fullWeightKey.toStoreKey()
            )
            LocalUserDefaults.shared.addUser(user: updatedStore)
            log.info("[KeyValidation] Updated userStore with correct publicKey: \(correctPublicKey.prefix(8))")

            // Return all accounts (including child accounts) to avoid duplicate fetch
            return (provider, fullWeightKey, validAccount.address.hexAddr, wallet, accounts)
          } else {
            log.warning("[KeyValidation] ❌ Key has no valid mainnet account: \(keyId)")
          }
        } catch {
          log.warning("[KeyValidation] ❌ Failed to fetch account for key: \(keyId), error: \(error)")
          continue
        }
      }
    }

    log.error("[KeyValidation] No valid key found for uid: \(uid)")
    return nil
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
