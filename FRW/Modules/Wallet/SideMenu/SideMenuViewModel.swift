//
//  SideMenuViewModel.swift
//  FRW
//
//  Created by Hao Fu on 1/4/2025.
//

import Combine
import Factory
import Flow
import FlowWalletKit
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
    @Published var isCreating: Bool = false

    @Published
    var isUpdateFlag: Bool = false

    @Published
    var userInfoBackgroudColor = Color.LL.Neutrals.neutrals6

    @Published
    var activeAccount: AccountModel? = nil

    @Published
    var userInfo: UserInfo? = nil

    @Published var filterAccounts: [AccountModel] = []

    @Published
    var hasCoa: Bool = true

    var colorsMap: [String: Color] = [:]

    var currentAddress: String {
        WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? ""
    }

    private var cancellableSet = Set<AnyCancellable>()

    // MARK: Lifecycle

    init() {
        wallet.$walletEntity
            .compactMap { $0 }
            .flatMap { $0.$isLoading }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.accountLoading = value
            }
            .store(in: &cancellableSet)

        wallet.$mainAccount
            .compactMap { $0 }
            .flatMap { $0.$coa }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.hasCoa = (value != nil)
            }
            .store(in: &cancellableSet)

        wallet.$selectedAccount
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshActiveAccount()
            }
            .store(in: &cancellableSet)

        wallet.$walletAccount
            .compactMap { $0 }
            .flatMap { $0.$info }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isUpdateFlag.toggle()
            }
            .store(in: &cancellableSet)

        UserManager.shared.$allAccounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshList()
            }
            .store(in: &cancellableSet)

        UserManager.shared.filterAccounts.$filterAccounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshList()
            }
            .store(in: &cancellableSet)
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

    func onAddAccount() {
        let closure: StringClosure = { [weak self] action in
            if action == AddAccountSheet.Action.create.rawValue {
                self?.createAccount()
            } else if action == AddAccountSheet.Action.recover.rawValue {
                self?.recoverAccount()
            }
        }
        Router.route(to: RouteMap.SideMenu.addAccount(closure))
    }

    func onClickEnableEVM() {
        NotificationCenter.default.post(name: .toggleSideMenu)
        Router.route(to: RouteMap.Wallet.enableEVM)
    }

    private func createAccount() {
        isCreating = true
        Task {
            do {
                guard let accountKey = await WalletManager.shared.mainAccount?.fullWeightKey else {
                    log.error("don't find full weight key")
                    HUD.error(title: "don't find full weight key")
                    await MainActor.run {
                        self.isCreating = false
                    }
                    return
                }

                let requestParam = CreateAddress(hashAlgorithm: accountKey.hashAlgo.index, publicKey: accountKey.publicKey.description, signatureAlgorithm: accountKey.signAlgo.index, weight: accountKey.weight)
                let response: UserAddressV2Response = try await Network.request(FRWAPI.User.createAddress(requestParam))
                let txId = Flow.ID(hex: response.txId)
                _ = try await txId.onceSealed()
                guard let model = try await WalletManager.shared.walletEntity?.fetchAccountsByCreationTxId(txId: txId, network: currentNetwork) else {
                    await MainActor.run {
                        self.isCreating = false
                    }
                    return
                }
                let fetcher = AccountFetcher()
                let accountModel = try await fetcher.fetchMetadata(account: model)
                await MainActor.run {
                    filterAccounts.append(accountModel)
                    HUD.success(title: "success_tips".localized)
                    self.isCreating = false
                }
            } catch {
                log.error(error)
                await MainActor.run {
                    self.isCreating = false
                }
            }
        }
    }

    private func recoverAccount() {
        log.debug("--")
    }
}

// MARK: - Refresh Data

extension SideMenuViewModel {
    private func refreshActiveAccount() {
        let current: AccountInfoProtocol? = WalletManager.shared.selectedChildAccount ?? WalletManager.shared.selectedEVMAccount ?? WalletManager.shared.mainAccount
        guard let current else {
            return
        }
        activeAccount = AccountModel(account: current, mainAccount: WalletManager.shared.isSelectedFlowAccount ? nil : WalletManager.shared.mainAccount, flowCount: "0", nftCount: 0, linkedAccounts: [])
    }

    private func refreshList() {
        filterAccounts = UserManager.shared.allAccounts.filter { inWhite(with: $0) }
    }

    func inWhite(with account: AccountModel) -> Bool {
        guard let mainAccount = account.account as? FlowWalletKit.Account else {
            return false
        }
        return UserManager.shared.filterAccounts.inFilter(with: mainAccount) ? false : true
    }
}

// MARK: - getter

extension SideMenuViewModel {
    var hasOtherAccounts: Bool {
        let hasCOA = WalletManager.shared.mainAccount?.hasCOA ?? false
        let hasChild = WalletManager.shared.mainAccount?.hasChild ?? false
        let hasOther = (WalletManager.shared.walletEntity?.accounts?.count ?? 0) > 1
        return hasCOA || hasChild || hasOther
    }
}
