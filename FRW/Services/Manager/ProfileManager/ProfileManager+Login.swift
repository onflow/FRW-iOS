//
//  ProfileManager+Login.swift
//  FRW
//
//  Created by cat on 9/29/25.
//

import Foundation

extension ProfileManager {
  func updateOrDeleteProfile(userInfo: UserInfo?, with uid: String) throws {
    guard let userInfo else {
//      deleteProfile(userId: uid)
      return
    }
    guard let profile = loadProfile(userId: uid) else {
      let users = findStoreUser(uid: uid)
      let newProfile = ProfileModel(userInfo: userInfo, with: uid, wallets: users)
      saveProfile(newProfile)
      return
    }
    let result = profile.updated(username: userInfo.nickname, avatar: userInfo.avatar )
    saveProfile(result)
  }
  
  func findStoreUser(uid: String) -> [UserManager.StoreUser] {
    let list = LocalUserDefaults.shared.userList
    return list.filter { $0.userId == uid }
  }
}
