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
  
  init() {
    ProfileManager.shared.$currentProfile
      .receive(on: DispatchQueue.main)
      .sink { [weak self] profile in
        self?.updateAccounts(profile: profile)
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
  
  func hideType(with account: [RNBridge.WalletAccount]) -> AccountHideType {
    //TODO:
    return .hidden
  }
  
}
