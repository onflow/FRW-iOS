//
//  KeyProtocol+Add.swift
//  FRW
//
//  Created by cat on 2024/9/27.
//

import Foundation
import FlowWalletKit

private let sTag = ".key."

enum KeyProvider {
    static func password(with _: String) -> String {
        let aseKey = LocalEnvManager.shared.backupAESKey
        return aseKey
    }
  
    static func keys(with uid: String, in store: FlowWalletKit.KeychainStorage ) -> [String] {
        return store.allKeys.filter { $0.contains(uid) }
    }
  
    static func lastKey(with uid: String, in store: FlowWalletKit.KeychainStorage ) -> String? {
        return store.allKeys.last { $0.contains(uid) }
    }

    static func getId(with key: String) -> String {
        guard key.contains(sTag) else {
            return key
        }
        guard let result = key.components(separatedBy: sTag).first else {
            return key
        }
        return result
    }

    static func getSuffix(with key: String) -> String {
        guard key.contains(sTag) else {
            return key
        }
        guard let suffix = key.components(separatedBy: sTag).last else {
            return key
        }
        return suffix
    }
  
    static func createKey(userId: String, publicKey: String) -> String {
      guard !userId.contains(sTag) else {
          return userId
      }
      let suffix = publicKey.prefix(8)
      return userId + sTag + suffix
    }
}

extension KeyProtocol {
    func createKey(uid: String) -> String {
        guard !uid.contains(sTag) else {
            return uid
        }
        let suffix = self.id.prefix(8)
        return uid + sTag + suffix
    }
}

// MARK: - Key Validation Utilities

import Flow

extension KeyProvider {
    /// Check if a key is active on-chain
    static func isKeyActive(publicKey: String, in account: Flow.Account) -> Bool {
        return account.keys.contains { key in
            !key.revoked &&
            key.weight >= 1000 &&
            key.publicKey.hex == publicKey
        }
    }

    /// Get all active keys from account
    static func getActiveKeys(from account: Flow.Account) -> [Flow.AccountKey] {
        return account.keys.filter { !$0.revoked && $0.weight >= 1000 }
    }

    /// Find matching active key for a key provider
    static func findMatchingActiveKey(for keyProvider: any KeyProtocol, in account: Flow.Account) -> Flow.AccountKey? {
        let activeKeys = getActiveKeys(from: account)

        if let p256 = keyProvider.publicKey(signAlgo: .ECDSA_P256)?.hexString {
            if let matched = activeKeys.first(where: { $0.publicKey.hex == p256 }) {
                return matched
            }
        }

        if let secp = keyProvider.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString {
            if let matched = activeKeys.first(where: { $0.publicKey.hex == secp }) {
                return matched
            }
        }

        return nil
    }
}

