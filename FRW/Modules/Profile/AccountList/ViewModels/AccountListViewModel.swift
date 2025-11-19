//
//  AccountListViewModel.swift
//  FRW
//
//  Created by cat on 11/13/25.
//

import Foundation
import Combine

enum AccountHideType {
  case none
  case visible
  case hidden
}

class AccountListViewModel: ObservableObject {
  
  @Published var allAccounts: [[RNBridge.WalletAccount]] = []
  private var cancelSets = Set<AnyCancellable>()
  private var uid: String?

  init() {
    ProfileManager.shared.$currentProfile
      .receive(on: DispatchQueue.main)
      .sink { [weak self] profile in
        self?.updateAccounts(profile: profile)
      }
      .store(in: &cancelSets)
    uid = ProfileManager.shared.currentProfile?.uid

    // Listen for hidden addresses changes
    NotificationCenter.default.publisher(for: .hiddenAddressesDidChanged)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.onHiddenAddressesChanged()
      }
      .store(in: &cancelSets)
  }

  private func updateAccounts(profile: ProfileModel?) {
    guard let profile = profile else {
      allAccounts = []
      return
    }
    allAccounts = profile.accounts
    if let currentAddress = WalletManager.shared.selectedAccount?.address.hexAddr {
      if let index = allAccounts.firstIndex(where: { $0.first?.address == currentAddress }) {
        let selectedAccount = allAccounts.remove(at: index)
        allAccounts.insert(selectedAccount, at: 0)
      }
    }
  }
  
  func hideType(with accounts: [RNBridge.WalletAccount]) -> AccountHideType {
    guard let mainAccount = accounts.first(where: { $0.type == .main || $0.type == .eoa }),
          let uid
    else {
      return .none
    }
    let result = LocalUserDefaults.shared.isAddressHidden(mainAccount.address, for: uid)
    return result ? .hidden : .visible
  }

  func showAddress(at address: String) {
    guard let uid else {
      return
    }
    LocalUserDefaults.shared.removeHiddenAddress(address, for: uid)
  }

  private func onHiddenAddressesChanged() {
    // Trigger view update to refresh hide/show states
    objectWillChange.send()
  }

}
