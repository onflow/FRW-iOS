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
    private var cancellableSet = Set<AnyCancellable>()


    init() {
      ProfileManager.shared.$currentProfile
        .compactMap { $0 }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] profile in
          self?.refreshProfile(profile: profile)
        }
        .store(in: &cancellableSet)

      wallet.$selectedAccount
        .receive(on: DispatchQueue.main)
        .compactMap { $0 }
        .sink { [weak self] account in
          self?.refreshAccount(address: account.hexAddr)
        }.store(in: &cancellableSet)

      // Listen for hidden addresses changes
      NotificationCenter.default.publisher(for: .hiddenAddressesDidChanged)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
          self?.onHiddenAddressesChanged()
        }
        .store(in: &cancellableSet)
    }

    private func refreshProfile(profile: ProfileModel) {
      allAccounts = profile.accounts.map({ list in
        list.map { account in
          // Check if manually hidden via LocalUserDefaults
          let isManuallyHidden = LocalUserDefaults.shared.isAddressHidden(account.address, for: profile.uid)
          // Combine with original isHidden logic (balance/NFT based)
          let isHidden = account.isHidden || isManuallyHidden
          return SideMenuItem(account: account, isHidden: isHidden)
        }
      })
      if let address = currentAccount?.account.address {
        refreshAccount(address: address)
      }
    }

    private func refreshAccount(address: String?) {
      for list in allAccounts {
        for account in list {
          if account.account.address.lowercased() == address?.lowercased() {
            withAnimation(.easeInOut) {
              currentAccount = account
            }
            break
          }
        }
      }
    }
  
    func updateCurrentAccount(_ selectedAccount: SideMenuItem) {
        WalletManager.shared.changeSelectedAccount(address: selectedAccount.account.address, type: selectedAccount.account.FWAccountType)
        NotificationCenter.default.post(name: .toggleSideMenu)
    }

    func switchAccountMoreAction() {
        Router.route(to: RouteMap.Profile.switchProfile)
    }

    func onClickEnableEVM() {
        NotificationCenter.default.post(name: .toggleSideMenu)
        Router.route(to: RouteMap.Wallet.enableEVM)
    }

    private func onHiddenAddressesChanged() {
        // Refresh hidden states for all accounts
        guard let profile = ProfileManager.shared.currentProfile else { return }
        refreshProfile(profile: profile)
    }

}

