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
    static func wallet(id: String) throws -> FlowWalletKit.PrivateKey {
        let pw = KeyProvider.password(with: id)
        let key = KeyProvider.lastKey(with: id, in: PKStorage) ?? id
        let privateKey = try FlowWalletKit.PrivateKey.get(
            id: key,
            password: pw,
            storage: PrivateKey.PKStorage
        )
        return privateKey
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
