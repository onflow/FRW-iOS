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

class SideMenuViewModel: ObservableObject {
    // MARK: Internal

    @Injected(\.wallet)
    private var wallet: WalletManager

    @Injected(\.token)
    private var token: TokenBalanceHandler

    @Published var accountLoading: Bool = false

    @Published
    var linkLoading: Bool = false

    @Published
    var userInfoBackgroudColor = Color.LL.Neutrals.neutrals6

    @Published
    var walletBalance: [String: Decimal] = [:]

    var colorsMap: [String: Color] = [:]

    @Published var hasCoa: Bool = true
    @Published var currentAccount: RNBridge.WalletAccount? = nil
    @Published var allAccounts: [[RNBridge.WalletAccount]] = []
    private var cancellableSet = Set<AnyCancellable>()

    // MARK: Lifecycle

    init() {

        wallet.$walletEntity
            .compactMap { $0 }
            .flatMap { $0.$isLoading }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
              log.debug("----1")
              self?.accountLoading = value
            }
            .store(in: &cancellableSet)

        wallet.$mainAccount
            .compactMap { $0 }
            .flatMap { $0.$isLoading }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.linkLoading = value
                if !value {
                    log.debug("----2")
                    self?.fetchAllAccounts()
                }
            }
            .store(in: &cancellableSet)
      
    }
  
    private func fetchAllAccounts() {
      guard allAccounts.isEmpty else {
        return
      }
      Task {
        do {
          let userId = UserManager.shared.activatedUID
          let result = try await wallet.walletEntity?.buildWalletAccounts(userId: userId) ?? []
          await MainActor.run {
            self.currentAccount =  wallet.mainAccount?.toWalletAccount()
            self.allAccounts = result
            self.accountLoading = false
            self.hasCoa = (wallet.coa != nil)
            self.loadBalance()
          }
        } catch {
          await MainActor.run {
            self.accountLoading = false
          }
          log.error("[SideMenu] Failed to build wallet accounts: \(error)")
        }
      }
    }
  
    func updateCurrentAccount(_ selectedAccount: RNBridge.WalletAccount) {
        self.currentAccount = selectedAccount
        WalletManager.shared.changeSelectedAccount(address: selectedAccount.address, type: selectedAccount.FWAccountType)
        NotificationCenter.default.post(name: .toggleSideMenu)
    }

    func loadBalance() {
        Task {
          do {
              let allAddresses = allAccounts.flatMap { $0.compactMap(\.address) }
              let result = try await token.getAvailableFlowBalance(addresses: allAddresses, forceReload: true)
              await MainActor.run {
                  // 遍历 allAccounts，更新每个 account 的 balance 字段
                  self.allAccounts = self.allAccounts.map { group in
                      group.map { account in
                          let balance = result[account.address] ?? 0
                          let flowString = balance.doubleValue.formatDisplayFlowBalance
                          return account.copyWith(flow: flowString)
                      }
                  }
                  self.currentAccount = self.currentAccount.map { account in
                      let balance = result[account.address] ?? 0
                    let flowString = balance.doubleValue.formatDisplayFlowBalance
                    return account.copyWith(flow: flowString)
                  }
              }
          } catch {
              log.debug(error)
          }
        }
    }

    func pickColor(from url: String) {
        guard !url.isEmpty else {
            userInfoBackgroudColor = Color.LL.Neutrals.neutrals6
            return
        }
        if let color = colorsMap[url] {
            userInfoBackgroudColor = color
            return
        }
        Task {
            let color = await ImageHelper.mostFrequentColor(from: url)
            await MainActor.run {
                self.colorsMap[url] = color
                self.userInfoBackgroudColor = color
            }
        }
    }

    func switchAccountMoreAction() {
        Router.route(to: RouteMap.Profile.switchProfile)
    }

    func onClickEnableEVM() {
        NotificationCenter.default.post(name: .toggleSideMenu)
        Router.route(to: RouteMap.Wallet.enableEVM)
    }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()
}

