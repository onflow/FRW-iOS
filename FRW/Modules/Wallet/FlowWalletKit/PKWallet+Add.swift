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

extension FlowWalletKit.PrivateKey: WalletKeyProvidable {
    static var keychainStorage: FlowWalletKit.KeychainStorage {
        PKStorage
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
        guard let key = try FlowWalletKit.PrivateKey.get(
            id: id,
            password: password,
            storage: storage
        ) as? Self else {
            throw WalletError.emptyKeyProvider
        }
        return key
    }
}
