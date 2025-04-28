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

    static func wallet(id: String) throws -> SecureEnclaveKey {
        let pw = KeyProvider.password(with: id)
        let key = KeyProvider.lastKey(with: id, in: SecureEnclaveKey.KeychainStorage) ?? id
        let secureEnclaveKey = try SecureEnclaveKey.get(
            id: key,
            password: pw,
            storage: SecureEnclaveKey.KeychainStorage
        )
        return secureEnclaveKey
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

    func store(id: String) throws {
        let pw = KeyProvider.password(with: id)
        let key = createKey(uid: id)
        try store(id: key, password: pw)
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
