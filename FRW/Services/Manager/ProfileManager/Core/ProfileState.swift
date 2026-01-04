//
//  ProfileState.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Combine
import Foundation

// MARK: - ProfileState

/// Observable state container for profile data
final class ProfileState: ObservableObject {
    // MARK: Lifecycle

    init(storage: ProfileStorageProtocol) {
        self.storage = storage
    }

    // MARK: Internal

    /// All loaded profiles
    @Published
    private(set) var profiles: [ProfileModel] = []

    /// Currently active profile
    @Published
    private(set) var currentProfile: ProfileModel?

    /// Indicates if the manager is ready for use
    @Published
    private(set) var isReady = false

    /// Last refresh timestamp
    @Published
    private(set) var lastRefreshDate: Date?

    // MARK: - State Updates

    /// Update profiles array
    func setProfiles(_ newProfiles: [ProfileModel]) {
        profiles = newProfiles
    }

    /// Update current profile based on active user ID
    func updateCurrentProfile(uid: String?) {
        guard let uid else {
            currentProfile = nil
            return
        }
        currentProfile = profiles.first { $0.uid == uid }
        log.debug("[ProfileState] Current profile updated: \(uid)")
    }

    /// Mark state as ready
    func markReady() {
        isReady = true
    }

    /// Update last refresh date
    func markRefreshed() {
        lastRefreshDate = Date()
    }

    /// Refresh profiles from storage
    func refreshFromStorage() {
        do {
            let loadedProfiles = try storage.loadAll()
            profiles = loadedProfiles
            log.debug("[ProfileState] Refreshed \(loadedProfiles.count) profiles from storage")
        } catch {
            log.error("[ProfileState] Failed to refresh from storage: \(error)")
        }
    }

    /// Update a single profile in the array
    func updateProfile(_ profile: ProfileModel) {
        if let index = profiles.firstIndex(where: { $0.uid == profile.uid }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }

        // Update current profile if it matches
        if currentProfile?.uid == profile.uid {
            currentProfile = profile
        }
    }

    /// Remove a profile from the array
    func removeProfile(userId: String) {
        profiles.removeAll { $0.uid == userId }

        if currentProfile?.uid == userId {
            currentProfile = nil
        }
    }

    // MARK: Private

    private let storage: ProfileStorageProtocol
}

// MARK: - ProfileCacheManager

/// Cache manager for profile data fetching
final class ProfileCacheManager: ProfileCacheProtocol {
    // MARK: Lifecycle

    init(validityInterval: TimeInterval = Constants.defaultValidityInterval) {
        self.validityInterval = validityInterval
    }

    // MARK: Internal

    enum Constants {
        static let defaultValidityInterval: TimeInterval = 5 * 60 // 5 minutes
    }

    func shouldFetch(profileId: String) -> Bool {
        guard let lastFetch = lastFetchTimes[profileId] else {
            return true
        }
        return Date().timeIntervalSince(lastFetch) > validityInterval
    }

    func markFetched(profileId: String) {
        lastFetchTimes[profileId] = Date()
    }

    func invalidate(profileId: String) {
        lastFetchTimes.removeValue(forKey: profileId)
    }

    func clearAll() {
        lastFetchTimes.removeAll()
    }

    // MARK: - Batch Operations

    /// Get profiles that need to be fetched
    func profilesNeedingFetch(from profiles: [ProfileModel]) -> [ProfileModel] {
        profiles.filter { shouldFetch(profileId: $0.uid) }
    }

    /// Mark multiple profiles as fetched
    func markAllFetched(profileIds: [String]) {
        let now = Date()
        for id in profileIds {
            lastFetchTimes[id] = now
        }
    }

    // MARK: Private

    private var lastFetchTimes: [String: Date] = [:]
    private let validityInterval: TimeInterval
}

// MARK: - ProfileRefreshDebouncer

/// Debouncer for profile refresh operations
final class ProfileRefreshDebouncer {
    // MARK: Lifecycle

    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }

    // MARK: Internal

    /// Debounce a refresh operation
    func debounce(_ operation: @escaping () async -> Void) {
        currentTask?.cancel()
        currentTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    /// Cancel any pending refresh
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    // MARK: Private

    private var currentTask: Task<Void, Never>?
    private let delay: TimeInterval
}
