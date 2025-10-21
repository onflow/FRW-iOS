//
//  SecureEnclaveKey+Add.swift
//  FRW
//
//  Created by cat on 2024/9/10.
//

import Flow
import FlowWalletKit
import Foundation

extension SecureEnclaveKey {
    private static let suffix = ".SE"
    static func create() throws -> SecureEnclaveKey {
        let SecureEnclaveKey = try SecureEnclaveKey
            .create(storage: SecureEnclaveKey.KeychainStorage)
        return SecureEnclaveKey
    }

    func flowAccountKey(
        index: Int = -1,
        signAlgo: Flow.SignatureAlgorithm = .ECDSA_P256,
        weight: Int = 1000
    ) throws -> Flow.AccountKey {
        guard let publicData = publicKey() else {
            throw WalletError.emptyPublicKey
        }
        let key = Flow.AccountKey(
            index: index,
            publicKey: .init(data: publicData),
            signAlgo: signAlgo,
            hashAlgo: .SHA2_256,
            weight: weight
        )
        return key
    }
}

// MARK: - Private

extension SecureEnclaveKey {
    static var KeychainStorage: FlowWalletKit.KeychainStorage {
        let service = (Bundle.main.bundleIdentifier ?? AppBundleName) + SecureEnclaveKey.suffix
        let storage = FlowWalletKit.KeychainStorage(
            service: service,
            label: "SecureEnclaveKey",
            synchronizable: false,
            deviceOnly: true
        )
        return storage
    }
}

extension SecureEnclaveKey: WalletKeyProvidable {
    static var keychainStorage: FlowWalletKit.KeychainStorage {
        KeychainStorage
    }

    static var matchableSignAlgorithms: [Flow.SignatureAlgorithm] {
        [
            .ECDSA_P256,
        ]
    }

    static func loadStoredKey(
        id: String,
        password: String,
        storage: FlowWalletKit.KeychainStorage
    ) throws -> SecureEnclaveKey {
        try SecureEnclaveKey.get(
            id: id,
            password: password,
            storage: storage
        )
    }
}

// MARK: - String

extension String {
    func addUserMessage() -> Data? {
        guard let textData = data(using: .utf8) else {
            return nil
        }
        return Flow.DomainTag.user.normalize + textData
    }
}

public extension Data {
    func signUserMessage() -> Data {
        Flow.DomainTag.user.normalize + self
    }
}
