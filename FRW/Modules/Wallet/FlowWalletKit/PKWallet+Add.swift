//
//  PKWallet+Add.swift
//  FRW
//
//  Created by cat on 2024/9/10.
//

import Flow
import FlowWalletKit
import Foundation

extension FlowWalletKit.PrivateKey {
    private static let suffix = ".PK"
    static func wallet(id: String, publicKey: String? = nil) throws -> FlowWalletKit.PrivateKey {
        let pw = KeyProvider.password(with: id)
        let keys = KeyProvider.keys(with: id, in: PKStorage)
        let fallbackKey = keys.last ?? id

        // If publicKey provided, try to find matching key
        if let targetPubKey = publicKey {
            if let matched = try? keys.first(where: { k in
                let pkKey = try FlowWalletKit.PrivateKey.get(id: k, password: pw, storage: PKStorage)
                let p256 = pkKey.publicKey(signAlgo: .ECDSA_P256)?.hexString
                let secp = pkKey.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString
                return p256 == targetPubKey || secp == targetPubKey
            }) {
                log.debug("[PrivateKey] Found matching key for publicKey: \(targetPubKey.prefix(8))")
                return try FlowWalletKit.PrivateKey.get(id: matched, password: pw, storage: PKStorage)
            }
            log.warning("[PrivateKey] No match for publicKey: \(targetPubKey.prefix(8)), using fallback")
        }

        // Fallback to last key
        return try FlowWalletKit.PrivateKey.get(id: fallbackKey, password: pw, storage: PKStorage)
    }

    func store(id: String) throws {
        let pw = KeyProvider.password(with: id)
        let key = createKey(uid: id)
        try store(id: key, password: pw)
    }
}

extension FlowWalletKit.PrivateKey {
    static var PKStorage: FlowWalletKit.KeychainStorage {
        let storage = FlowWalletKit.KeychainStorage(
            service: keychainService,
            label: keychainTag,
            synchronizable: false,
            deviceOnly: true
        )
        return storage
    }
}

extension FlowWalletKit.PrivateKey {
    static var keychainService: String {
        (Bundle.main.bundleIdentifier ?? AppBundleName) + suffix
    }

    static var keychainTag: String {
        "PKWallet"
    }
}
