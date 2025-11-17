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
  let account:RNBridge.WalletAccount
  var isHidden: Bool = false
}

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
    @Published var currentAccount: SideMenuItem? = nil
    @Published var filterAccounts: [[SideMenuItem]] = []
    private var cancellableSet = Set<AnyCancellable>()

    // MARK: Lifecycle

    init() {

        wallet.$walletEntity
            .compactMap { $0 }
            .flatMap { $0.$isLoading }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
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
                    self?.fetchAllAccounts()
                }
            }
            .store(in: &cancellableSet)
      
    }
  
    private func fetchAllAccounts() {
      guard filterAccounts.isEmpty else {
        return
      }
      Task {
        do {
          let userId = UserManager.shared.activatedUID
          let result = try await wallet.walletEntity?.buildWalletAccounts(userId: userId) ?? []
          await MainActor.run {
            let currentWalletAccount = wallet.mainAccount?.toWalletAccount()
            self.currentAccount = currentWalletAccount.map { SideMenuItem(account: $0) }
            self.filterAccounts = result.map { list in
              list.map { SideMenuItem(account: $0, isHidden: $0.type == .evm) }
            }
            self.accountLoading = false
            self.hasCoa = (wallet.coa != nil)
            self.loadBalance()
            self.loadCOAAsset()
          }
        } catch {
          await MainActor.run {
            self.accountLoading = false
          }
          log.error("[SideMenu] Failed to build wallet accounts: \(error)")
        }
      }
    }
  
    func updateCurrentAccount(_ selectedAccount: SideMenuItem) {
        self.currentAccount = selectedAccount
        WalletManager.shared.changeSelectedAccount(address: selectedAccount.account.address, type: selectedAccount.account.FWAccountType)
        NotificationCenter.default.post(name: .toggleSideMenu)
    }

    func loadBalance() {
        Task {
          do {
              let allAddresses = filterAccounts.flatMap { $0.compactMap { $0.account.address } }
              let result = try await token.getAvailableFlowBalance(addresses: allAddresses, forceReload: true)
              await MainActor.run {
                  self.filterAccounts = self.filterAccounts.map { group in
                      group.map { item in
                          let balance = result[item.account.address] ?? 0
                          let flowString = balance.doubleValue.formatDisplayFlowBalance
                          let updatedAccount = item.account.copyWith(flow: flowString)
                          return SideMenuItem(account: updatedAccount, isHidden: item.isHidden)
                      }
                  }
                  self.currentAccount = self.currentAccount.map { item in
                      let balance = result[item.account.address] ?? 0
                    let flowString = balance.doubleValue.formatDisplayFlowBalance
                    let updatedAccount = item.account.copyWith(flow: flowString)
                    return SideMenuItem(account: updatedAccount, isHidden: item.isHidden)
                  }
              }
          } catch {
              log.debug(error)
          }
        }
    }

    func loadCOAAsset() {
      Task {
          // Collect all EVM account addresses
          let evmAddresses = filterAccounts.flatMap { list in
            list.filter { $0.account.type == .evm }
                .map { $0.account.address }
          }

          // Early return if no EVM accounts
          guard !evmAddresses.isEmpty else { return }

          do {
              // Fetch COA assets
              let coaAssets = try await WalletManager.shared.fetchCOAAsset(addresses: evmAddresses)

              // Create lookup dictionary for O(1) access (case-insensitive)
              let coaAssetDict = Dictionary(
                  uniqueKeysWithValues: coaAssets.map {
                      ($0.address.lowercased(), $0)
                  }
              )

              // Update filterAccounts on main thread
              await MainActor.run {
                  self.filterAccounts = self.filterAccounts.map { list in
                      list.map { item in
                          // Only update EVM accounts
                          guard item.account.type == .evm else { return item }

                          // Check if COA asset exists (case-insensitive)
                          let hasCoaAsset = coaAssetDict[item.account.address.lowercased()] != nil

                          // Show EVM accounts that have COA assets, hide those that don't
                          return SideMenuItem(
                              account: item.account,
                              isHidden: !hasCoaAsset
                          )
                      }
                  }
              }
          } catch {
              log.error("[SideMenu] Failed to load COA assets: \(error)")
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

