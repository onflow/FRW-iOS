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

//MARK: - refresh Current Profile
extension ProfileManager {
  /// Refresh the current profile's accounts by fetching latest data
  /// This updates account balances, COA assets, and child accounts
  func refreshCurrentProfileAccounts() async {
    guard let currentProfile = currentProfile else {
      log.warning("[Profile] No current profile to refresh")
      return
    }

    do {
      log.debug("[Profile] Starting refresh for current profile: \(currentProfile.uid)")

      // Fetch updated account information for current profile only
      let accountResult = try await fetchAccounts(profiles: [currentProfile])
      log.debug("[Profile] Fetched account data")

      let balanceResult = try await fetchFlowAmount(profiles: accountResult)
      log.debug("[Profile] Fetched balance data")

      let result = try await fetchCOANFTs(profiles: balanceResult)
      log.debug("[Profile] Fetched COA assets")

      // Update the profile in the main profiles array
      await MainActor.run {
        if let index = profiles.firstIndex(where: { $0.uid == currentProfile.uid }) {
          profiles[index] = result.first ?? currentProfile
          updateCurrentProfile()
          saveProfile(result.first ?? currentProfile)
          log.info("[Profile] Successfully refreshed current profile accounts")
        }
      }
    } catch {
      log.error("[Profile] Failed to refresh current profile accounts: \(error)")
    }
  }
}
