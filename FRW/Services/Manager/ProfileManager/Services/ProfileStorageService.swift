//
//  ProfileStorageService.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Foundation
import KeychainAccess

// MARK: - ProfileStorageService

/// Service responsible for profile persistence using Keychain
final class ProfileStorageService: ProfileStorageProtocol {
    // MARK: Lifecycle

    init(keychain: Keychain? = nil) {
        self.keychain = keychain ?? Keychain(service: Constants.serviceName)
            .accessibility(.whenUnlockedThisDeviceOnly)
            .synchronizable(false)
    }

    // MARK: Internal

    // MARK: - Constants

    enum Constants {
        static let serviceName = "com.flowfoundation.frw.profiles"
        static let profileKeyPrefix = "profiles_"
        static let metadataKey = "profiles_metadata"
        static let indexKey = "profiles_index"
    }

    // MARK: - ProfileStorageProtocol Implementation

    func save(_ profile: ProfileModel) throws {
        let key = Constants.profileKeyPrefix + profile.uid

        do {
            let data = try encoder.encode(profile)
            try keychain.set(data, key: key)
            try updateIndex(with: profile.uid)
            log.debug("[ProfileStorage] Saved profile: \(profile.uid)")
        } catch {
            log.error("[ProfileStorage] Save failed for \(profile.uid): \(error)")
            throw ProfileError.keychainError(.unexpectedError)
        }
    }

    func load(userId: String) throws -> ProfileModel? {
        let key = Constants.profileKeyPrefix + userId

        do {
            guard let data = try keychain.getData(key) else {
                return nil
            }
            return try decoder.decode(ProfileModel.self, from: data)
        } catch {
            log.error("[ProfileStorage] Load failed for \(userId): \(error)")
            throw ProfileError.decodingError
        }
    }

    func delete(userId: String) throws {
        let key = Constants.profileKeyPrefix + userId

        do {
            try keychain.remove(key)
            try removeFromIndex(userId: userId)
            log.debug("[ProfileStorage] Deleted profile: \(userId)")
        } catch {
            log.error("[ProfileStorage] Delete failed for \(userId): \(error)")
            throw ProfileError.keychainError(.unexpectedError)
        }
    }

    func loadAll() throws -> [ProfileModel] {
        let profileIds = try getAllIds()
        log.debug("[ProfileStorage] Loading \(profileIds.count) profiles")

        var profiles: [ProfileModel] = []
        for userId in profileIds {
            if let profile = try load(userId: userId) {
                profiles.append(profile)
            }
        }
        return profiles
    }

    func getAllIds() throws -> [String] {
        do {
            guard let data = try keychain.getData(Constants.indexKey) else {
                return []
            }
            return try decoder.decode([String].self, from: data)
        } catch {
            log.error("[ProfileStorage] Get all IDs failed: \(error)")
            return []
        }
    }

    func clearAll() throws {
        let profileIds = try getAllIds()

        for userId in profileIds {
            try delete(userId: userId)
        }

        try keychain.remove(Constants.indexKey)
        try keychain.remove(Constants.metadataKey)
        log.info("[ProfileStorage] Cleared all profiles")
    }

    // MARK: - Batch Operations

    /// Save multiple profiles efficiently
    func saveAll(_ profiles: [ProfileModel]) throws {
        for profile in profiles {
            try save(profile)
        }
    }

    /// Check if a profile exists
    func exists(userId: String) -> Bool {
        let key = Constants.profileKeyPrefix + userId
        return (try? keychain.getData(key)) != nil
    }

    // MARK: Private

    private let keychain: Keychain

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    // MARK: - Index Management

    private func updateIndex(with userId: String) throws {
        var profileIds = try getAllIds()

        if !profileIds.contains(userId) {
            profileIds.append(userId)
            let data = try encoder.encode(profileIds)
            try keychain.set(data, key: Constants.indexKey)
        }
    }

    private func removeFromIndex(userId: String) throws {
        var profileIds = try getAllIds()
        profileIds.removeAll { $0 == userId }

        let data = try encoder.encode(profileIds)
        try keychain.set(data, key: Constants.indexKey)
    }
}
