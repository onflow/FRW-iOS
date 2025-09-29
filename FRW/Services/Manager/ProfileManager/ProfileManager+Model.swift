//
//  ProfileManager+Model.swift
//  FRW
//
//  Created by cat on 9/24/25.
//

import Foundation

// MARK: - ProfileModel

struct ProfileModel: Codable, Equatable {
  // MARK: Lifecycle

  init(
    uid: String,
    username: String? = nil,
    avatar: String? = nil,
    createdAt: Date = Date(),
    lastUpdated: Date = Date(),
    wallets: [UserManager.StoreUser] = []
  ) {
    let version = Bundle.main
      .infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    self.uid = uid
    self.username = username
    self.avatar = avatar
    self.createdAt = createdAt
    self.lastUpdated = lastUpdated
    self.version = version
    self.wallets = wallets
  }

  init(userInfo: UserInfo, with uid: String, wallets: [UserManager.StoreUser] = []) {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    self.uid = uid
    self.username = userInfo.nickname
    self.avatar = userInfo.avatar
    self.createdAt = Date()
    self.lastUpdated = Date()
    self.version = version
    self.wallets = wallets
  }

  // Additional initializer to support preserving dates
  private init(
    uid: String,
    username: String?,
    avatar: String?,
    createdAt: Date,
    lastUpdated: Date,
    version: String,
    wallets: [UserManager.StoreUser]
  ) {
    self.uid = uid
    self.username = username
    self.avatar = avatar
    self.createdAt = createdAt
    self.lastUpdated = lastUpdated
    self.version = version
    self.wallets = wallets
  }

  // MARK: Internal

  let uid: String
  let username: String?
  let avatar: String?
  let createdAt: Date
  let lastUpdated: Date
  let version: String
  let wallets: [UserManager.StoreUser]

  // MARK: - Equatable

  static func == (lhs: ProfileModel, rhs: ProfileModel) -> Bool {
    lhs.uid == rhs.uid
  }

  func replace(with users: [UserManager.StoreUser]) -> ProfileModel {
    let sortedUser = users.sorted { ($0.address ?? "") > ($1.address ?? "") }
    return ProfileModel(
      uid: uid,
      username: username,
      avatar: avatar,
      lastUpdated: Date(),
      wallets: sortedUser
    )
  }
  
  func updated(username: String? = nil,
    avatar: String? = nil,
    fromWallets: [UserManager.StoreUser]? = nil
  ) -> ProfileModel {
    var existWallets = wallets
    existWallets.append(contentsOf: fromWallets ?? [])
    // Remove those with the same address
    var seenAddresses = Set<String>()
    existWallets = existWallets.filter { user in
      let addr = (user.address ?? "").lowercased()
      guard !addr.isEmpty else { return false }
      guard !seenAddresses.contains(addr) else { return false }
      seenAddresses.insert(addr)
      return true
    }
    // sort by address
    existWallets.sort { ($0.address ?? "") > ($1.address ?? "") }
    // Preserve original creation date but update lastUpdated
    return ProfileModel(
      uid: uid,
      username: username ?? self.username,
      avatar: avatar ?? self.avatar,
      createdAt: createdAt, // Preserve original creation date
      lastUpdated: Date(), // Update timestamp
      version: version,
      wallets: existWallets
    )
  }
}

extension ProfileModel {
  var subTitle: String {
    let count = Set(wallets.compactMap { $0.address?.lowercased() }.filter { !$0.isEmpty }).count
    if count > 1 {
      return "\(count) \("addresses_tag".localized)"
    }
    return wallets.first?.address ?? ""
  }
}
