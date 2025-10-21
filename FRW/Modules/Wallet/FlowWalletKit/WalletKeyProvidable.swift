//
//  WalletKeyProvidable.swift
//  FRW
//
//  Created by Hao Fu on 22/10/2025.
//

import Flow
import FlowWalletKit
import Foundation

protocol WalletKeyProvidable: KeyProtocol {
    static var keychainStorage: FlowWalletKit.KeychainStorage { get }
    static var matchableSignAlgorithms: [Flow.SignatureAlgorithm] { get }
    static func loadStoredKey(
        id: String,
        password: String,
        storage: FlowWalletKit.KeychainStorage
    ) throws -> Self
}

extension WalletKeyProvidable {
    static func wallet(id: String, publicKey: String? = nil) throws -> Self {
        let password = KeyProvider.password(with: id)
        let storedKeys = KeyProvider.keys(with: id, in: keychainStorage)
        let searchKeys = storedKeys.isEmpty ? [id] : storedKeys
        let fallbackKey = storedKeys.last ?? id

        let targets = normalizedTargets(from: publicKey)
        if !targets.isEmpty {
            for keyId in searchKeys {
                let candidate = try loadStoredKey(
                    id: keyId,
                    password: password,
                    storage: keychainStorage
                )
                if candidate.matchesPublicKeys(targets: targets, algorithms: matchableSignAlgorithms) {
                    return candidate
                }
            }
        }

        return try loadStoredKey(
            id: fallbackKey,
            password: password,
            storage: keychainStorage
        )
    }

    func store(id: String) throws {
        let password = KeyProvider.password(with: id)
        let storageId = createKey(uid: id)
        try store(id: storageId, password: password)
    }
}

private extension KeyProtocol {
    func matchesPublicKeys(targets: [String], algorithms: [Flow.SignatureAlgorithm]) -> Bool {
        guard !targets.isEmpty else {
            return false
        }
        for algorithm in algorithms {
            guard let publicKey = publicKey(signAlgo: algorithm) else {
                continue
            }

            let candidateValues = [
                publicKey.hexString,
                publicKey.hexValue,
                publicKey.description,
            ]

            for value in candidateValues.compactMap({ $0 }) {
                if targets.contains(value.normalizedPublicKeyValue()) {
                    return true
                }
            }
        }
        return false
    }
}

private extension String {
    func normalizedPublicKeyValue() -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return trimmed
        }
        let lowercased = trimmed.lowercased()
        if lowercased.hasPrefix("0x") {
            return String(lowercased.dropFirst(2))
        }
        return lowercased
    }
}

private extension WalletKeyProvidable {
    static func normalizedTargets(from publicKey: String?) -> [String] {
        guard let raw = publicKey, !raw.isEmpty else {
            return []
        }
        return raw
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.normalizedPublicKeyValue() }
    }
}
