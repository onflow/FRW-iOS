//
//  ProfileManager+Model.swift
//  FRW
//
//  Created by cat on 9/24/25.
//

import Foundation

// MARK: - ProfileModel

struct ProfileModel: Codable {
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

    func updated(username: String? = nil, avatar: String? = nil, wallets: [UserManager.StoreUser]? = nil) -> ProfileModel {
        // Preserve original creation date but update lastUpdated
        return ProfileModel(
            userIdAndPublickKeyPrefix: self.userIdAndPublickKeyPrefix,
            username: username ?? self.username,
            avatar: avatar ?? self.avatar,
            createdAt: self.createdAt, // Preserve original creation date
            lastUpdated: Date(), // Update timestamp
            version: self.version,
            wallets: wallets ?? self.wallets
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
}

extension ProfileModel {
  var uid: String {
    KeyProvider.getId(with: userIdAndPublickKeyPrefix)
  }
  
  var address: String {
    wallets.first?.address ?? "0x"
  }
  
  var subTitle: String {
    let count = wallets.count
    if count > 1 {
      return "\(count) \("addresses_tag".localized)"
    }
    return address
  }
}
