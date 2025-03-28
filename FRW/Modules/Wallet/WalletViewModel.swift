//
//  WalletViewModel.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/7.
//

import Combine
import Flow
import FlowWalletKit
import Foundation
import SwiftUI
import SwiftUIPager

extension WalletViewModel {
    enum WalletState {
        case idle
        case noAddress
        case loading
        case error
    }

    struct WalletCoinItemModel: Mockable {
        let token: TokenModel
        let balance: Double
        let last: Double
        let changePercentage: Double

        var changeIsNegative: Bool {
            changePercentage < 0
        }

        var priceValue: String? {
            guard last != 0 || token.symbol == "fusd" else {
                return nil
            }
            return "\(CurrencyCache.cache.currencySymbol)\(token.symbol == "fusd" ? CurrencyCache.cache.currentCurrencyRate.formatCurrencyString(digits: 4) : last.formatCurrencyString(digits: 4, considerCustomCurrency: true))"
        }

        var changeString: String {
            if changePercentage == 0 {
                return "-"
            }
            let symbol = changeIsNegative ? "-" : "+"
            let num = String(format: "%.1f", fabsf(Float(changePercentage) * 100))
            return "\(symbol)\(num)%"
        }

        var changeColor: Color {
            changeIsNegative ? Color.Flow.Font.descend : Color.Flow.Font.ascend
        }

        var changeBG: Color {
            if changePercentage == 0 {
                return Color.Theme.Background.grey.opacity(0.16)
            }
            return changeIsNegative ? Color.Flow.Font.descend.opacity(0.16) : Color.Flow.Font.ascend
                .opacity(0.16)
        }

        var balanceAsCurrentCurrency: String {
            (balance * last).formatCurrencyString(digits: 4, considerCustomCurrency: true)
        }

        static func mock() -> WalletViewModel.WalletCoinItemModel {
            WalletCoinItemModel(
                token: TokenModel.mock(),
                balance: 999,
                last: 10,
                changePercentage: 50
            )
        }
    }
}

// MARK: - WalletViewModel

final class WalletViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        WalletManager.shared.$walletInfo
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] newInfo in
                guard newInfo?.currentNetworkWalletModel?.getAddress != nil else {
                    self?.walletState = .noAddress
                    self?.balance = 0
                    self?.coinItems = []
                    return
                }
                self?.refreshButtonState()
                self?.reloadWalletData()
                self?.updateMoveAsset()
            }.store(in: &cancelSets)

        WalletManager.shared.$activatedCoins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshCoinItems()
            }.store(in: &cancelSets)

        WalletConnectManager.shared.$pendingRequests
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.pendingRequestCount = WalletConnectManager.shared.pendingRequests.count
            }.store(in: &cancelSets)

        ThemeManager.shared.$style.sink { _ in
            DispatchQueue.main.async {
                self.updateTheme()
            }
        }.store(in: &cancelSets)

        NotificationCenter.default.publisher(for: .walletHiddenFlagUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshHiddenFlag()
            }.store(in: &cancelSets)

        NotificationCenter.default.publisher(for: .coinSummarysUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshCoinItems()
            }.store(in: &cancelSets)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }

                if self.lastRefreshTS == 0 {
                    return
                }

                if abs(self.lastRefreshTS - Date().timeIntervalSince1970) > self
                    .autoRefreshInterval
                {
                    self.reloadWalletData()
                }
            }.store(in: &cancelSets)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(transactionCountDidChanged),
            name: .transactionCountDidChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willReset),
            name: .willResetWallet,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReset),
            name: .didResetWallet,
            object: nil
        )

        refreshButtonState()

        EVMAccountManager.shared.$accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshButtonState()
                self?.updateMoveAsset()
            }.store(in: &cancelSets)
        ChildAccountManager.shared.$childAccounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshButtonState()
                self?.updateMoveAsset()
            }.store(in: &cancelSets)
    }

    // MARK: Internal

    @Published
    var isHidden: Bool = LocalUserDefaults.shared.walletHidden
    @Published
    var balance: Double = 0
    @Published
    var coinItems: [WalletCoinItemModel] = []
    @Published
    var walletState: WalletState = .noAddress
    @Published
    var transactionCount: Int = LocalUserDefaults.shared.transactionCount
    @Published
    var pendingRequestCount: Int = 0
    @Published
    var backupTipsPresent: Bool = false

    @Published
    var isMock: Bool = false

    @Published
    var moveAssetsPresent: Bool = false
    @Published
    var moveTokenPresent: Bool = false

    @Published
    var currentPage: Int = 0
    @Published
    var page: Page = .first()

    @Published
    var showHeaderMask = false

    @Published
    var showAddTokenButton: Bool = true
    @Published
    var showSwapButton: Bool = true
    @Published
    var showStakeButton: Bool = true
    @Published
    var showHorLayout: Bool = false

    @Published
    var showBuyButton: Bool = true

    @Published
    var showMoveAsset: Bool = false

    var needShowPlaceholder: Bool {
        isMock || walletState == .noAddress
    }

    var mCoinItems: [WalletCoinItemModel] {
        if needShowPlaceholder {
            return [WalletCoinItemModel].mock()
        } else {
            return coinItems
        }
    }

    // MARK: Private

    private var lastRefreshTS: TimeInterval = 0
    private let autoRefreshInterval: TimeInterval = 30

    private var isReloading: Bool = false

    /// If the current account is not backed up, each time start app, backup tips will be displayed.
    private var backupTipsShown: Bool = false

    private var cancelSets = Set<AnyCancellable>()

    private func updateTheme() {
        showHeaderMask = false
        if ThemeManager.shared.style == .dark {
            showHeaderMask = true
            return
        }
        // check has notification
    }

    private func refreshHiddenFlag() {
        isHidden = LocalUserDefaults.shared.walletHidden
    }

    private func refreshCoinItems() {
        var list = [WalletCoinItemModel]()
        for token in WalletManager.shared.activatedCoins {
            if token.hasBalance {
                let summary = CoinRateCache.cache.getSummary(by: token.contractId)
                let item = WalletCoinItemModel(
                    token: token,
                    balance: WalletManager.shared
                        .getBalance(with: token).doubleValue,
                    last: summary?.getLastRate() ?? 0,
                    changePercentage: summary?.getChangePercentage() ?? 0
                )
                list.append(item)
            }
        }
        list.sort { first, second in
            if first.balance * first.last == second.balance * second.last {
                return first.last > second.last
            } else {
                return first.balance * first.last > second.balance * second.last
            }
        }
        coinItems = list

        refreshTotalBalance()

        // Disable this backup tip for now, cause it show sometime incorrect
        // And our new backup flow is showing after account creation
        // showBackupTipsIfNeeded()
    }

    private func refreshTotalBalance() {
        var total: Double = 0
        for item in coinItems {
            let asUSD = item.balance * item.last
            total += asUSD
        }

        balance = total
    }

    private func showBackupTipsIfNeeded() {
        if !UserManager.shared.isLoggedIn {
            return
        }

        guard let uid = UserManager.shared.activatedUID else { return }

        if MultiAccountStorage.shared.getBackupType(uid) != .none {
            return
        }

        if WalletManager.shared.activatedCoins.isEmpty {
            return
        }

        if backupTipsShown {
            return
        }

        if backupTipsPresent {
            return
        }

        if balance <= 0.01 {
            return
        }

        if WalletManager.shared.isSelectedChildAccount {
            return
        }

        let result = WalletManager.shared.activatedCoins.filter { tokenModel in
            if !tokenModel.isFlowCoin {
                return WalletManager.shared.getBalance(with: tokenModel).doubleValue > 0.0
            }
            return false
        }

        if result.isEmpty, LocalUserDefaults.shared.nftCount == 0 {
            return
        }

        if LocalUserDefaults.shared.backupSheetNotAsk {
            return
        }

        backupTipsPresent = true
        backupTipsShown = true
    }

    private func reloadTransactionCount() {
        Task {
            do {
                var count = try await FRWAPI.Account.fetchAccountTransferCount()
                count += TransactionManager.shared.holders.count

                if count < LocalUserDefaults.shared.transactionCount {
                    return
                }

                let finalCount = count
                DispatchQueue.main.async {
                    LocalUserDefaults.shared.transactionCount = finalCount
                }
            } catch {
                debugPrint(
                    "WalletViewModel -> reloadTransactionCount, fetch transaction count failed: \(error)"
                )
            }
        }
    }

    @objc
    private func transactionCountDidChanged() {
        DispatchQueue.syncOnMain {
            self.transactionCount = LocalUserDefaults.shared.transactionCount
        }
    }

    @objc
    private func willReset() {
        LocalUserDefaults.shared.transactionCount = 0
    }

    @objc
    private func didReset() {
        backupTipsShown = false
    }

    private func updateMoveAsset() {
        log.info("[Home] update move asset status")
        showMoveAsset = EVMAccountManager.shared.accounts.count > 0 || !ChildAccountManager.shared
            .childAccounts.isEmpty
    }
}

// MARK: - Action

extension WalletViewModel {
    func reloadWalletData() {
        guard WalletManager.shared.getPrimaryWalletAddress() != nil else {
            return
        }
        UserManager.shared.verifyUserType()
        if isReloading {
            return
        }

        isReloading = true

        log.debug("reloadWalletData")

        lastRefreshTS = Date().timeIntervalSince1970
        walletState = .idle

        if coinItems.isEmpty {
            isMock = true
        }

        Task {
            do {
                try await WalletManager.shared.fetchWalletDatas()
                self.reloadTransactionCount()

                await MainActor.run {
                    self.isMock = false
                    self.isReloading = false
                }
            } catch {
                log.error("reload wallet data failed", context: error)
                await MainActor.run {
                    self.walletState = .error
                    self.isReloading = false
                    self.isMock = false
                }
            }
        }
    }

    func copyAddressAction() {
        UIPasteboard.general.string = WalletManager.shared.selectedAccountAddress
        HUD.success(title: "Address Copied".localized)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func toggleHiddenStatusAction() {
        LocalUserDefaults.shared.walletHidden = !isHidden
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func moveAssetsAction() {
        Router.route(to: RouteMap.Wallet.moveAssets)
    }

    func scanAction() {
        ScanHandler.scan()
    }

    func stakingAction() {
        if !LocalUserDefaults.shared.stakingGuideDisplayed, !StakingManager.shared.isStaked {
            Router.route(to: RouteMap.Wallet.stakingSelectProvider)
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Router.route(to: RouteMap.Wallet.stakingList)
    }

    func onAddToken() {
        guard ChildAccountManager.shared.selectedChildAccount == nil else {
            return
        }
        if EVMAccountManager.shared.selectedAccount != nil {
            Router.route(to: RouteMap.Wallet.addCustomToken)
        } else {
            Router.route(to: RouteMap.Wallet.addToken)
        }
    }

    func sideToggleAction() {
        NotificationCenter.default.post(name: .toggleSideMenu, object: nil)
    }

    func onPageIndexChangeAction(_ index: Int) {
        withAnimation(.default) {
            log.info("[Index] \(index)")
            currentPage = index
        }
    }

    func viewWillAppear() {
        if LocalUserDefaults.shared.shouldShowConfettiOnHome {
            LocalUserDefaults.shared.shouldShowConfettiOnHome = false
            ConfettiManager.show()
        }
    }
}

// MARK: - Change

extension WalletViewModel {
    func refreshButtonState() {
        let canAddToken = ChildAccountManager.shared
            .selectedChildAccount == nil // && EVMAccountManager.shared.selectedAccount == nil
        if canAddToken {
            showAddTokenButton = true
        } else {
            showAddTokenButton = false
        }

        let isChild = ChildAccountManager.shared.selectedChildAccount != nil
        let isNotPrimary = ChildAccountManager.shared
            .selectedChildAccount != nil || EVMAccountManager.shared.selectedAccount != nil
        // Swap
        if (RemoteConfigManager.shared.config?.features.swap ?? false) == true {
            // don't show when current is Linked account
            if isChild {
                showSwapButton = false
            } else {
                showSwapButton = true
            }
        } else {
            showSwapButton = false
        }

        // Stake
        if currentNetwork.isMainnet {
            if isNotPrimary {
                showStakeButton = false
            } else {
                showStakeButton = true
            }
        } else {
            showStakeButton = false
        }

        showHorLayout = (showSwapButton == false && showStakeButton == false)

        // buy
        if RemoteConfigManager.shared.config?.features.onRamp ?? false == true,
           flow.chainID == .mainnet
        {
            if isNotPrimary {
                showBuyButton = false
            } else {
                showBuyButton = true
            }

        } else {
            showBuyButton = false
        }
    }
}
