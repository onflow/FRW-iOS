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
/// Conforming types only need to describe how to access their specific storage and how
/// to reconstruct a key instance from a stored identifier.
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
    /// Restores a key of the current type.
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

        let targets = normalizedTargets(from: publicKey)
        if !targets.isEmpty {
            // Stored metadata may contain multiple public keys per uid; try to find the match first
            // so we return the precise key that produced the stored account.
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
    func matchesPublicKeys(targets: [String], algorithms: [Flow.SignatureAlgorithm]) -> Bool {
        guard !targets.isEmpty else {
            return false
        }
        for algorithm in algorithms {
            guard let publicKey = publicKey(signAlgo: algorithm) else {
                continue
            }

            // Different SDK APIs expose the hex string via different properties; try each form
            // because existing stored metadata could have been produced by any of them.
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
        // Support multiple comma-separated public keys saved during migration. Each entry may have
        // different casing or optional `0x` prefixes, so we normalize them before comparison.
        return raw
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.normalizedPublicKeyValue() }
    }
}
