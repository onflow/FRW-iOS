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

