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

    static func wallet(id: String, publicKey: String? = nil) throws -> SecureEnclaveKey {
        let pw = KeyProvider.password(with: id)
        let keys = KeyProvider.keys(with: id, in: SecureEnclaveKey.KeychainStorage)
        let fallbackKey = keys.last ?? id

        // If a target publicKey is provided, try to find the matching stored key first.
        if let targetPubKey = publicKey {
            if let matched = try keys.first(where: { k in
                let seKey = try SecureEnclaveKey.get(
                    id: k,
                    password: pw,
                    storage: SecureEnclaveKey.KeychainStorage
                )
                let pubK = seKey.publicKey(signAlgo: .ECDSA_P256)?.hexString
                return pubK == targetPubKey
            }) {
                return try SecureEnclaveKey.get(
                    id: matched,
                    password: pw,
                    storage: SecureEnclaveKey.KeychainStorage
                )
            }
        }

        // Fallback to the last stored key (or the provided id when none stored).
        return try SecureEnclaveKey.get(
            id: fallbackKey,
            password: pw,
            storage: SecureEnclaveKey.KeychainStorage
        )
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
