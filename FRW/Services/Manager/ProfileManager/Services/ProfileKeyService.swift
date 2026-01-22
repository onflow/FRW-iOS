//
//  ProfileKeyService.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Flow
import FlowWalletKit
import Foundation

// MARK: - ProfileKeyService

/// Service responsible for key provider operations
final class ProfileKeyService: ProfileKeyServiceProtocol {
    // MARK: Lifecycle

    init() {}

    // MARK: Internal

    // MARK: - ProfileKeyServiceProtocol Implementation

    func findKeyProvider(uid: String) -> (any KeyProtocol)? {
        // Try SecureEnclaveKey first (most secure)
        if let provider = try? SecureEnclaveKey.wallet(id: uid) {
            return provider
        }

        // Try SeedPhraseKey
        if let provider = try? SeedPhraseKey.wallet(id: uid) {
            return provider
        }

        // Try PrivateKey
        if let provider = try? FlowWalletKit.PrivateKey.wallet(id: uid) {
            return provider
        }

        log.debug("[ProfileKey] No key provider found for uid: \(uid)")
        return nil
    }

    func keyExists(uid: String) -> Bool {
        findKeyProvider(uid: uid) != nil
    }

    func fetchValidUserIds() async -> [String: String] {
        var result: [String: String] = [:]

        // Validate SecureEnclave keys
        let seValidIds = await validateSecureEnclaveKeys()
        result.merge(seValidIds) { _, new in new }

        // Get SeedPhrase keys (no validation needed)
        let spIds = getSeedPhraseKeyIds()
        result.merge(spIds) { _, new in new }

        // Get PrivateKey keys (no validation needed)
        let pkIds = getPrivateKeyIds()
        result.merge(pkIds) { _, new in new }

        return result
    }

    func fetchAllAccounts(keyProvider: any KeyProtocol) async throws -> [FlowWalletKit.Account] {
        let supportNetworks: Set<Flow.ChainID> = [.mainnet, .testnet]
        let wallet = FlowWalletKit.Wallet(type: .key(keyProvider), networks: supportNetworks)
        try await wallet.fetchAccount()
        return wallet.accounts?[.mainnet] ?? []
    }

    // MARK: - Key Type Accessors

    /// Get all SecureEnclave key IDs
    var secureEnclaveKeyIds: [String] {
        SecureEnclaveKey.KeychainStorage.allKeys
    }

    /// Get all SeedPhrase key IDs
    var seedPhraseKeyIds: [String] {
        SeedPhraseKey.seedPhraseStorage.allKeys
    }

    /// Get all PrivateKey key IDs
    var privateKeyIds: [String] {
        FlowWalletKit.PrivateKey.PKStorage.allKeys
    }

    // MARK: Private

    // MARK: - Private Validation Methods

    private func validateSecureEnclaveKeys() async -> [String: String] {
        var validKeys: [String: String] = [:]
        let keyList = secureEnclaveKeyIds

        for key in keyList {
            guard let provider = try? SecureEnclaveKey.wallet(id: key) else {
                log.warning("[ProfileKey] SecureEnclaveKey get failed: \(key)")
                continue
            }

            // Verify the key can sign and validate
            guard let message = "test message".data(using: .utf8) else {
                log.error("[ProfileKey] Message encoding failed")
                continue
            }

            // Check if key has associated accounts
            guard let accounts = try? await fetchAllAccounts(keyProvider: provider),
                  !accounts.isEmpty
            else {
                continue
            }

            // Validate signature
            guard let signature = try? provider.sign(data: message, hashAlgo: .SHA2_256) else {
                log.warning("[ProfileKey] SecureEnclaveKey sign failed: \(key)")
                continue
            }

            let isValid = provider.isValidSignature(signature: signature, message: message)
            if isValid {
                let publicKey = provider.publicKey()?.hexValue
                let uid = KeyProvider.getId(with: key)
                validKeys[uid] = publicKey
            } else {
                log.warning("[ProfileKey] SecureEnclaveKey signature validation failed: \(key)")
            }
        }

        return validKeys
    }

    private func getSeedPhraseKeyIds() -> [String: String] {
        var result: [String: String] = [:]
        let keyList = seedPhraseKeyIds

        for key in keyList {
            guard let provider = try? SeedPhraseKey.wallet(id: key) else {
                log.warning("[ProfileKey] SeedPhraseKey get failed: \(key)")
                continue
            }

            let p256Key = provider.publicKey(signAlgo: .ECDSA_P256)?.hexValue ?? ""
            let secp256k1Key = provider.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue ?? ""
            let publicKey = "\(p256Key),\(secp256k1Key)"

            let uid = KeyProvider.getId(with: key)
            result[uid] = publicKey
        }

        return result
    }

    private func getPrivateKeyIds() -> [String: String] {
        var result: [String: String] = [:]
        let keyList = privateKeyIds

        for key in keyList {
            guard let provider = try? FlowWalletKit.PrivateKey.wallet(id: key) else {
                log.warning("[ProfileKey] PrivateKey get failed: \(key)")
                continue
            }

            let p256Key = provider.publicKey(signAlgo: .ECDSA_P256)?.hexValue ?? ""
            let secp256k1Key = provider.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue ?? ""
            let publicKey = "\(p256Key),\(secp256k1Key)"

            let uid = KeyProvider.getId(with: key)
            result[uid] = publicKey
        }

        return result
    }
}
