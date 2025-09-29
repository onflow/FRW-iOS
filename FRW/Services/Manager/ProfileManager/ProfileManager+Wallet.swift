//
//  ProfileManager+Wallet.swift
//  FRW
//
//  Created by cat on 9/29/25.
//

import Foundation
import FlowWalletKit

extension ProfileManager {
  func update(uid: String, keyProvider: any KeyProtocol, with wallet: FlowWalletKit.Wallet?) {
    guard let profile = loadProfile(userId: uid) else {
      return
    }
    guard let accounts = wallet?.accounts?[currentNetwork] else {
      return
    }
    let validAccount = accounts.filter({ $0.hasFullWeightKey })
    guard let flowKey = validAccount.first?.fullWeightKey else {
      return
    }
    let accountKey = flowKey.toStoreKey()
    let publicKey = flowKey.publicKey.hex
    
    var userStoreList: [UserManager.StoreUser] = []
    for account in accounts {
      let storeUser = UserManager.StoreUser(
        publicKey: publicKey,
        address: account.hexAddr,
        userId: profile.uid,
        keyType: keyProvider.keyType,
        account: accountKey
      )
      userStoreList.append(storeUser)
    }
    ProfileManager.shared.replace(profile: profile, with: userStoreList)
  }
}
