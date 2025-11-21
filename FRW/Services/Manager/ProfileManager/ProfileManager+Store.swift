//
//  ProfileManager+Store.swift
//  FRW
//
//  Created by cat on 9/24/25.
//

import Foundation
import KeychainAccess

// MARK: - ProfileKeychainService

class ProfileKeychainService {
  // MARK: Lifecycle

  init() {
    self.keychain = Keychain(service: "com.flowfoundation.frw.profiles")
      .accessibility(.whenUnlockedThisDeviceOnly)
      .synchronizable(false)
  }

  // MARK: Internal

  // MARK: - Profile Operations

  func saveProfile(_ profile: ProfileModel) throws {
    let key = profileKeyPrefix + profile.uid
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970

    do {
      let data = try encoder.encode(profile)
      try keychain.set(data, key: key)
      try updateProfileIndex(with: profile.uid)
    } catch {
      log.error("[Profile] Save profile failed for user \(profile.uid): \(error)")
      throw ProfileError.keychainError(.unexpectedError)
    }
  }

  func loadProfile(userId: String) throws -> ProfileModel? {
    let key = profileKeyPrefix + userId

    do {
      guard let data = try keychain.getData(key) else {
        return nil
      }

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .secondsSince1970
      let profile = try decoder.decode(ProfileModel.self, from: data)
      return profile
    } catch {
      log.error("[Profile] Load profile failed for user \(userId): \(error)")
      throw ProfileError.decodingError
    }
  }

  func deleteProfile(userId: String) throws {
    let key = profileKeyPrefix + userId

    do {
      try keychain.remove(key)
      try removeFromProfileIndex(userId: userId)
    } catch {
      log.error("[Profile] Delete profile failed for user \(userId): \(error)")
      throw ProfileError.keychainError(.unexpectedError)
    }
  }

  func getAllProfileIds() throws -> [String] {
    do {
      guard let data = try keychain.getData(indexKey) else {
        log.warning("[Profile] empty profile")
        return []
      }

      let decoder = JSONDecoder()
      let profileIds = try decoder.decode([String].self, from: data)
      return profileIds
    } catch {
      log.error("[Profile] Get all profile IDs failed: \(error)")
      return []
    }
  }

  func getAllProfiles() throws -> [ProfileModel] {
    let profileIds = try getAllProfileIds()
    log.debug("[Profile] all profile ids \n \(profileIds)")
    var profiles: [ProfileModel] = []

    for userId in profileIds {
      if let profile = try loadProfile(userId: userId) {
        profiles.append(profile)
      }
    }

    return profiles
  }

  // MARK: - Utility

  func clearAllProfiles() throws {
    let profileIds = try getAllProfileIds()

    for userId in profileIds {
      try deleteProfile(userId: userId)
    }

    try keychain.remove(indexKey)
    try keychain.remove(metadataKey)
  }

  // MARK: Private

  private let keychain: Keychain
  private let profileKeyPrefix = "profiles_"
  private let metadataKey = "profiles_metadata"
  private let indexKey = "profiles_index"

  // MARK: - Index Management

  private func updateProfileIndex(with userId: String) throws {
    var profileIds = try getAllProfileIds()

    if !profileIds.contains(userId) {
      profileIds.append(userId)

      let encoder = JSONEncoder()
      let data = try encoder.encode(profileIds)
      try keychain.set(data, key: indexKey)
    }
  }

  private func removeFromProfileIndex(userId: String) throws {
    var profileIds = try getAllProfileIds()
    profileIds.removeAll { $0 == userId }

    let encoder = JSONEncoder()
    let data = try encoder.encode(profileIds)
    try keychain.set(data, key: indexKey)
  }
}
