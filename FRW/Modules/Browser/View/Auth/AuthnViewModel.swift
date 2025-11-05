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

class AuthnViewModel: ObservableObject {

  var provider: AuthnDataProvider
  private var accounts: [RNBridge.WalletAccount] = []
  private var callback: AuthnViewModel.Callback?

  @Published var currentAccount: RNBridge.WalletAccount?
  @Published var linkedAccount: [RNBridge.WalletAccount] = []
  @Published var showAccountSelection: Bool = false
  
  init(provider: AuthnDataProvider,callback: @escaping AuthnViewModel.Callback) {
    self.provider = provider
    self.callback = callback
    buildEVMAccounts()
  }
  
  private func buildEVMAccounts() {
    accounts = []
    if let list = WalletManager.shared.EOAs {
      let result = list.map{ $0.toWalletAccount()}
      accounts.append(contentsOf: result)
      currentAccount = accounts.first
    }
    if let coa = WalletManager.shared.coa {
      accounts.append(coa.toWalletAccount())
    }
  }
  
  deinit {
    callback?(false)
    WalletConnectManager.shared.reloadPendingRequests()
  }
  
  var inBlacklist: Bool {
    BlocklistHandler.shared.inBlacklist(url: provider.url)
  }

  var compatibleAccounts: [RNBridge.WalletAccount] {
    accounts.filter { $0.id != currentAccount?.id }
  }

  func toggleAccountSelection() {
    withAnimation(.easeInOut(duration: 0.35)) {
      showAccountSelection.toggle()
    }
  }

  func selectAccount(_ account: RNBridge.WalletAccount) {
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
