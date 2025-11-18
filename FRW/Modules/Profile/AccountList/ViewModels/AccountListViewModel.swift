//
//  AccountListViewModel.swift
//  FRW
//
//  Created by cat on 11/13/25.
//

import Foundation


enum AccountHideType {
  case none
  case visible
  case hidden
}

class AccountListViewModel: ObservableObject {
  
  @Published var allAccounts: [[RNBridge.WalletAccount]] = []
  
  
  init() {
    Task {
      do {
        let result = try await fetchAccounts()
        await MainActor.run {
          allAccounts =  result
        }
      } catch {
        log.error("fetch account failed. \(error)")
      }
    }
  }
  
  private func fetchAccounts() async throws -> [[RNBridge.WalletAccount]] {
    do {
      let wallet =  await WalletManager.shared
      let userId = UserManager.shared.activatedUID
      var result = try await wallet.walletEntity?.buildWalletAccounts(userId: userId) ?? []
      if let currentAddress =  await wallet.selectedAccount?.address.hexAddr {
        if let index = result.firstIndex(where: { $0.first?.address == currentAddress }) {
          let selectedAccount = result.remove(at: index)
          result.insert(selectedAccount, at: 0)
        }
      }
      return result
    } catch {
      log.error("fetch account failed.")
      throw error
    }
  }
  
  func hideType(with account: [RNBridge.WalletAccount]) -> AccountHideType {
    //TODO:
    return .none
  }
  
}
