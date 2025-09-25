//
//  ProfileManager+Model.swift
//  FRW
//
//  Created by cat on 9/24/25.
//

import Foundation

// MARK: - ProfileModel

struct ProfileModel: Codable, Equatable {
    let userIdAndPublickKeyPrefix: String
    let username: String?
    let avatar: String?
    let createdAt: Date
    let lastUpdated: Date
    let version: String
    let wallets: [UserManager.StoreUser]

    init(userIdAndPublickKeyPrefix: String, username: String? = nil, avatar: String? = nil, wallets: [UserManager.StoreUser] = []) {
        self.userIdAndPublickKeyPrefix = userIdAndPublickKeyPrefix
        self.username = username
        self.avatar = avatar
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.version = "3.0.1"
        self.wallets = wallets
    }

    func updated(username: String? = nil, avatar: String? = nil, fromWallets: [UserManager.StoreUser]? = nil) -> ProfileModel {
        var existWallets = self.wallets
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
            userIdAndPublickKeyPrefix: self.userIdAndPublickKeyPrefix,
            username: username ?? self.username,
            avatar: avatar ?? self.avatar,
            createdAt: self.createdAt, // Preserve original creation date
            lastUpdated: Date(), // Update timestamp
            version: self.version,
            wallets: existWallets
        )
    }

    // Additional initializer to support preserving dates
    private init(userIdAndPublickKeyPrefix: String, username: String?, avatar: String?, createdAt: Date, lastUpdated: Date, version: String, wallets: [UserManager.StoreUser]) {
        self.userIdAndPublickKeyPrefix = userIdAndPublickKeyPrefix
        self.username = username
        self.avatar = avatar
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.version = version
        self.wallets = wallets
    }

    // MARK: - Equatable
    static func == (lhs: ProfileModel, rhs: ProfileModel) -> Bool {
      return lhs.uid == rhs.uid
    }
}

extension ProfileModel {
  var uid: String {
    KeyProvider.getId(with: userIdAndPublickKeyPrefix)
  }
  
  var address: String {
    wallets.first?.address ?? ""
  }
  
  var subTitle: String {
    let count = Set(wallets.compactMap { $0.address?.lowercased() }.filter { !$0.isEmpty }).count
    if count > 1 {
      return "\(count) \("addresses_tag".localized)"
    }
    return address
  }
}
