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

extension SeedPhraseKey: WalletKeyProvidable {
    static var keychainStorage: FlowWalletKit.KeychainStorage {
        seedPhraseStorage
    }

    static var matchableSignAlgorithms: [Flow.SignatureAlgorithm] {
        [
            .ECDSA_SECP256k1,
            .ECDSA_P256,
        ]
    }

    static func loadStoredKey(
        id: String,
        password: String,
        storage: FlowWalletKit.KeychainStorage
    ) throws -> Self {
        guard let key = try SeedPhraseKey.get(
            id: id,
            password: password,
            storage: storage
        ) as? Self else {
            throw WalletError.emptyKeyProvider
        }
        return key
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
