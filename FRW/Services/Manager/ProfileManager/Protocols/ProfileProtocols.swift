//
//  ProfileProtocols.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Foundation
import FlowWalletKit
import Flow

// MARK: - ProfileStorageProtocol

/// Protocol for profile persistence operations
protocol ProfileStorageProtocol {
    /// Save a profile to persistent storage
    func save(_ profile: ProfileModel) throws

    /// Load a profile by user ID
    func load(userId: String) throws -> ProfileModel?

    /// Delete a profile by user ID
    func delete(userId: String) throws

    /// Load all profiles from storage
    func loadAll() throws -> [ProfileModel]

    /// Get all profile IDs without loading full profiles
    func getAllIds() throws -> [String]

    /// Clear all profiles from storage
    func clearAll() throws
}

// MARK: - ProfileFetchServiceProtocol

/// Protocol for fetching profile data from network/blockchain
protocol ProfileFetchServiceProtocol {
    /// Fetch account data for profiles
    func fetchAccounts(for profiles: [ProfileModel]) async throws -> [ProfileModel]

    /// Fetch Flow balances for profiles
    func fetchBalances(for profiles: [ProfileModel]) async throws -> [ProfileModel]

    /// Fetch NFT counts for COA accounts
    func fetchNFTCounts(for profiles: [ProfileModel]) async throws -> [ProfileModel]

    /// Fetch all account info (accounts + balances + NFTs) in sequence
    func fetchAllAccountInfo(for profiles: [ProfileModel]) async throws -> [ProfileModel]
}

// MARK: - ProfileKeyServiceProtocol

/// Protocol for key provider operations
protocol ProfileKeyServiceProtocol {
    /// Find the key provider for a given user ID
    func findKeyProvider(uid: String) -> (any KeyProtocol)?

    /// Check if a key exists for the given user ID
    func keyExists(uid: String) -> Bool

    /// Fetch all valid user IDs with their public keys
    func fetchValidUserIds() async -> [String: String]

    /// Fetch all accounts for a key provider
    func fetchAllAccounts(keyProvider: any KeyProtocol) async throws -> [FlowWalletKit.Account]
}

// MARK: - ProfileMigrationServiceProtocol

/// Protocol for profile migration operations
protocol ProfileMigrationServiceProtocol {
    /// The key used to track migration completion
    var migrationKey: String { get }

    /// Check if migration is needed
    func needsMigration() -> Bool

    /// Perform migration
    func migrate() async throws

    /// Mark migration as completed
    func markMigrationCompleted()

    /// Reset migration status (for testing)
    func resetMigrationStatus()
}

// MARK: - ProfileStateProtocol

/// Protocol for profile state management
protocol ProfileStateProtocol: ObservableObject {
    /// All loaded profiles
    var profiles: [ProfileModel] { get set }

    /// Currently active profile
    var currentProfile: ProfileModel? { get set }

    /// Indicates if the manager is ready
    var isReady: Bool { get }

    /// Update current profile based on active user ID
    func updateCurrentProfile()

    /// Refresh profiles from storage
    func refreshFromStorage()
}

// MARK: - ProfileManagerProtocol

/// Main protocol for ProfileManager coordination
protocol ProfileManagerProtocol: ProfileStateProtocol {
    /// Storage service for persistence
    var storage: ProfileStorageProtocol { get }

    /// Fetch service for network operations
    var fetchService: ProfileFetchServiceProtocol { get }

    /// Key service for key management
    var keyService: ProfileKeyServiceProtocol { get }

    /// Migration service for data migration
    var migrationService: ProfileMigrationServiceProtocol { get }

    /// Initialize and setup the manager
    func setup()

    /// Save a profile
    func saveProfile(_ profile: ProfileModel)

    /// Load a profile by user ID
    func loadProfile(userId: String) -> ProfileModel?

    /// Delete a profile by user ID
    func deleteProfile(userId: String)

    /// Refresh all account information
    func refreshAllAccountsInfo()

    /// Refresh current profile's account information
    func refreshCurrentProfileAccounts() async
}

// MARK: - ProfileCacheProtocol

/// Protocol for profile caching strategies
protocol ProfileCacheProtocol {
    /// Check if data for a profile should be fetched
    func shouldFetch(profileId: String) -> Bool

    /// Mark a profile as recently fetched
    func markFetched(profileId: String)

    /// Invalidate cache for a profile
    func invalidate(profileId: String)

    /// Clear all cache
    func clearAll()
}
