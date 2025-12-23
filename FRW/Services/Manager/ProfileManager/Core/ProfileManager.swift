//
//  ProfileManager.swift
//  FRW
//
//  Created by cat on 9/24/25.
//  Refactored on 11/29/25.
//

import Combine
import Flow
import FlowWalletKit
import Foundation

// MARK: - ProfileManager

/// Coordinator class that orchestrates profile management operations
/// Uses dependency injection for all services to enable testability
final class ProfileManager: ObservableObject {
  // MARK: Lifecycle

  private init() {
    // Initialize services
    let storageService = ProfileStorageService()
    let keyService = ProfileKeyService()

    self.storage = storageService
    self.keyService = keyService
    self.fetchService = ProfileFetchService(keyService: keyService)
    self.migrationService = ProfileMigrationService(
      storage: storageService,
      keyService: keyService
    )
    self.state = ProfileState(storage: storageService)
    self.cacheManager = ProfileCacheManager()
    self.refreshDebouncer = ProfileRefreshDebouncer()

    // Forward state publishers
    setupStateBindings()
    // Initial load
    initialize()
  }

  // MARK: - Dependency Injection Constructor (for testing)

  init(
    storage: ProfileStorageProtocol,
    keyService: ProfileKeyServiceProtocol,
    fetchService: ProfileFetchServiceProtocol,
    migrationService: ProfileMigrationServiceProtocol
  ) {
    self.storage = storage
    self.keyService = keyService
    self.fetchService = fetchService
    self.migrationService = migrationService
    self.state = ProfileState(storage: storage)
    self.cacheManager = ProfileCacheManager()
    self.refreshDebouncer = ProfileRefreshDebouncer()

    setupStateBindings()
    initialize()
  }

  // MARK: Internal

  // MARK: - Singleton

  static let shared = ProfileManager()

  // MARK: - Services

  let storage: ProfileStorageProtocol
  let keyService: ProfileKeyServiceProtocol
  let fetchService: ProfileFetchServiceProtocol
  let migrationService: ProfileMigrationServiceProtocol

  // MARK: - Published State (forwarded from ProfileState)

  @Published
  private(set) var isReady = false

  @Published
  var profiles: [ProfileModel] = []

  @Published
  var currentProfile: ProfileModel?

  // MARK: - Setup

  func setup() {
    UserManager.shared.$activatedUID
      .receive(on: DispatchQueue.main)
      .sink { [weak self] uid in
        self?.state.updateCurrentProfile(uid: uid)
        self?.syncStateToPublished()
      }
      .store(in: &cancellableSet)
  }

  // MARK: - Profile CRUD Operations

  func saveProfile(_ profile: ProfileModel) {
    saveProfile(profile, validateKey: true)
  }

  /// Save profile with optional key validation
  /// - Parameters:
  ///   - profile: The profile to save
  ///   - validateKey: If true, requires key to exist before saving (default: true)
  func saveProfile(_ profile: ProfileModel, validateKey: Bool) {
    if validateKey {
      guard keyService.keyExists(uid: profile.uid) else {
        log.warning("[Profile] Save failed - key not found for \(profile.uid)")
        return
      }
    }

    do {
      try storage.save(profile)
      state.updateProfile(profile)
      syncStateToPublished()
      log.info("[Profile] Saved profile: \(profile.uid)")
    } catch {
      log.error("[Profile] Save failed for \(profile.uid): \(error)")
    }
  }

  func saveProfiles(_ profiles: [ProfileModel], onlySave: Bool = false) {
    var didSaveAny = false

    for profile in profiles {
      guard keyService.keyExists(uid: profile.uid) else {
        log.warning("[Profile] Save skipped - key not found for \(profile.uid)")
        continue
      }

      do {
        try storage.save(profile)
        didSaveAny = true
      } catch {
        log.error("[Profile] Save failed for \(profile.uid): \(error)")
      }
    }

    if didSaveAny, !onlySave {
      refreshFromStorage()
    }
  }

  func loadProfile(userId: String) -> ProfileModel? {
    do {
      return try storage.load(userId: userId)
    } catch {
      log.error("[Profile] Load failed for \(userId): \(error)")
      return nil
    }
  }

  func deleteProfile(userId: String) {
    do {
      try storage.delete(userId: userId)
      state.removeProfile(userId: userId)
      syncStateToPublished()
      log.info("[Profile] Deleted profile: \(userId)")
    } catch {
      log.error("[Profile] Delete failed for \(userId): \(error)")
    }
  }

  func replace(profile: ProfileModel, with users: [UserManager.StoreUser]) {
    let updated = profile.updated(fromWallets: users)
    saveProfile(updated)
  }

  // MARK: - Account Operations

  func fetchAllAccountsInfo() {
    Task {
      await fetchAllAccountsInfoAsync()
    }
  }

  func refreshCurrentProfileAccounts() async {
    guard let current = currentProfile else {
      log.warning("[Profile] No current profile to refresh")
      return
    }
    await refreshProfileAccount(profile: current)
  }

  func refreshProfileAccount(profile: ProfileModel) async {
    do {
      let updated = try await fetchService.fetchAllAccountInfo(for: [profile])

      await MainActor.run {
        if let refreshed = updated.first {
          saveProfile(refreshed, validateKey: false)
          log.info("[Profile] Refreshed current profile accounts")
        }
      }
    } catch {
      log.error("[Profile] Refresh current profile failed: \(error)")
    }
  }

  // MARK: - Utility Methods

  func clearAllProfiles() {
    do {
      try storage.clearAll()
      state.setProfiles([])
      syncStateToPublished()
      migrationService.resetMigrationStatus()
      log.info("[Profile] Cleared all profiles")
    } catch {
      log.error("[Profile] Clear all failed: \(error)")
    }
  }

  func getProfileCount() -> Int {
    profiles.count
  }

  func hasProfile(userId: String) -> Bool {
    loadProfile(userId: userId) != nil
  }

  // MARK: - Key Provider Service (Delegated)

  func findKeyProvider(uid: String) -> (any KeyProtocol)? {
    keyService.findKeyProvider(uid: uid)
  }

  func keyExist(uid: String) -> Bool {
    keyService.keyExists(uid: uid)
  }

  // MARK: - Display Helpers

  func showProfileList() -> [ProfileModel] {
    var profileMap: [String: ProfileModel] = [:]

    // Filter by unique key (uid + first address)
    for profile in profiles {
      let key = profile.uid + (profile.wallets.first?.address ?? "")
      if let existing = profileMap[key],
         existing.wallets.count > profile.wallets.count {
        continue
      }
      profileMap[key] = profile
    }

    // Ensure all profiles have usernames
    var result: [ProfileModel] = []
    for (index, profile) in profileMap.values.enumerated() {
      var finalProfile = profile
      if profile.username == nil {
        finalProfile = profile.updated(username: "Profile \(index + 1)")
      }
      result.append(finalProfile)
    }

    // Sort by username
    result.sort { ($0.username ?? "") < ($1.username ?? "") }
    return result
  }

  func updateCurrentProfile() {
    let uid = UserManager.shared.activatedUID
    state.updateCurrentProfile(uid: uid)
    syncStateToPublished()
  }

  // MARK: Private

  private let state: ProfileState
  private let cacheManager: ProfileCacheManager
  private let refreshDebouncer: ProfileRefreshDebouncer
  private var cancellableSet = Set<AnyCancellable>()

  // MARK: - Initialization

  private func initialize() {
    // Synchronously load cached profiles
    loadCachedProfiles()

    // Async operations
    Task {
      await performMigrationIfNeeded()
      await MainActor.run {
        refreshFromStorage()
        state.markReady()
        syncStateToPublished()
      }
      fetchAllAccountsInfo()
    }
  }

  private func setupStateBindings() {
    // Observe state changes and forward to published properties
    state.$profiles
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newProfiles in
        self?.profiles = newProfiles
      }
      .store(in: &cancellableSet)

    state.$currentProfile
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newProfile in
        log.debug("currentProfile \(newProfile?.uid ?? "")")
        self?.currentProfile = newProfile
      }
      .store(in: &cancellableSet)

    state.$isReady
      .receive(on: DispatchQueue.main)
      .sink { [weak self] ready in
        self?.isReady = ready
      }
      .store(in: &cancellableSet)
  }

  private func syncStateToPublished() {
    profiles = state.profiles
    currentProfile = state.currentProfile
    isReady = state.isReady
  }

  // MARK: - Private Loading Methods

  private func loadCachedProfiles() {
    do {
      let cached = try storage.loadAll()
      state.setProfiles(cached)

      // Validate that each profile has a valid key
      for profile in cached {
        if !keyService.keyExists(uid: profile.uid) {
          deleteProfile(userId: profile.uid)
        }
      }

      syncStateToPublished()
      log.debug("[Profile] Loaded \(cached.count) cached profiles")
    } catch {
      log.error("[Profile] Load cached profiles failed: \(error)")
    }
  }

  private func refreshFromStorage() {
    state.refreshFromStorage()
    state.updateCurrentProfile(uid: UserManager.shared.activatedUID)
    syncStateToPublished()
  }

  // MARK: - Private Fetch Methods

  private func fetchAllAccountsInfoAsync() async {
    // Capture current profiles to preserve any that fail to fetch
    let currentProfiles = profiles

    do {
      let updated = try await fetchService.fetchAllAccountInfo(for: currentProfiles)

      await MainActor.run {
        // Merge fetched profiles with existing ones (preserve profiles that failed to fetch)
        let updatedIds = Set(updated.map { $0.uid })
        let preserved = currentProfiles.filter { !updatedIds.contains($0.uid) }
        let merged = updated + preserved

        state.setProfiles(merged)
        state.updateCurrentProfile(uid: UserManager.shared.activatedUID)
        saveProfiles(updated, onlySave: true)
        syncStateToPublished()
        cacheManager.markAllFetched(profileIds: updated.map { $0.uid })

        log
          .debug(
            "[Profile] Fetched \(updated.count) profiles, preserved \(preserved.count)"
          )
      }
    } catch {
      log.error("[Profile] Fetch all accounts info failed: \(error)")
    }
  }

  // MARK: - Private Migration Methods

  private func performMigrationIfNeeded() async {
    do {
      try await migrationService.migrate()
    } catch {
      log.error("[Profile] Migration failed: \(error)")
    }
  }
}

// MARK: - Valid Profile List

extension ProfileManager {
  func fetchValidUserId() async -> [String: String] {
    await keyService.fetchValidUserIds()
  }
}
