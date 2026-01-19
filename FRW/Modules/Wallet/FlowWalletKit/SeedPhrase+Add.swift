//
//  SeedPhrase+Add.swift
//  FRW
//
//  Created by cat on 2024/9/27.
//

import Flow
import FlowWalletKit
import Foundation

extension SeedPhraseKey {
    private static let suffix = ".SP"
    static func wallet(id: String, publicKey: String? = nil) throws -> SeedPhraseKey {
        let pw = KeyProvider.password(with: id)
        let keys = KeyProvider.keys(with: id, in: seedPhraseStorage)
        let fallbackKey = keys.last ?? id

        // If publicKey provided, try to find matching key
        if let targetPubKey = publicKey {
            if let matched = try? keys.first(where: { k in
                let spKey = try SeedPhraseKey.get(id: k, password: pw, storage: seedPhraseStorage)
                let p256 = spKey.publicKey(signAlgo: .ECDSA_P256)?.hexString
                let secp = spKey.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString
                return p256 == targetPubKey || secp == targetPubKey
            }) {
                log.debug("[SeedPhrase] Found matching key for publicKey: \(targetPubKey.prefix(8))")
                return try SeedPhraseKey.get(id: matched, password: pw, storage: seedPhraseStorage)
            }
            log.warning("[SeedPhrase] No match for publicKey: \(targetPubKey.prefix(8)), using fallback")
        }

        // Fallback to last key
        return try SeedPhraseKey.get(id: fallbackKey, password: pw, storage: seedPhraseStorage)
    }

    func store(id: String) throws {
        let pw = KeyProvider.password(with: id)
        let key = createKey(uid: id)
        try store(id: key, password: pw)
    }

    static var seedPhraseStorage: FlowWalletKit.KeychainStorage {
        let storage = FlowWalletKit.KeychainStorage(
            service: keychainService,
            label: keychainTag,
            synchronizable: false,
            deviceOnly: true
        )
        return storage
    }
}

// MARK: - For Backup

extension SeedPhraseKey {
    static func createBackup(uid _: String? = nil) throws -> SeedPhraseKey {
        let key = try SeedPhraseKey.create(storage: seedPhraseBackupStorage)
        return key
    }

    func storeBackup(id: String) throws {
        let pw = KeyProvider.password(with: id)
        let key = createKey(uid: id)
        try store(id: key, password: pw)
    }

    static var seedPhraseBackupStorage: FlowWalletKit.KeychainStorage {
        let storage = FlowWalletKit.KeychainStorage(
            service: keychainBackService,
            label: keychainBackTag,
            synchronizable: false
        )
        return storage
    }
}

extension SeedPhraseKey {
    static var keychainService: String {
        (Bundle.main.bundleIdentifier ?? AppBundleName) + suffix
    }

    static var keychainTag: String {
        "SeedPhraseKey"
    }

    static var keychainBackService: String {
        keychainService + ".backup"
    }

    static var keychainBackTag: String {
        keychainTag + " Backup"
    }
}
