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
    static func wallet(id: String) throws -> SeedPhraseKey {
        let pw = KeyProvider.password(with: id)
        let key = KeyProvider.lastKey(with: id, in: seedPhraseStorage) ?? id
        let seedPhraseKey = try SeedPhraseKey.get(
            id: key,
            password: pw,
            storage: SeedPhraseKey.seedPhraseStorage
        )
        return seedPhraseKey
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
