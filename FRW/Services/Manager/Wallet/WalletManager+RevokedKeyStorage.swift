//
//  WalletManager+RevokedKeyStorage.swift
//  FRW
//
//  Created by Claude on 2026/01/19.
//

import Flow
import FlowWalletKit
import Foundation

// MARK: - Revoked Key Storage Management

extension WalletManager {

  /// Get isolated storage for revoked keys
  private func getRevokedKeyStorage(for keyType: FlowWalletKit.KeyType) -> FlowWalletKit.KeychainStorage {
    let suffix: String
    switch keyType {
    case .seedPhrase:
      suffix = ".SP.revoked"
    case .privateKey, .keyStore:
      suffix = ".PK.revoked"
    case .secureEnclave:
      suffix = ".SE.revoked"
    }

    return FlowWalletKit.KeychainStorage(
      service: (Bundle.main.bundleIdentifier ?? AppBundleName) + suffix,
      label: "RevokedKeys",
      synchronizable: false,
      deviceOnly: true
    )
  }

  // MARK: - Core Functions

  /// Move keys to revoked storage for isolation (NEVER delete, only isolate)
  func moveKeysToRevokedStorage(
    keyIds: [String],
    keyType: FlowWalletKit.KeyType,
    uid: String
  ) async {
    let activeStorage = getStorage(for: keyType)
    let revokedStorage = getRevokedKeyStorage(for: keyType)

    for keyId in keyIds {
      do {
        // Read key from active storage
        if let keyData = try? activeStorage.get(keyId) {
          // Save to revoked storage
          try revokedStorage.set(keyId, value: keyData)

          // Remove from active storage
          try activeStorage.remove(keyId)

          log.info("[RevokedKey] Moved key to revoked storage: \(keyId)")
        }
      } catch {
        log.error("[RevokedKey] Failed to move key \(keyId): \(error)")
      }
    }
  }

  /// Restore a revoked key back to active storage (for recovery)
  func restoreRevokedKey(
    keyId: String,
    keyType: FlowWalletKit.KeyType
  ) async throws {
    let activeStorage = getStorage(for: keyType)
    let revokedStorage = getRevokedKeyStorage(for: keyType)

    // Check if key exists in revoked storage
    guard let keyData = try? revokedStorage.get(keyId) else {
      throw WalletError.emptyAccountKey
    }

    // Move back to active storage
    try activeStorage.set(keyId, value: keyData)
    try revokedStorage.remove(keyId)

    log.info("[RevokedKey] Restored key from revoked storage: \(keyId)")
  }

  /// List all revoked keys for a key type
  func listRevokedKeys(for keyType: FlowWalletKit.KeyType) -> [String] {
    let revokedStorage = getRevokedKeyStorage(for: keyType)
    return revokedStorage.allKeys
  }

  // MARK: - Debug Functions

  #if DEBUG
  /// Get total count of revoked keys (debug only)
  func getRevokedKeysCount() -> Int {
    let seedPhraseCount = listRevokedKeys(for: .seedPhrase).count
    let privateKeyCount = listRevokedKeys(for: .privateKey).count
    let secureEnclaveCount = listRevokedKeys(for: .secureEnclave).count
    return seedPhraseCount + privateKeyCount + secureEnclaveCount
  }

  /// Export revoked keys info for debugging
  func exportRevokedKeysInfo() -> [String: Any] {
    var info: [String: Any] = [:]

    for keyType: FlowWalletKit.KeyType in [.seedPhrase, .privateKey, .secureEnclave] {
      let keys = listRevokedKeys(for: keyType)
      let keyTypeString: String
      switch keyType {
      case .seedPhrase:
        keyTypeString = "seedPhrase"
      case .privateKey:
        keyTypeString = "privateKey"
      case .keyStore:
        keyTypeString = "keyStore"
      case .secureEnclave:
        keyTypeString = "secureEnclave"
      }

      info[keyTypeString] = keys.map { keyId in
        return [
          "keyId": keyId,
          "creationTime": getKeyCreationTime(keyId: keyId)?.description ?? "unknown"
        ]
      }
    }

    return info
  }

  /// Clear all revoked keys (PERMANENT DELETION - debug only)
  func clearAllRevokedKeys() async {
    log.warning("[RevokedKey] Clearing all revoked keys - PERMANENT DELETION")

    for keyType: FlowWalletKit.KeyType in [.seedPhrase, .privateKey, .secureEnclave] {
      let revokedStorage = getRevokedKeyStorage(for: keyType)
      let allKeys = revokedStorage.allKeys

      for keyId in allKeys {
        do {
          try revokedStorage.remove(keyId)
          log.info("[RevokedKey] Deleted revoked key: \(keyId)")
        } catch {
          log.error("[RevokedKey] Failed to delete key \(keyId): \(error)")
        }
      }
    }
  }
  #endif
}
