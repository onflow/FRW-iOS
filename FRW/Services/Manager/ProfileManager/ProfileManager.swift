//
//  ProfileManager.swift
//  FRW
//
//  Created by cat on 9/24/25.
//

import Foundation
import FlowWalletKit
import WalletCore

// MARK: - ProfileManager

class ProfileManager: ObservableObject {
    private let keychainService = ProfileKeychainService()
    private var profileCache: [String: ProfileModel] = [:]

    @Published var profiles: [ProfileModel] = []
    
  static let shared = ProfileManager()
  
    private init() {
#if DEBUG
      clearAllProfiles()
#endif
        loadCachedProfiles()
        migrateExistingProfilesIfNeeded()
    }

    // MARK: - Profile Management

    func saveProfile(_ profile: ProfileModel) {
        do {
            try keychainService.saveProfile(profile)
            profileCache[profile.userIdAndPublickKeyPrefix] = profile
            refreshProfiles()
            log.info("[Profile] Profile saved successfully for user: \(profile.userIdAndPublickKeyPrefix)")
        } catch {
            log.error("[Profile] Failed to save profile for user \(profile.userIdAndPublickKeyPrefix): \(error)")
        }
    }

    func loadProfile(userId: String) -> ProfileModel? {
        // Check cache first
        if let cachedProfile = profileCache[userId] {
            return cachedProfile
        }

        // Load from keychain
        do {
            if let profile = try keychainService.loadProfile(userId: userId) {
                profileCache[userId] = profile
                return profile
            }
        } catch {
            log.error("[Profile] Failed to load profile for user \(userId): \(error)")
        }

        return nil
    }

    func deleteProfile(userId: String) {
        do {
            try keychainService.deleteProfile(userId: userId)
            profileCache.removeValue(forKey: userId)
            refreshProfiles()
            log.info("[Profile] Profile deleted successfully for user: \(userId)")
        } catch {
            log.error("[Profile] Failed to delete profile for user \(userId): \(error)")
        }
    }

    func updateProfile(userId: String, username: String? = nil, avatar: String? = nil) {
        guard let existingProfile = loadProfile(userId: userId) else {
            log.warning("[Profile] Cannot update non-existent profile for user: \(userId)")
            return
        }

        let updatedProfile = existingProfile.updated(username: username, avatar: avatar)
        saveProfile(updatedProfile)
    }
  
  func updateProfile(userId: String, publicKey: String, with user: [UserManager.StoreUser]) {
    let key = KeyProvider.createKey(userId: userId, publicKey: publicKey)
    guard let existingProfile = loadProfile(userId: key) else {
        log.warning("[Profile] Cannot update non-existent profile for user: \(userId)")
        return
    }
    let result = existingProfile.updated(fromWallets: user)
    saveProfile(result)
  }
  
  func addUser(profile: ProfileModel, with users: [UserManager.StoreUser]) {
    let result = profile.updated(fromWallets: users)
    saveProfile(result)
  }

    // MARK: - Cache Management

    private func loadCachedProfiles() {
        do {
            let allProfiles = try keychainService.getAllProfiles()
            for profile in allProfiles {
                profileCache[profile.userIdAndPublickKeyPrefix] = profile
            }
            self.profiles = allProfiles
        } catch {
            log.error("[Profile] Failed to load cached profiles: \(error)")
        }
    }

    private func refreshProfiles() {
        do {
            let allProfiles = try keychainService.getAllProfiles()
            DispatchQueue.main.async {
                self.profiles = allProfiles
            }
        } catch {
            log.error("[Profile] Failed to refresh profiles: \(error)")
        }
    }

    // MARK: - Migration

    private func migrateExistingProfilesIfNeeded() {
        // Check if migration has already been completed
        let migrationKey = "profile_migration_completed_v1"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }

        log.info("[Profile] Starting profile migration...")

        let userStoreList = LocalUserDefaults.shared.userList
        let validUserIdAndPublicKey = ProfileManager.fetchValidUserId()
        for userIdAndPublickKeyPrefix in validUserIdAndPublicKey {
            // Check if profile already exists in keychain
            if loadProfile(userId: userIdAndPublickKeyPrefix) != nil {
                continue
            }

            // Create new profile for validated user
            let uid = KeyProvider.getId(with: userIdAndPublickKeyPrefix)
            let userInfo = MultiAccountStorage.shared.getUserInfo(uid)
            
            var filterList = userStoreList.filter { store in
              let result = KeyProvider.createKey(userId: store.userId, publicKey: store.publicKey)
              return result == userIdAndPublickKeyPrefix
            }
            filterList.sort { $0.address ?? "" > $1.address ?? "" }
            let profile = ProfileModel(
              userIdAndPublickKeyPrefix: userIdAndPublickKeyPrefix,
              username: userInfo?.username ?? userInfo?.username ?? "",
              avatar: userInfo?.avatar ?? "",
              wallets: filterList
            )
            
            saveProfile(profile)
            log.info("[Profile] Migrated profile for user: \(userIdAndPublickKeyPrefix):")
        }

        // Mark migration as completed
#if !DEBUG
        UserDefaults.standard.set(true, forKey: migrationKey)
#endif
        log.info("[Profile] Profile migration completed successfully")
    }

    // MARK: - Utility

    func clearAllProfiles() {
        do {
            try keychainService.clearAllProfiles()
            profileCache.removeAll()
            DispatchQueue.main.async {
                self.profiles = []
            }

            // Reset migration flag
            UserDefaults.standard.removeObject(forKey: "profile_migration_completed_v1")

            log.info("[Profile] All profiles cleared successfully")
        } catch {
            log.error("[Profile] Failed to clear all profiles: \(error)")
        }
    }

    func getProfileCount() -> Int {
        return profiles.count
    }

    func hasProfile(userId: String) -> Bool {
        return loadProfile(userId: userId) != nil
    }
}

extension ProfileManager {
  func showProfileList() -> [ProfileModel] {
    var profileList: [String: ProfileModel] = [:]
    for profile in profiles {
      let key = profile.uid + (profile.wallets.first?.address ?? "")
      if let existingProfile = profileList[key], existingProfile.wallets.count > profile.wallets.count {
        profileList[key] = existingProfile
      } else {
        profileList[key] = profile
      }
    }
    return profileList.map { $0.value }
  }
}

// MARK: Valid Profile List
extension ProfileManager {
  static func fetchValidUserId() -> [String] {
    var userIdAndPublicKeyPre: [String] = []
    // Secure Enclave Key
    let seKeylist = SecureEnclaveKey.KeychainStorage.allKeys
    guard let message = "test message".data(using: .utf8) else {
      log.error("[Profile] encode message failed. This shouldn't happen")
      return []
    }

    for key in seKeylist {
      guard let se = try? SecureEnclaveKey.wallet(id: key) else {
        log.warning("[Profile] SecureEnclaveKey get failed.\(key) ")
        continue
      }
      guard let signature = try? se.sign(data: message, hashAlgo: .SHA2_256) else {
        log.warning("[Profile] SecureEnclaveKey sign message failed.\(key) ")
        continue
      }
      let result = se.isValidSignature(signature: signature, message: message)
      if result {
        userIdAndPublicKeyPre.append(key)
      } else {
        log.warning("[Profile] SecureEnclaveKey valid signature failed.\(key) ")
      }
    }
    // SeedPhraseKey
    let spKeyList = SeedPhraseKey.seedPhraseStorage.allKeys
    for key in spKeyList {
      guard let provider = try? SeedPhraseKey.wallet(id: key) else {
        log.warning("[Profile] SeedPhraseKey get failed.\(key) ")
        continue
      }
      userIdAndPublicKeyPre.append(key)
    }
    // PrivateKey
    let pkKeyList = FlowWalletKit.PrivateKey.PKStorage.allKeys
    for key in pkKeyList {
      guard let provider = try? FlowWalletKit.PrivateKey.wallet(id: key) else {
        log.warning("[Profile] PrivateKey get failed.\(key) ")
        continue
      }
      userIdAndPublicKeyPre.append(key)
    }
    return userIdAndPublicKeyPre
  }
}
