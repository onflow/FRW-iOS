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
  typealias Callback = (Bool) -> Void
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

  @Published var currentAccount: AuthnAccountProvider? = nil
  @Published var allowSelection = false
  @Published var showAccountSelection: Bool = false
  
  init(provider: AuthnDataProvider,callback: @escaping AuthnViewModel.Callback) {
    self.provider = provider
    self.callback = callback
    loadCurrentEVM()
  }
  
  private func loadCurrentEVM() {
    
    var accounts: [RNBridge.WalletAccount] = []
    let eoa = WalletManager.shared.EOAs?.map { $0.toWalletAccount() } ?? []
    accounts.append(contentsOf: eoa)
    if let coa = WalletManager.shared.coa?.toWalletAccount() {
      accounts.append(coa)
    }
    let preAddress = LocalUserDefaults.shared.EVMDefaultAddress ?? "emtpy"
    if let account =  accounts.first { $0.address == preAddress } ?? accounts.first {
      currentAccount = AuthnAccountProvider(account: account, linkAccounts: [])
    }
    allowSelection = accounts.count > 1
  }
  
  deinit {
    callback?(false)
    WalletConnectManager.shared.reloadPendingRequests()
  }
  
  var inBlacklist: Bool {
    BlocklistHandler.shared.inBlacklist(url: provider.url)
  }

  func toggleAccountSelection() {
    if allowSelection {
      
    }
  }

  func selectAccount(_ account: AuthnAccountProvider) {
    currentAccount = account
    withAnimation(.easeInOut(duration: 0.35)) {
      showAccountSelection = false
    }
  }

  func didChooseAction(_ result: Bool) {
      Router.dismiss { [weak self] in
          guard let self else { return }
          callback?(result)
          callback = nil
      }
  }
}
