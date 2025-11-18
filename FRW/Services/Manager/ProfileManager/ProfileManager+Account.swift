//
//  ProfileManager+Account.swift
//  FRW
//
//  Created by cat on 11/17/25.
//

import Foundation
import FlowWalletKit
import Flow

extension ProfileManager {
  func fetchAllAccountsInfo() {
    Task {
      do {
        let accountResult = try await fetchAccounts(profiles: profiles)
        let BalanceResult = try await fetchFlowAmount(profiles: accountResult)
        let result = try await fetchCOANFTs(profiles: BalanceResult)
        await MainActor.run {
          profiles = result
          saveProfiles(result)
        }
      }
    }
  }
  
  private func fetchAccounts(profiles: [ProfileModel]) async throws -> [ProfileModel] {
    let supportNetworks: Set<Flow.ChainID> = [currentNetwork]
    var profilesOfAddedAccount: [ProfileModel] = []
    for profile in profiles {
      guard let provider = await WalletManager.shared.keyProvider(profile: profile) else {
        continue
      }
      var walletAccounts: [RNBridge.WalletAccount] = []
      let walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
      try? await walletEntity.fetchAccount()
      guard let accountList =  walletEntity.accounts?[currentNetwork] else {
        continue
      }
      if let eoas = walletEntity.eoaAddress {
        let result = Array(eoas).compactMap {
          EOA($0, network: currentNetwork)?.toWalletAccount(parentAddress: nil, userId: profile.uid)
        }
        walletAccounts.append(contentsOf: result)
      }
      for account in accountList {
        guard let result = try? await parseAccount(account: account, userId: profile.uid) else {
          continue
        }
        walletAccounts.append(contentsOf: result)
      }
      let newProfile = profile.updatingAccounts(to: walletAccounts)
      profilesOfAddedAccount.append(newProfile)
    }
    return profilesOfAddedAccount
  }

  private func parseAccount(account: FlowWalletKit.Account, userId: String? = nil) async throws ->  [RNBridge.WalletAccount] {
    var list: [RNBridge.WalletAccount] = []
    try? await account.fetchAccount()
    list.append(account.toWalletAccount(userId: userId))
    if let linked = account.coa {
      list.append(linked.toWalletAccount(parentAddress: account.hexAddr, userId: userId))
    }

    if let childList = account.childs {
      let result = childList.map { $0.toWalletAccount(parentAddress: account.hexAddr, userId: userId) }
      list.append(contentsOf: result)
    }
    return list
  }

  private func fetchFlowAmount(profiles: [ProfileModel]) async throws -> [ProfileModel] {
    let addresses = profiles.flatMap { profile in
      profile.accounts?.compactMap { $0.address } ?? []
    }
    let token = CadenceTokenBalanceProvider()
    let result = try await token.getAvailableFlowBalance(addresses: addresses)
    var profilesOfAddedBalance: [ProfileModel] = []
    for profile in profiles {
      var newAccounts: [RNBridge.WalletAccount] = []
      for account in profile.accounts ?? [] {
        var newAccount = account
        if let amount = result[account.address] {
          newAccount = account.copyWith(flow: String(amount.doubleValue))
        }
        newAccounts.append(newAccount)
      }
      let newProfile = profile.updatingAccounts(to: newAccounts)
      profilesOfAddedBalance.append(newProfile)
    }
    return profilesOfAddedBalance
  }

  private func fetchCOANFTs(profiles: [ProfileModel]) async throws -> [ProfileModel] {
    let addresses = profiles.flatMap { profile in
      profile.accounts?.compactMap { ($0.type == .evm ? $0.address : nil) } ?? []
    }
    let token = EVMTokenBalanceProvider()
    var countForCOA: [String: Int] = [:]
    for addr in addresses {
      if let FWAddr = FWAddressDector.create(address: addr) {
        let result = try await token.getNFTCollections(address: FWAddr)
        countForCOA[addr] = result.reduce(0) {$0 + $1.count}
      }
    }

    var profilesOfAddedBalance: [ProfileModel] = []
    for profile in profiles {
      var newAccounts: [RNBridge.WalletAccount] = []
      for account in profile.accounts ?? [] {
        var newAccount = account
        if newAccount.type == .evm {
          if let amount = countForCOA[account.address], amount > 0 {
            newAccount = account.copyWith(nft: String(amount))
          }
        }
        newAccounts.append(newAccount)
      }
      let newProfile = profile.updatingAccounts(to: newAccounts)
      profilesOfAddedBalance.append(newProfile)
    }
    return profilesOfAddedBalance
  }

}
