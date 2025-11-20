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
        log.debug("fetch account")
        let BalanceResult = try await fetchFlowAmount(profiles: accountResult)
        log.debug("fetch balance")
        let result = try await fetchCOANFTs(profiles: BalanceResult)
        log.debug("fetch coa asset")
        await MainActor.run {
          profiles = result
          updateCurrentProfile()
          saveProfiles(result)
        }
      }
    }
  }
  
  private func fetchAccounts(profiles: [ProfileModel]) async throws -> [ProfileModel] {
    let supportNetworks: Set<Flow.ChainID> = [currentNetwork]
    var profilesOfAddedAccount: [ProfileModel] = []
    for profile in profiles {
      guard let provider = getKeyProvider(uid: profile.uid) else {
        continue
      }
      var walletAccounts: [[WalletAccount]] = []
      let walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
      try? await walletEntity.fetchAccount()
      guard let accountList =  walletEntity.accounts?[currentNetwork] else {
        continue
      }
      if let eoas = walletEntity.eoaAddress {
        let result = Array(eoas).compactMap {
          EOA($0, network: currentNetwork)?.toWalletAccount(userId: profile.uid)
        }
        walletAccounts.append(contentsOf: [result])
      }
      for account in accountList {
        guard let result = try? await parseAccount(account: account, userId: profile.uid) else {
          continue
        }
        walletAccounts.append(result)
      }
      // Wrap accounts in a 2D array structure (single group for now)
      let newProfile = profile.updatingAccounts(to: walletAccounts)
      profilesOfAddedAccount.append(newProfile)
    }
    return profilesOfAddedAccount
  }

  private func parseAccount(account: FlowWalletKit.Account, userId: String? = nil) async throws ->  [WalletAccount] {
    var list: [WalletAccount] = []
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
      profile.accounts.flatMap { $0 }.compactMap { $0.address }
    }
    let token = CadenceTokenBalanceProvider()
    let result = try await token.getAvailableFlowBalance(addresses: addresses)
    var profilesOfAddedBalance: [ProfileModel] = []
    for profile in profiles {
      // Update accounts while preserving 2D array structure
      let updatedGroups = profile.accounts.map { group in
        group.map { account in
          var newAccount = account
          if let amount = result[account.address] {
            newAccount = account.copyWith(balance: amount.doubleValue)
          }
          return newAccount
        }
      }
      let newProfile = profile.updatingAccounts(to: updatedGroups)
      profilesOfAddedBalance.append(newProfile)
    }
    return profilesOfAddedBalance
  }

  private func fetchCOANFTs(profiles: [ProfileModel]) async throws -> [ProfileModel] {
    let addresses = profiles.flatMap { profile in
      profile.accounts.flatMap { $0 }.compactMap { ($0.type == .coa ? $0.address : nil) }
    }
    let token = await EVMTokenBalanceProvider()
    var countForCOA: [String: Int] = [:]
    for addr in addresses {
      if let FWAddr = FWAddressDector.create(address: addr) {
        let result = try await token.getNFTCollections(address: FWAddr)
        countForCOA[addr] = result.reduce(0) {$0 + $1.count}
      }
    }

    var profilesOfAddedBalance: [ProfileModel] = []
    for profile in profiles {
      // Update accounts while preserving 2D array structure
      let updatedGroups = profile.accounts.map { group in
        group.map { account in
          var newAccount = account
          if newAccount.type == .coa {
            if let amount = countForCOA[account.address], amount > 0 {
              newAccount = account.copyWith(nftCount: amount)
            }
          }
          return newAccount
        }
      }
      let newProfile = profile.updatingAccounts(to: updatedGroups)
      profilesOfAddedBalance.append(newProfile)
    }
    return profilesOfAddedBalance
  }

  private func getKeyProvider(uid: String) -> (any KeyProtocol)? {
    if let provider = try? SecureEnclaveKey.wallet(id: uid),
       let publicKey = provider.publicKey()?.hexString {
      return provider
    }

    if let provider = try? SeedPhraseKey.wallet(id: uid) {
      return provider
    }

    if let provider = try? PrivateKey.wallet(id: uid) {
      return provider
    }
    return nil
  }
}
