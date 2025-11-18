//
//  AuthnViewModel.swift
//  FRW
//
//  Created by cat on 10/31/25.
//

import Foundation
import Flow
import SwiftUI

extension AuthnViewModel {
  typealias Callback = (String?) -> Void
}

struct AuthnDataProvider {
  var title: String
  var url: String
  var address: String
  var logo: String?
  var network: Flow.ChainID = currentNetwork
}

struct AuthnAccountProvider {
  let account: RNBridge.WalletAccount
  let linkAccounts: [RNBridge.WalletAccount]
}

class AuthnViewModel: ObservableObject {

  var provider: AuthnDataProvider
  private var callback: AuthnViewModel.Callback?

  private var accounts: [AuthnAccountProvider] = []
  @Published var currentAccount: AuthnAccountProvider? = nil
  @Published var allowSelection = false
  @Published var showAccountSelection: Bool = false
  
  
  init(provider: AuthnDataProvider,callback: @escaping AuthnViewModel.Callback) {
    self.provider = provider
    self.callback = callback
    loadCurrentEVM()
  }
  
  private func loadCurrentEVM() {
    accounts = []
    guard let profile = ProfileManager.shared.currentProfile,
          let mainAddress = WalletManager.shared.mainAccount?.hexAddr
    else {
      return
    }
    let eoaAccount = profile.accounts?.filter { $0.type == .eoa }
    let coaAccount = profile.accounts?.filter { $0.type == .evm && $0.parentAddress == mainAddress && !$0.isHidden }
    let eoa = eoaAccount?.compactMap { AuthnAccountProvider(account: $0, linkAccounts: []) } ?? []
    accounts.append(contentsOf: eoa)
    let coa = coaAccount?.compactMap { AuthnAccountProvider(account: $0, linkAccounts: []) } ?? []
    accounts.append(contentsOf: coa)

    let preAddress = LocalUserDefaults.shared.EVMDefaultAddress ?? "emtpy"
    currentAccount =  accounts.first(where: { $0.account.address == preAddress }) ?? accounts.first
    allowSelection = accounts.count > 1
  }
  
  deinit {
    log.debug("[Authn] deinit call")
    callback?(nil)
    WalletConnectManager.shared.reloadPendingRequests()
  }
  
  var inBlacklist: Bool {
    BlocklistHandler.shared.inBlacklist(url: provider.url)
  }

  func toggleAccountSelection() {
    if allowSelection, let selectedAccount = currentAccount {
      let viewModel = AuthnAccountsViewModel(
        selectedAccount: selectedAccount,
        compatibleAccounts: accounts) { [weak self] provider in
          self?.currentAccount = provider
        }
      Router.route(to: RouteMap.Explore.accounts(viewModel))
    }
  }

  func selectAccount(_ account: AuthnAccountProvider) {
    currentAccount = account
    withAnimation(.easeInOut(duration: 0.35)) {
      showAccountSelection = false
    }
  }

  func didChooseAction(_ result: Bool) {
      LocalUserDefaults.shared.EVMDefaultAddress = currentAccount?.account.address
      Router.dismiss { [weak self] in
          guard let self else { return }
          callback?(currentAccount?.account.address)
          callback = nil
          log.debug("[Authn] confirm clicked")
      }
  }
}
