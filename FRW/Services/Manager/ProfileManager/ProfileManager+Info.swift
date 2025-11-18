//
//  ProfileManager+Info.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import Foundation

extension ProfileManager {
  /// update account by address for current profile
  func updateAccount(at address: String) {
    guard let profile = currentProfile else {
      return
    }
    var list: [RNBridge.WalletAccount] = []
    let accounts = profile.accounts ?? []
    for account in accounts {
      var newAccount = account
      if account.address.uppercased() == address {
        newAccount = account.updatedFromEmoji()
      }
      list.append(newAccount)
    }
    let newProfile = profile.updatingAccounts(to: list)
    saveProfile(newProfile)
    currentProfile = newProfile
  }
}
