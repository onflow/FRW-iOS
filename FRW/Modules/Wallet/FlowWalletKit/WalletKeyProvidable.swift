//
//  WalletKeyProvidable.swift
//  FRW
//
//  Created by Hao Fu on 22/10/2025.
//

import Flow
import FlowWalletKit
import Foundation

/// Shared behaviour for key types that can be retrieved from keychain storage by uid.
/// Conforming types need to provide their dedicated storage, supported signature algorithms,
/// and an implementation that fetches a concrete key instance from storage.
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
    /// Restores a key for the given uid, optionally matching a stored public key.
    /// - Parameters:
    ///   - id: The activated user id (without suffix) we use to build storage keys.
    ///   - publicKey: Optional public key string(s) saved with the account metadata.
    /// - Returns: A key instance matching the requested uid (and public key when provided).
    ///
    /// We attempt to locate the exact key that matches the provided public key (if any)
    /// and otherwise fall back to the latest stored key for the uid. This mirrors the legacy
    /// behaviour while allowing precise selection during multi-key migrations.
    static func wallet(id: String, publicKey: String? = nil) throws -> Self {
        let password = KeyProvider.password(with: id)
        let storedKeys = KeyProvider.keys(with: id, in: keychainStorage)
        let searchKeys = storedKeys.isEmpty ? [id] : storedKeys
        let fallbackKey = storedKeys.last ?? id

        let targetPublicKey = publicKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let targetPublicKey, !targetPublicKey.isEmpty {
            // Try to locate the exact key whose public key matches what we stored alongside the profile.
            for keyId in searchKeys {
                let candidate = try loadStoredKey(
                    id: keyId,
                    password: password,
                    storage: keychainStorage
                )
                if candidate.matchesPublicKey(targetPublicKey, algorithms: matchableSignAlgorithms) {
                    return candidate
                }
            }
        }

        // No public-key match was found (or none were provided); use the newest stored key id.
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
    func matchesPublicKey(_ target: String, algorithms: [Flow.SignatureAlgorithm]) -> Bool {
        let normalizedTarget = target.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      
        guard !normalizedTarget.isEmpty else {
            return false
        }
      
        for algorithm in algorithms {
            guard let publicKey = publicKey(signAlgo: algorithm) else {
                continue
            }

            return publicKey.hexValue.lowercased() == normalizedTarget
        }
      
        return false
    }
}
