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
  let account: WalletAccount
  let linkAccounts: [WalletAccount]
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
    // Flatten 2D array before filtering
    let flattenedAccounts = profile.accounts.flatMap { $0 }
    let eoaAccount = flattenedAccounts.filter { $0.type == .eoa }
    let coaAccount = flattenedAccounts.filter { $0.type == .coa && $0.parent?.address == mainAddress }
    let eoa = eoaAccount.compactMap { AuthnAccountProvider(account: $0, linkAccounts: []) }
    let coa = coaAccount.compactMap { AuthnAccountProvider(account: $0, linkAccounts: []) }

    let coaWhiteList = RemoteConfigManager.shared.coaDomains
    if coaWhiteList.contains(where: { provider.url.lowercased().contains($0.lowercased()) }) {
      accounts.append(contentsOf: coa)
      accounts.append(contentsOf: eoa)
    } else {
      accounts.append(contentsOf: eoa)
      accounts.append(contentsOf: coa)
    }

    // Try to get cached address for current uid and host, fallback to first account
    let cachedAddress = getCachedAddress()
    if let cached = cachedAddress,
       let cachedAccount = accounts.first(where: { $0.account.address == cached }) {
      currentAccount = cachedAccount
    } else {
      currentAccount = accounts.first
    }
    allowSelection = accounts.count > 1
  }

  // Extract host from URL
  private var hostFromURL: String {
    guard let url = URL(string: provider.url),
          let host = url.host else {
      return provider.url
    }
    return host
  }

  // Get cached address for current uid and host
  private func getCachedAddress() -> String? {
    guard let uid = LocalUserDefaults.shared.activatedUID else {
      return nil
    }
    return LocalUserDefaults.shared.getAuthnAddress(for: uid, host: hostFromURL)
  }

  // Save selected address to cache
  private func saveCachedAddress(_ address: String) {
    guard let uid = LocalUserDefaults.shared.activatedUID else {
      return
    }
    LocalUserDefaults.shared.setAuthnAddress(address, for: uid, host: hostFromURL)
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
      if let address = currentAccount?.account.address {
          saveCachedAddress(address)
      }
      Router.dismiss { [weak self] in
          guard let self else { return }
          callback?(currentAccount?.account.address)
          callback = nil
          log.debug("[Authn] confirm clicked")
      }
  }
}
