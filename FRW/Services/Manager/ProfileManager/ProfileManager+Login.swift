//
//  ProfileManager+Login.swift
//  FRW
//
//  Created by cat on 9/29/25.
//

import Foundation

extension ProfileManager {
  func updateProfile(userInfo: UserInfo?, with uid: String) throws {
    if let userInfo {
      guard loadProfile(userId: uid) == nil else {
        return
      }
      let newProfile = ProfileModel(userInfo: userInfo, with: uid)
      saveProfile(newProfile)
    } else {
      deleteProfile(userId: uid)
    }
  }
}
