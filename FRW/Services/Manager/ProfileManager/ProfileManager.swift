//
//  ProfileManager.swift
//  FRW
//
//  Created by cat on 9/24/25.
//

import Foundation
import FlowWalletKit
import WalletCore
import Flow

// MARK: - ProfileManager

class ProfileManager: ObservableObject {
  // MARK: Lifecycle
  let migrationKey = "profiles_migration_completed_v302"
  
  private init() {
    #if DEBUG
//    clearAllProfiles()
    #endif
    loadCachedProfiles()
    Task {
      await migrateExistingProfilesIfNeeded()
    }
  }

  // MARK: Internal

  static let shared = ProfileManager()

  @Published
  var profiles: [ProfileModel] = []

  var currentProfile: ProfileModel? {
    guard let uid = UserManager.shared.activatedUID else {
      return nil
    }
    return profiles.first { $0.uid == uid }
  }
  // MARK: - Profile Management

  func saveProfile(_ profile: ProfileModel) {
    guard keyExist(uid: profile.uid) else {
      log.warning("[Profile] Profile saved failed for user(\(profile.uid)), key don't found. ")
      return
    }
    do {
      try keychainService.saveProfile(profile)
      profileCache[profile.uid] = profile
      refreshProfiles()
      log.info("[Profile] Profile saved successfully for user: \(profile.uid)")
    } catch {
      log.error("[Profile] Failed to save profile for user \(profile.uid): \(error)")
    }
  }

  func saveProfiles(_ profiles: [ProfileModel]) {
    var didSaveAnyProfile = false
    for profile in profiles {
      guard keyExist(uid: profile.uid) else {
        log.warning("[Profile] Profile save skipped for user(\(profile.uid)), key not found.")
        continue
      }
      do {
        try keychainService.saveProfile(profile)
        profileCache[profile.uid] = profile
        didSaveAnyProfile = true
        log.info("[Profile] Profile saved successfully for user: \(profile.uid)")
      } catch {
        log.error("[Profile] Failed to save profile for user \(profile.uid): \(error)")
      }
    }
    if didSaveAnyProfile {
      refreshProfiles()
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

  func replace(profile: ProfileModel, with users: [UserManager.StoreUser]) {
    let result = profile.updated(fromWallets: users)
    saveProfile(result)
  }

  // MARK: - Utility

  func clearAllProfiles() {
    do {
      try keychainService.clearAllProfiles()
      profileCache.removeAll()
      DispatchQueue.main.async {
        self.profiles = []
      }
      UserDefaults.standard.removeObject(forKey: migrationKey)

      log.info("[Profile] All profiles cleared successfully")
    } catch {
      log.error("[Profile] Failed to clear all profiles: \(error)")
    }
  }

  func getProfileCount() -> Int {
    profiles.count
  }

  func hasProfile(userId: String) -> Bool {
    loadProfile(userId: userId) != nil
  }

  // MARK: Private

  private let keychainService = ProfileKeychainService()
  private var profileCache: [String: ProfileModel] = [:]

  // MARK: - Cache Management

  private func loadCachedProfiles() {
    do {
      let allProfiles = try keychainService.getAllProfiles()
      for profile in allProfiles {
        profileCache[profile.uid] = profile
      }
      profiles = allProfiles
      // Check whether the uid of the profile contains a key on keyChain
      for profile in allProfiles {
        if !keyExist(uid: profile.uid) {
          deleteProfile(userId: profile.uid)
        }
      }
      log.debug("[Profile] load profile: \n \(profiles)")
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

  private func migrateExistingProfilesIfNeeded() async {
    // Check if migration has already been completed
    
    if UserDefaults.standard.bool(forKey: migrationKey) {
      return
    }

    log.info("[Profile] Starting profile migration...")

    let userStoreList = LocalUserDefaults.shared.userList
    let validUserIdAndPublicKey = await fetchValidUserId()
    for (uid, _) in validUserIdAndPublicKey {
      if loadProfile(userId: uid) != nil {
        continue
      }
      let userInfo = MultiAccountStorage.shared.getUserInfo(uid)
      log.info("[Profile]-userInfo: \(uid) ## \(userInfo)")
      var filterList = userStoreList.filter { $0.userId == uid }
      filterList.sort { $0.address ?? "" > $1.address ?? "" }
      guard !filterList.isEmpty else {
        continue
      }
      let profile = ProfileModel(
        uid: uid,
        username: userInfo?.nickname ?? userInfo?.username,
        avatar: userInfo?.avatar,
        wallets: filterList
      )
      saveProfile(profile)
      log.info("[Profile] Migrated profile for user: \(uid):")
    }

    // Mark migration as completed
    UserDefaults.standard.set(true, forKey: migrationKey)
    log.info("[Profile] Profile migration completed successfully")
  }
}

extension ProfileManager {
  func showProfileList() -> [ProfileModel] {
    var profileList: [String: ProfileModel] = [:]
    // filter key and find the largest number
    for profile in profiles {
      let key = profile.uid + (profile.wallets.first?.address ?? "")
      if let existingProfile = profileList[key],
         existingProfile.wallets.count > profile.wallets.count {
        profileList[key] = existingProfile
      } else {
        profileList[key] = profile
      }
    }
    // get the list of Profile
    let showList = profileList.map { $0.value }
    // name if username is nil, Preventive
    var result: [ProfileModel] = []
    for (index, model) in showList.enumerated() {
      var tmp = model
      if model.username == nil {
        tmp = model.updated(username: "Profile \(index + 1)")
      }
      result.append(tmp)
    }
    // sort by username for user
    result.sort { ($0.username ?? "") < ($1.username ?? "") }
    return result
  }
}

// MARK: Keys
extension ProfileManager {
  func keyExist(uid: String) -> Bool {
    
    let seKeylist = SecureEnclaveKey.KeychainStorage.allKeys
    for key in seKeylist {
      guard key.contains(uid) else {
        continue
      }
      guard let provider = try? SecureEnclaveKey.wallet(id: uid) else {
        continue
      }
      return true
    }
    // SeedPhraseKey
    let spKeyList = SeedPhraseKey.seedPhraseStorage.allKeys
    for key in spKeyList {
      guard key.contains(uid) else {
        continue
      }
      guard let provider = try? SeedPhraseKey.wallet(id: uid) else {
        continue
      }
      return true
    }
    // PrivateKey
    let pkKeyList = FlowWalletKit.PrivateKey.PKStorage.allKeys
    for key in pkKeyList {
      guard key.contains(uid) else {
        continue
      }
      guard let provider = try? FlowWalletKit.PrivateKey.wallet(id: uid) else {
        continue
      }
      return true
    }
    log.info("[Profile] \(uid) don't found key")
    return false
  }
}

// MARK: Valid Profile List
extension ProfileManager {
  func fetchValidUserId() async -> [String: String] {
    var userIdAndPublicKeyPre: [String: String] = [:]
    // Secure Enclave Key
    let seKeylist = SecureEnclaveKey.KeychainStorage.allKeys

    for key in seKeylist {
      guard let provider = try? SecureEnclaveKey.wallet(id: key) else {
        log.warning("[Profile] SecureEnclaveKey get failed.\(key) ")
        continue
      }
      guard let message = "test message".data(using: .utf8) else {
        log.error("[Profile] encode message failed. This shouldn't happen")
        continue
      }
      guard let allAccount = try? await fetchAllAccount(keyProvider: provider),
            !allAccount.isEmpty
      else {
        continue
      }
      guard let signature = try? provider.sign(data: message, hashAlgo: .SHA2_256) else {
        log.warning("[Profile] SecureEnclaveKey sign message failed.\(key) ")
        continue
      }
      let result = provider.isValidSignature(signature: signature, message: message)
      if result {
        let publicKey = provider.publicKey()?.hexValue
        let uid = KeyProvider.getId(with: key)
        userIdAndPublicKeyPre[uid] = publicKey
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
      let publicKey = (provider.publicKey(signAlgo: .ECDSA_P256)?.hexValue ?? "") + "," +
        (provider.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue ?? "")
      let uid = KeyProvider.getId(with: key)
      userIdAndPublicKeyPre[uid] = publicKey
    }
    // PrivateKey
    let pkKeyList = FlowWalletKit.PrivateKey.PKStorage.allKeys
    for key in pkKeyList {
      guard let provider = try? FlowWalletKit.PrivateKey.wallet(id: key) else {
        log.warning("[Profile] PrivateKey get failed.\(key) ")
        continue
      }
      let publicKey = (provider.publicKey(signAlgo: .ECDSA_P256)?.hexValue ?? "") + "," +
        (provider.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue ?? "")
      let uid = KeyProvider.getId(with: key)
      userIdAndPublicKeyPre[uid] = publicKey
    }
    return userIdAndPublicKeyPre
  }

  private func fetchAllAccount(keyProvider: any KeyProtocol) async throws
    -> [FlowWalletKit.Account] {
    let supportNetworks: Set<Flow.ChainID> = [
      .mainnet,
      .testnet,
    ]
    let entity = FlowWalletKit.Wallet(type: .key(keyProvider), networks: supportNetworks)
    try await entity.fetchAccount()
    return entity.accounts?[.mainnet] ?? []
  }
}
