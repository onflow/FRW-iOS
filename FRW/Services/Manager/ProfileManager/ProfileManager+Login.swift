//
//  ProfileManager+Login.swift
//  FRW
//
//  Created by cat on 9/29/25.
//

import Foundation

extension ProfileManager {
  func updateOrDeleteProfile(userInfo: UserInfo?, with uid: String) throws {
    if let userInfo {
      guard loadProfile(userId: uid) == nil else {
        return
      }
      let users = findStoreUser(uid: uid)
      let newProfile = ProfileModel(userInfo: userInfo, with: uid, wallets: users)
      saveProfile(newProfile)
    } else {
      deleteProfile(userId: uid)
    }
  }
  
  func findStoreUser(uid: String) -> [UserManager.StoreUser] {
    let list = LocalUserDefaults.shared.userList
    return list.filter { $0.userId == uid }
  }
}
