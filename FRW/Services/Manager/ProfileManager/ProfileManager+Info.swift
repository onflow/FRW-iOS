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
    // Flatten, update, and preserve grouping structure
    let updatedGroups = profile.accounts.map { group in
      group.map { account in
        if account.address.uppercased() == address {
          return account.updatedFromEmoji()
        }
        return account
      }
    }
    let newProfile = profile.updatingAccounts(to: updatedGroups)
    saveProfile(newProfile)
    currentProfile = newProfile
  }
}
