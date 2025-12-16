//
//  ProfileWalletHandler.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import FlowWalletKit
import Foundation

// MARK: - ProfileManager+Wallet

extension ProfileManager {
    /// Update profile with wallet account information
    /// - Parameters:
    ///   - uid: User ID
    ///   - keyProvider: Key provider for signing
    ///   - wallet: Wallet entity containing account data
    func update(uid: String, keyProvider: any KeyProtocol, with wallet: FlowWalletKit.Wallet?) {
        guard let profile = loadProfile(userId: uid) else {
            log.warning("[ProfileWallet] Profile not found: \(uid)")
            return
        }

        guard let accounts = wallet?.accounts?[currentNetwork] else {
            log.warning("[ProfileWallet] No accounts found for network")
            return
        }

        // Find valid accounts with full weight key
        let validAccounts = accounts.filter { $0.hasFullWeightKey }
        guard let flowKey = validAccounts.first?.fullWeightKey else {
            log.warning("[ProfileWallet] No valid full weight key found")
            return
        }

        // Build store user list
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

        replace(profile: profile, with: userStoreList)
        log.info("[ProfileWallet] Updated profile \(uid) with \(userStoreList.count) accounts")
    }
}
