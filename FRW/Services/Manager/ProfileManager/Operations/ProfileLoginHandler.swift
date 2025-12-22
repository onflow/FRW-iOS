//
//  ProfileLoginHandler.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Foundation

// MARK: - ProfileManager+Login

extension ProfileManager {
  /// Update or create profile based on user info during login
  /// - Parameters:
  ///   - userInfo: User information from authentication
  ///   - uid: User ID
  func updateOrDeleteProfile(userInfo: UserInfo?, with uid: String) {
    guard let userInfo else {
      return
    }

    // Check if profile already exists
    var profile: ProfileModel?
    if let existingProfile = loadProfile(userId: uid) {
      // Update existing profile
      let updated = existingProfile.updated(
        username: userInfo.nickname,
        avatar: userInfo.avatar
      )
      // During login, key should exist - skip validation to ensure profile is saved
      saveProfile(updated, validateKey: false)
      profile = updated
      log.info("[ProfileLogin] Updated profile: \(uid)")
    } else {
      // Create new profile
      let wallets = findStoreUser(uid: uid)
      let newProfile = ProfileModel(
        userInfo: userInfo,
        with: uid,
        wallets: wallets
      )
      // During login, key should exist - skip validation to ensure profile is saved
      saveProfile(newProfile, validateKey: false)
      profile = newProfile
      log.info("[ProfileLogin] Created new profile: \(uid)")
    }

    // Fetch account info async with polling (won't drop the profile due to merge logic)
    Task {
      if let profile {
        await refreshProfileAccountWithPolling(profile: profile)
      }
    }
  }

  /// Find store users for a given UID from legacy storage
  func findStoreUser(uid: String) -> [UserManager.StoreUser] {
    LocalUserDefaults.shared.userList.filter { $0.userId == uid }
  }
  
  /// Refresh profile account with timed polling
  /// Polls every 5 seconds until accounts are found or 5 minutes timeout
  private func refreshProfileAccountWithPolling(profile: ProfileModel) async {
    let timeoutDuration: TimeInterval = 5 * 60 // 5 minutes
    let pollingInterval: TimeInterval = 5 // 5 seconds between polls
    let startTime = Date()
    var attemptCount = 0

    while Date().timeIntervalSince(startTime) < timeoutDuration {
      attemptCount += 1
      let elapsed = Int(Date().timeIntervalSince(startTime))

      do {
        let updated = try await fetchService.fetchAccounts(for: [profile])

        // Check if we got any accounts
        if let refreshed = updated.first, !refreshed.accounts.isEmpty {
          // Success: we got accounts, now fetch full info (balances + NFTs)
          let withAllInfo = try await fetchService.fetchAllAccountInfo(for: [refreshed])

          await MainActor.run {
            if let final = withAllInfo.first {
              saveProfile(final, validateKey: false)
              log.info("[ProfileLogin] Refreshed profile accounts after \(attemptCount) attempt(s), \(elapsed)s elapsed")
            }
          }
          return
        }

        // No accounts yet, wait before next poll
        log.info("[ProfileLogin] No accounts found, polling again in \(Int(pollingInterval))s (attempt \(attemptCount), \(elapsed)s elapsed)")
        try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))

      } catch {
        log.warning("[ProfileLogin] Fetch failed (attempt \(attemptCount), \(elapsed)s elapsed): \(error)")
        // Wait before retry on error
        try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
      }
    }

    let totalElapsed = Int(Date().timeIntervalSince(startTime))
    log.warning("[ProfileLogin] No accounts found after \(attemptCount) attempts, timeout reached (\(totalElapsed)s)")
  }
}
