//
//  AuthnViewModel.swift
//  FRW
//
//  Created by cat on 10/31/25.
//

import Foundation
import Flow

extension AuthnViewModel {
  typealias Callback = (Bool) -> Void
}

protocol AuthnDataProvider {
  
  var title: String { get }
  var url: String { get }
  var address: String { get }
  var logo: String? { get }
  var network: Flow.ChainID { get }
}

extension AuthnDataProvider {
  var network: Flow.ChainID {
    currentNetwork
  }
}

class AuthnViewModel: ObservableObject {
  
  @Published var provider: AuthnDataProvider
  private var callback: AuthnViewModel.Callback?
  
  init(provider: AuthnDataProvider,callback: @escaping AuthnViewModel.Callback) {
    self.provider = provider
    self.callback = callback
  }
  
  deinit {
    callback?(false)
    WalletConnectManager.shared.reloadPendingRequests()
  }
  
  var inBlacklist: Bool {
    BlocklistHandler.shared.inBlacklist(url: provider.url)
  }
  
  func didChooseAction(_ result: Bool) {
      Router.dismiss { [weak self] in
          guard let self else { return }
          callback?(result)
          callback = nil
      }
  }
}
