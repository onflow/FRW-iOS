//
//  SideMenuViewModel.swift
//  FRW
//
//  Created by Hao Fu on 1/4/2025.
//

import Combine
import Factory
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

    @Published
    var activeAccount: AccountModel? = nil

    @Published
    var accounts: [[AccountModel]] = []

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
                self?.refreshAccounts()
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
}

// MARK: - Refresh Data

extension SideMenuViewModel {
    private func refreshActiveAccount() {
        let current: AccountInfoProtocol? = WalletManager.shared.selectedChildAccount ?? WalletManager.shared.selectedEVMAccount ?? WalletManager.shared.mainAccount
        guard let current else {
            return
        }
        activeAccount = AccountModel(account: current, mainAccount: WalletManager.shared.isSelectedFlowAccount ? nil : WalletManager.shared.mainAccount, flowCount: "0", nftCount: 0)
    }

    func refreshAccounts() {
        refreshActiveAccount()
        let list = WalletManager.shared.currentNetworkAccounts
        Task {
            var results: [[AccountModel]] = []
            await withTaskGroup(of: [AccountModel]?.self) { group in
                for account in list {
                    group.addTask {
                        do {
                            return try await self.fetchMetadata(account: account)
                        } catch {
                            log.info("[SideMenu] fetch child or coa failed:\(error)")
                            return nil
                        }
                    }
                }
                for await result in group {
                    if let result = result {
                        results.append(result)
                    }
                }
            }
            let sortedResult = results.sorted { lhs, rhs in

                guard let l = lhs.first, let r = rhs.first else { return false }

                let lFlow = Double(l.flowCount) ?? 0
                let rFlow = Double(r.flowCount) ?? 0
                if lFlow != rFlow {
                    return lFlow > rFlow
                }
                return l.nftCount > r.nftCount
            }
            await MainActor.run {
                self.accounts = sortedResult
            }
        }
    }

    private func fetchMetadata(account: FlowWalletKit.Account) async throws -> [AccountModel] {
        try? await account.fetchAccount()
        let countInfo = await fetchCount(account: account)

        var tmp: [AccountModel] = []
        let mainInfo = countInfo[account.hexAddr] ?? .empty
        tmp.append(AccountModel(account: account, flowCount: String(mainInfo.flowBalance), nftCount: mainInfo.nftCounts))
        if let coa = account.coa {
            let coaInfo = countInfo[coa.address] ?? .empty
            tmp.append(AccountModel(account: coa, mainAccount: account, flowCount: String(coaInfo.flowBalance), nftCount: coaInfo.nftCounts))
        }
        if let child = account.childs {
            let result = child.map { child in
                let childInfo = countInfo[child.address.hexAddr] ?? .empty
                return AccountModel(account: child, mainAccount: account, flowCount: String(childInfo.flowBalance), nftCount: childInfo.nftCounts)
            }
            let sortedResult = result.sorted { lhs, rhs in
                let lhsFlow = Double(lhs.flowCount) ?? 0
                let rhsFlow = Double(rhs.flowCount) ?? 0
                if lhsFlow != rhsFlow {
                    return lhsFlow > rhsFlow
                }
                return lhs.nftCount > rhs.nftCount
            }
            tmp.append(contentsOf: sortedResult)
        }
        return tmp
    }

    private func fetchCount(account: FlowWalletKit.Account) async -> [String: FlowNFTCountModel] {
        do {
            var addressList: [String] = [account.hexAddr]
            if let address = account.coa?.address {
                addressList.append(address)
            }
            if let childs = account.childs {
                addressList.append(contentsOf: childs.map { $0.address.hexAddr })
            }
            let countInfo = try await FlowNetwork.getFlowTokenAndNFTCount(addresses: addressList)
            return countInfo
        } catch {
            log.error(error)
            return [:]
        }
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
