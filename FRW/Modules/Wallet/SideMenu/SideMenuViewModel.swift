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

// MARK: - SideMenuViewModel.AccountPlaceholder

extension SideMenuViewModel {
    struct AccountPlaceholder {
        let uid: String
        let avatar: String
    }
}

// MARK: - SideMenuViewModel

class SideMenuViewModel: ObservableObject {
    // MARK: Internal

    @Injected(\.wallet)
    private var wallet: WalletManager

    @Injected(\.token)
    private var token: TokenBalanceHandler

    @Published
    var accountLoading: Bool = false

    @Published
    var linkLoading: Bool = false

    @Published
    var userInfoBackgroudColor = Color.LL.Neutrals.neutrals6

    @Published
    var mainAccounts: [String] = []

    @Published
    var linkedAccounts: [String] = []

    @Published
    var walletBalance: [String: Decimal] = [:]

    var colorsMap: [String: Color] = [:]

    var currentAddress: String {
        WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? ""
    }

    private var cancellableSet = Set<AnyCancellable>()

    // MARK: Lifecycle

    init() {
        wallet.$mainAccount
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.loadBalance()
            }
            .store(in: &cancellableSet)

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
            }
            .store(in: &cancellableSet)
    }

    func loadBalance() {
        Task {
            let mainAccounts = wallet.currentNetworkAccounts.compactMap(\.hexAddr)
            var linksAccounts: [String] = []
            linksAccounts = wallet.childs?.compactMap(\.address.hex) ?? []
            if let coa = wallet.coa {
                linksAccounts.insert(coa.address, at: 0)
            }

            let accounts = mainAccounts + linksAccounts

            if accounts.isEmpty {
                return
            }
            do {
                let result = try await token.getAvailableFlowBalance(addresses: accounts, forceReload: true)
                await MainActor.run {
                    walletBalance = result
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
