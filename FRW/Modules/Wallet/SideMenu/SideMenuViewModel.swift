//
//  SideMenuViewModel.swift
//  FRW
//
//  Created by Hao Fu on 1/4/2025.
//

import Combine
import Factory
import Foundation
import SwiftUI

// MARK: - SideMenuViewModel

struct SideMenuItem {
  let account: WalletAccount
  var isHidden: Bool = false

  static func mock() -> SideMenuItem {
    SideMenuItem(account: .mockMain())
  }
}

class SideMenuViewModel: ObservableObject {
    // MARK: Internal

    @Injected(\.wallet)
    private var wallet: WalletManager

    @Published var hasCoa: Bool = true
    @Published var currentAccount: SideMenuItem? = nil
    @Published var allAccounts: [[SideMenuItem]] = [[.mock()],[.mock()],[.mock()]]
    @Published var shouldShowMigrationCard: Bool = false
    private var cancellableSet = Set<AnyCancellable>()


    init() {
      ProfileManager.shared.$currentProfile
        .receive(on: DispatchQueue.main)
        .sink { [weak self] profile in
          self?.refreshProfile(profile: profile)
        }
        .store(in: &cancellableSet)

      wallet.$selectedAccount
        .receive(on: DispatchQueue.main)
        .sink { [weak self] account in
          self?.refreshAccount(address: account?.hexAddr)
        }.store(in: &cancellableSet)

      // Listen for hidden addresses changes
      NotificationCenter.default.publisher(for: .hiddenAddressesDidChanged)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
          self?.onHiddenAddressesChanged()
        }
        .store(in: &cancellableSet)
    }

    private func refreshProfile(profile: ProfileModel?) {
      guard let profile = profile, profile.accounts.count > 0 else {
        log.debug("[Profile] profile:\(profile?.uid ?? "")")
        refreshAccount(address: nil)
        allAccounts = [[.mock()],[.mock()],[.mock()]]
        return
      }
      allAccounts = profile.accounts.map({ list in
        list.map { account in
          // Check if manually hidden via LocalUserDefaults
          let isManuallyHidden = LocalUserDefaults.shared.isAddressHidden(account.address, for: profile.uid)
          // Combine with original isHidden logic (balance/NFT based)
          let isHidden = account.isHidden || isManuallyHidden
          return SideMenuItem(account: account, isHidden: isHidden)
        }
      })
      if let address = wallet.selectedAccount?.hexAddr {
        refreshAccount(address: address)
        updateMigrationCardVisibility(for: currentAccount)
      }
    }

    private func refreshAccount(address: String?) {
      guard let address = address else {
        currentAccount = nil
        log.debug("[Profile] find current account:\(address ?? "")")
        return
      }
      var result: SideMenuItem? = nil
      for list in allAccounts {
        for account in list {
          if account.account.address.lowercased() == address.lowercased() {
            result = account
            break
          }
        }
        if result != nil {
          break
        }
      }
      log.debug("[Profile] find current account:\(result?.account)")
      withAnimation(.easeInOut) {
        currentAccount = result
      }
    }
  
    func updateCurrentAccount(_ selectedAccount: SideMenuItem) {
        WalletManager.shared.switchSelectedAccount(selectedAccount.account)
        NotificationCenter.default.post(name: .toggleSideMenu)
        updateMigrationCardVisibility(for: selectedAccount)
    }

    func switchAccountMoreAction() {
        Router.route(to: RouteMap.Profile.switchProfile)
    }

    func onClickEnableEVM() {
        NotificationCenter.default.post(name: .toggleSideMenu)
        Router.route(to: RouteMap.Wallet.enableEVM)
    }

    func onClickMigrationCard() {
        NotificationCenter.default.post(name: .toggleSideMenu)
        Router.route(to: RouteMap.ReactNative.migration)
    }

    private func onHiddenAddressesChanged() {
        // Refresh hidden states for all accounts
        guard let profile = ProfileManager.shared.currentProfile else { return }
        refreshProfile(profile: profile)
    }

    private func updateMigrationCardVisibility(for item: SideMenuItem?) {
      shouldShowMigrationCard = false
      guard let coaMigration = RemoteConfigManager.shared.config?.features.coaMigration, coaMigration else {
        return
      }
      guard let item else {
        return
      }
      guard item.account.type == .coa else {
        return
      }

      guard let list = wallet.EOAs, list.count > 0 else {
        return
      }

      let address = item.account.address.lowercased()
      guard let group = allAccounts.first(where: { accounts in
        accounts.contains { $0.account.address.lowercased() == address }
      }) else {
        return
      }

      guard let coaAccount = group.first(where: { account in
        account.account.type == .coa
      }) else {
        return
      }
      let balance = coaAccount.account.assets.balance ?? 0
      let nftCount = coaAccount.account.assets.nftCount ?? 0
      let erc20Count = coaAccount.account.assets.erc20Balance ?? 0
      withAnimation(.easeInOut) {
        self.shouldShowMigrationCard = balance > 0 || nftCount > 0 || erc20Count > 0
      }
    }

}
