//
//  ProfileMigrationService.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Foundation

// MARK: - ProfileMigrationService

/// Service responsible for migrating profile data from legacy storage
final class ProfileMigrationService: ProfileMigrationServiceProtocol {
    // MARK: Lifecycle

    init(
        storage: ProfileStorageProtocol,
        keyService: ProfileKeyServiceProtocol,
        migrationKey: String = Constants.defaultMigrationKey
    ) {
        self.storage = storage
        self.keyService = keyService
        self.migrationKey = migrationKey
    }

    // MARK: Internal

    // MARK: - Constants

    enum Constants {
        static let defaultMigrationKey = "profiles_migration_completed_v302"
    }

    let migrationKey: String

    // MARK: - ProfileMigrationServiceProtocol Implementation

    func needsMigration() -> Bool {
        !UserDefaults.standard.bool(forKey: migrationKey)
    }

    func migrate() async throws {
        guard needsMigration() else {
            log.debug("[ProfileMigration] Migration already completed")
            return
        }

        log.info("[ProfileMigration] Starting profile migration...")

        let validUserIds = await keyService.fetchValidUserIds()
        var migratedCount = 0

        for (uid, _) in validUserIds {
            do {
                let migrated = try migrateUser(uid: uid)
                if migrated {
                    migratedCount += 1
                }
            } catch {
                log.error("[ProfileMigration] Failed to migrate user \(uid): \(error)")
                // Continue with other users
            }
        }

        markMigrationCompleted()
        log.info("[ProfileMigration] Migration completed. Migrated \(migratedCount) profiles")
    }

    func markMigrationCompleted() {
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    func resetMigrationStatus() {
        UserDefaults.standard.removeObject(forKey: migrationKey)
    }

    // MARK: Private

    private let storage: ProfileStorageProtocol
    private let keyService: ProfileKeyServiceProtocol

    // MARK: - Private Migration Methods

    private func migrateUser(uid: String) throws -> Bool {
        // Skip if profile already exists
        if let _ = try storage.load(userId: uid) {
            log.debug("[ProfileMigration] Profile already exists for \(uid)")
            return false
        }

        // Get user info from legacy storage
        let userInfo = MultiAccountStorage.shared.getUserInfo(uid)
        log.info("[ProfileMigration] Migrating user: \(uid), info: \(String(describing: userInfo))")

        // Get wallets from legacy storage
        let userStoreList = LocalUserDefaults.shared.userList
        var filteredList = userStoreList.filter { $0.userId == uid }
        filteredList.sort { ($0.address ?? "") > ($1.address ?? "") }

        guard !filteredList.isEmpty else {
            log.warning("[ProfileMigration] No wallet data for \(uid)")
            return false
        }

        // Create new profile
        let profile = ProfileModel(
            uid: uid,
            username: userInfo?.nickname ?? userInfo?.username,
            avatar: userInfo?.avatar,
            wallets: filteredList
        )

        try storage.save(profile)
        log.info("[ProfileMigration] Successfully migrated profile for \(uid)")
        return true
    }
}

// MARK: - Migration Versioning Support

extension ProfileMigrationService {
    /// Check if a specific migration version has been completed
    static func hasMigrationCompleted(version: String) -> Bool {
        UserDefaults.standard.bool(forKey: version)
    }

    /// Get the current migration version
    static var currentMigrationVersion: String {
        Constants.defaultMigrationKey
    }
}
