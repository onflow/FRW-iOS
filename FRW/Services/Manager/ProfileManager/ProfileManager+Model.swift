//
//  ProfileManager+Model.swift
//  FRW
//
//  Created by cat on 9/24/25.
//

import Foundation

// MARK: - ProfileModel

struct ProfileModel: Codable, Equatable {
  private static let expirationInterval: TimeInterval = 5 * 60

  // MARK: Lifecycle

  init(
    uid: String,
    username: String? = nil,
    avatar: String? = nil,
    createdAt: Date = Date(),
    lastUpdated: Date = Date(),
    wallets: [UserManager.StoreUser] = [],
    accounts: [[WalletAccount]] = [],
    expirationDate: Date? = nil
  ) {
    let version = Bundle.main
      .infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let resolvedLastUpdated = lastUpdated
    let defaultExpiration = Date().addingTimeInterval(ProfileModel.expirationInterval)
    let resolvedExpirationDate = expirationDate ?? defaultExpiration
    self.init(
      uid: uid,
      username: username,
      avatar: avatar,
      createdAt: createdAt,
      lastUpdated: resolvedLastUpdated,
      version: version,
      wallets: wallets,
      accounts: accounts,
      expirationDate: resolvedExpirationDate
    )
  }

  init(userInfo: UserInfo, with uid: String, wallets: [UserManager.StoreUser] = []) {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let now = Date()
    let expirationDate = now.addingTimeInterval(ProfileModel.expirationInterval)
    self.init(
      uid: uid,
      username: userInfo.nickname,
      avatar: userInfo.avatar,
      createdAt: now,
      lastUpdated: now,
      version: version,
      wallets: wallets,
      accounts: [],
      expirationDate: expirationDate
    )
  }

  // Additional initializer to support preserving dates
  private init(
    uid: String,
    username: String?,
    avatar: String?,
    createdAt: Date,
    lastUpdated: Date,
    version: String,
    wallets: [UserManager.StoreUser],
    accounts: [[WalletAccount]],
    expirationDate: Date?
  ) {
    self.uid = uid
    self.username = username
    self.avatar = avatar
    self.createdAt = createdAt
    self.lastUpdated = lastUpdated
    self.version = version
    self.wallets = wallets
    self.accounts = accounts
    self.expirationDate = expirationDate
  }

  // MARK: Internal

  let uid: String
  let username: String?
  let avatar: String?
  let createdAt: Date
  let lastUpdated: Date
  let version: String
  let wallets: [UserManager.StoreUser]
  let expirationDate: Date?
  let accounts: [[WalletAccount]]


  // MARK: - Equatable

  static func == (lhs: ProfileModel, rhs: ProfileModel) -> Bool {
    let lhsCount = lhs.accounts.reduce(0) { $0 + $1.count }
    let rhsCount = rhs.accounts.reduce(0) { $0 + $1.count }
    return lhs.uid == rhs.uid && lhsCount == rhsCount
  }

  func replace(with users: [UserManager.StoreUser]) -> ProfileModel {
    let sortedUser = users.sorted { ($0.address ?? "") > ($1.address ?? "") }
    let lastUpdated = Date()
    return ProfileModel(
      uid: uid,
      username: username,
      avatar: avatar,
      createdAt: createdAt,
      lastUpdated: lastUpdated,
      version: version,
      wallets: sortedUser,
      accounts: accounts,
      expirationDate: expirationDate
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
    let lastUpdated = Date()
    return ProfileModel(
      uid: uid,
      username: username ?? self.username,
      avatar: avatar ?? self.avatar,
      createdAt: createdAt, // Preserve original creation date
      lastUpdated: lastUpdated, // Update timestamp
      version: version,
      wallets: existWallets,
      accounts: accounts,
      expirationDate: expirationDate
    )
  }

  func updatingAccounts(to newAccounts: [[WalletAccount]]) -> ProfileModel {
    ProfileModel(
      uid: uid,
      username: username,
      avatar: avatar,
      createdAt: createdAt,
      lastUpdated: Date(),
      version: version,
      wallets: wallets,
      accounts: newAccounts,
      expirationDate: expirationDate
    )
  }

  func hasExpired(at referenceDate: Date = Date()) -> Bool {
    guard let expirationDate else {
      return false
    }
    return referenceDate >= expirationDate
  }

  func refreshedExpiration(from referenceDate: Date = Date()) -> ProfileModel {
    ProfileModel(
      uid: uid,
      username: username,
      avatar: avatar,
      createdAt: createdAt,
      lastUpdated: lastUpdated,
      version: version,
      wallets: wallets,
      accounts: accounts,
      expirationDate: referenceDate.addingTimeInterval(Self.expirationInterval)
    )
  }
}

extension ProfileModel {

  var amountDes: String {
    let list = accounts.flatMap { $0 }
    let totalFlow = list.reduce(0.0) { result, account in
      result + (account.assets.balance ?? 0)
    }
    guard totalFlow > 0 else {
      return ""
    }
    return totalFlow.formatDisplayFlowBalance
  }

  var accountDes: String {
    let count = accounts.flatMap { $0 }.filter { !$0.isHidden }.count
    guard count > 0 else {
      return ""
    }
    return "\(count) Accounts"
  }
}
