//
//  WalletManager+WalletAccount.swift
//  FRW
//
//  Created by cat on 7/11/25.
//

import Foundation
import FlowWalletKit

extension FlowWalletKit.Wallet {
  func buildWalletAccounts(userId: String? = nil) async throws -> [[RNBridge.WalletAccount]] {
    var result: [[RNBridge.WalletAccount]] = []
    
    // EOA accounts for current network
    let eoa = eoaAddress?.compactMap({ EOA($0, network: currentNetwork)?.toWalletAccount(userId: userId) }) ?? []
    result.append(eoa)
    
    // Safely unwrap accounts for the current network
    if let accountsByNetwork = accounts,
       let networkAccounts = accountsByNetwork[currentNetwork] {
        var linkedGroups: [[RNBridge.WalletAccount]] = []
        for account in networkAccounts {
          let group = try await account.buildWalletAccount(userId: userId)
          linkedGroups.append(group)
        }
        result.append(contentsOf: linkedGroups)
    }
    
    return result
  }
}

extension FlowWalletKit.Account {
  /// fetch linked account and convert to `WalletAccount`
  func buildWalletAccount(userId: String? = nil) async throws -> [RNBridge.WalletAccount] {
      if !hasLinkedAccounts {
        try await fetchAccount()
      }
      var result: [RNBridge.WalletAccount] = []
      let mainAccount = toWalletAccount(userId: userId)
      result.append(mainAccount)
      
      if let account = coa {
        let linkedAccount = account.toWalletAccount(parentAddress: mainAccount.address, userId: userId)
        result.append(linkedAccount)
      }
    
      if let childAccount = childs {
        let linkedAccounts = childAccount.map{ $0.toWalletAccount(parentAddress: mainAccount.address,userId: userId) }
        result.append(contentsOf: linkedAccounts)
      }
      return result
  }
}
