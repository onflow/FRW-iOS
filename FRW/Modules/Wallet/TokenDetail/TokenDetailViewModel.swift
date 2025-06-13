//
//  TokenDetailViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 1/7/2022.
//

import Combine
import Flow
import SwiftUI
import SwiftUICharts
import Factory

extension TokenDetailView {
    struct Quote: Codable {
        let closeTime: Double
        let openPrice: Double
        let highPrice: Double
        let lowPrice: Double
        let closePrice: Double
        let volume: Double
        let quoteVolume: Double

        var generateChartPoint: LineChartDataPoint {
            let date = Date(timeIntervalSince1970: closeTime)
            let price = Double(closePrice.formatCurrencyString(
                digits: 2,
                considerCustomCurrency: true
            )) ?? 0
            return LineChartDataPoint(value: price, description: date.ymdString, date: date)
        }
    }

    enum PeriodFrequency: Int {
        case halfHour = 1800
        case oneHour = 3600
        case oneDay = 86400
        case threeDay = 259_200
        case oneWeek = 604_800
    }

    enum ChartRangeType: CaseIterable {
        case d1
        case w1
        case m1
        case m3
        case y1
        case all

        // MARK: Internal

        var title: String {
            switch self {
            case .d1:
                return "1D"
            case .w1:
                return "1W"
            case .m1:
                return "1M"
            case .m3:
                return "3M"
            case .y1:
                return "1Y"
            case .all:
                return "ALL"
            }
        }

        var frequency: TokenDetailView.PeriodFrequency {
            switch self {
            case .d1:
                return .halfHour
            case .w1:
                return .oneHour
            case .m1, .m3:
                return .oneDay
            case .y1:
                return .threeDay
            case .all:
                return .oneWeek
            }
        }

        var after: String {
            let oneDayInterval: TimeInterval = 24 * 60 * 60
            switch self {
            case .d1:
                return String(
                    format: "%.0lf",
                    Date(timeIntervalSinceNow: -oneDayInterval).timeIntervalSince1970
                )
            case .w1:
                return String(
                    format: "%.0lf",
                    Date(timeIntervalSinceNow: -oneDayInterval * 7).timeIntervalSince1970
                )
            case .m1:
                return String(
                    format: "%.0lf",
                    Date(timeIntervalSinceNow: -oneDayInterval * 30).timeIntervalSince1970
                )
            case .m3:
                return String(
                    format: "%.0lf",
                    Date(timeIntervalSinceNow: -oneDayInterval * 90).timeIntervalSince1970
                )
            case .y1:
                return String(
                    format: "%.0lf",
                    Date(timeIntervalSinceNow: -oneDayInterval * 365).timeIntervalSince1970
                )
            case .all:
                return ""
            }
        }
    }
}

// MARK: - TokenDetailViewModel.Action

extension TokenDetailViewModel {
    enum Action {
        case none
        case move
    }
}

// MARK: - TokenDetailViewModel

class TokenDetailViewModel: ObservableObject {
    // MARK: Lifecycle

    init(token: TokenModel) {
        self.token = token
        setupObserver()
        fetchAllData()
        refreshButtonState()
    }

    @Injected(\.wallet)
    private var wallet: WalletManager
    // MARK: Internal

    @Published
    var storageUsedRatio: Double = 0
    @Published
    var storageUsedDesc: String = ""
    @Published
    var storageFlow: Double = 0
    @Published
    var totalBalance: Double = 0
    @Published
    var token: TokenModel
    @Published
    var market: QuoteMarket = LocalUserDefaults.shared.market
    @Published
    var selectedRangeType: TokenDetailView.ChartRangeType = .d1
    @Published
    var chartData: LineChartData?
    @Published
    var balance: Double = 0
    @Published
    var balanceAsUSD: Double = 0
    @Published
    var changePercent: Double = 0
    @Published
    var rate: Double = 0
    @Published
    var recentTransfers: [FlowScanTransfer] = []

    @Published
    var showSwapButton: Bool = true
    @Published
    var showBuyButton: Bool = true
    @Published
    var showDeleteToken: Bool = false

    @Published
    var showSheet: Bool = false
    var buttonAction: TokenDetailViewModel.Action = .none

    // Only show storage info when it's flow token under flow account 
    var showStorageView: Bool { token.isFlowCoin && wallet.selectedAccount?.type == .main }

    var isTokenDetailsButtonEnabled: Bool { token.website.isNotNullNorEmpty }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()

    private func setupObserver() {
        NotificationCenter.default.publisher(for: .quoteMarketUpdated).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.market = LocalUserDefaults.shared.market
                self?.fetchAllData()
            }
        }.store(in: &cancelSets)

        NotificationCenter.default.publisher(for: .coinSummarysUpdated).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshSummary()
            }
        }.store(in: &cancelSets)

        WalletManager.shared.$activatedCoins.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshSummary()
            }
        }.store(in: &cancelSets)
    }
}

// MARK: - Getter

extension TokenDetailViewModel {
    var changePercentString: String {
        let num = String(format: "%.1f", fabsf(Float(changePercent) * 100))
        return "\(num)%"
    }

    var balanceString: String {
        balance.formatCurrencyString()
    }

    var balanceAsCurrentCurrencyString: String {
        balanceAsUSD.formatCurrencyString(considerCustomCurrency: true)
    }

    var changeIsNegative: Bool {
        changePercent < 0
    }

    var changeColor: Color {
        changeIsNegative ? Color.LL.Warning.warning2 : Color.LL.Success.success2
    }

    var hasRateAndChartData: Bool {
        if let token = ListedToken(rawValue: token.symbol ?? "") {
            if case .query = token.priceAction {
                return true
            }
        }
        return false
    }

    var movable: Bool {
        EVMAccountManager.shared
            .hasAccount &&
            (token.evmAddress != nil || token.identifier != nil || token.isFlowCoin)
    }

    var verifiedValue: String {
        token.isVerifiedValue ? "Yes" : "No"
    }

    var contractAddress: String {
        token.contractAddress ?? ""
    }
}

// MARK: - Action

extension TokenDetailViewModel {
    func sendAction() {
        LocalUserDefaults.shared.recentToken = token.vaultIdentifier
        Router.route(to: RouteMap.Wallet.send())
    }

    func receiveAction() {
        Router.route(to: RouteMap.Wallet.receiveQR)
    }

    func changeSelectRangeTypeAction(_ type: TokenDetailView.ChartRangeType) {
        if selectedRangeType == type {
            return
        }

        selectedRangeType = type
        fetchChartData()
    }

    func changeMarketAction(_ market: QuoteMarket) {
        if self.market == market {
            return
        }

        LocalUserDefaults.shared.market = market
    }

    func moreTransfersAction() {
        Router.route(to: RouteMap.Wallet.transactionList(token.contractId))
    }

    func transferDetailAction(_ model: FlowScanTransfer) {
        if let txid = model.txid {
            let network = currentNetwork
            let accountType = AccountType.current
            let url = network.getTransactionHistoryUrl(
                accountType: accountType,
                transactionId: txid
            )

            url.map { UIApplication.shared.open($0) }
        }
    }

    func stakeDetailAction() {
        StakingManager.shared.goStakingAction()
    }

    // move token
    func onMoveToken() {
        buttonAction = .move
        showSheetAction()
    }

    func onSwapToken() {
        Router.route(to: RouteMap.Wallet.swapProvider(token))
    }

    func showSheetAction() {
        if showSheet {
            showSheet = false
        }
        withAnimation(.easeOut(duration: 0.2)) {
            showSheet = true
        }
    }

    func deleteCustomToken() {
        guard let customToken = token.findCustomToken() else {
            return
        }
        WalletManager.shared.customTokenManager.delete(token: customToken)
    }

    func onClickAddress() {
        guard let url = token.aboutTokenUrl() else {
            return
        }
        Router.route(to: RouteMap.Explore.browser(url))
    }

    func onClickUnverifiedToken() {
        let urlStr = "https://wallet.flow.com/post/verified-tokens-on-flow-wallet"
        guard let url = URL(string: urlStr) else {
            return
        }
        Router.route(to: RouteMap.Explore.browser(url))
    }
}

// MARK: - Fetch & Refresh

extension TokenDetailViewModel {
    private func fetchAllData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
//                group.addTask {
//                    try? await WalletManager.shared.fetchBalance()
//                }

                group.addTask {
                    let accountInfo = try? await FlowNetwork.checkAccountInfo()
                    if let accountInfo {
                        await MainActor.run {
                            self.storageFlow = accountInfo.storageFlow.doubleValue
                            self.totalBalance = accountInfo.balance.doubleValue
                            self.storageUsedRatio = accountInfo.storageUsedRatio
                            self.storageUsedDesc = accountInfo.storageUsedString
                        }
                    }
                }

                await group.waitForAll()
            }
        }

        if hasRateAndChartData {
            fetchChartData()
        }

        fetchTransactionsData()
    }

    private func refreshSummary() {
        balance = WalletManager.shared
            .getBalance(with: token).doubleValue
        rate = CoinRateCache.cache
            .getSummary(by: token.contractId)?
            .getLastRate() ?? 0
        balanceAsUSD = balance * rate
        changePercent = CoinRateCache.cache.getSummary(by: token.contractId)?
            .getChangePercentage() ?? 0
    }

    private func fetchChartData() {
        Task { [weak self] in
            guard let self = self else { return }
            let pair = token.getPricePair(market: market)
            if pair.isEmpty {
                return
            }

            let currentRangeType = selectedRangeType

            let request = CryptoHistoryRequest(
                provider: market.rawValue,
                pair: pair,
                after: currentRangeType.after,
                period: "\(currentRangeType.frequency.rawValue)"
            )

            do {
                let response: CryptoHistoryResponse = try await Network
                    .request(FRWAPI.Crypto.history(request))
                if currentRangeType != self.selectedRangeType {
                    // selectedRangeType is changed, this is an outdated response
                    return
                }

                await MainActor.run {
                    self.generateChartData(response: response)
                }
            } catch {
                HUD.error(title: "fetch_chart_data_failed".localized)
            }
        }
    }

    private func generateChartData(response: CryptoHistoryResponse) {
        let quotes = response.parseMarketQuoteData(rangeType: selectedRangeType)
        let linePoints = quotes.map { $0.generateChartPoint }
        let chartLineStyle = LineStyle(lineColour: ColourStyle(
            colours: [
                Color.LL.Primary.salmonPrimary.opacity(0.24),
                Color.LL.Primary.salmonPrimary.opacity(0),
            ],
            startPoint: .top,
            endPoint: .bottom
        ))

        let set = LineDataSet(dataPoints: linePoints, style: chartLineStyle)
        let chartStyle = LineChartStyle(
            infoBoxPlacement: .floating,
            infoBoxBorderColour: .LL.Primary.salmonPrimary,
            infoBoxBorderStyle: StrokeStyle(lineWidth: 1),
            markerType: .vertical(attachment: .point),
            yAxisLabelPosition: .trailing,
            yAxisLabelFont: .inter(size: 12, weight: .regular),
            yAxisLabelColour: Color.LL.Neutrals.neutrals8,
            yAxisNumberOfLabels: 4
        )
        let cd = LineChartData(dataSets: set, chartStyle: chartStyle)
        cd.legends = []

        chartData = cd
    }

    var transactionsCacheKey: String {
        "token_detail_transaction_cache_\(token.contractId)"
    }

    private func fetchTransactionsData() {
        Task { [weak self] in
            guard let self = self else { return }
            if let cachedTransactions = try? await PageCache.cache.get(
                forKey: self.transactionsCacheKey,
                type: [FlowScanTransfer].self
            ), !cachedTransactions.isEmpty {
                await MainActor.run {
                    self.recentTransfers = cachedTransactions
                }
            }

            do {
                let request = TokenTransfersRequest(
                    address: WalletManager.shared.getPrimaryWalletAddress() ?? "",
                    limit: 3,
                    after: "",
                    token: self.token.contractId
                )
                let response: TransfersResponse = try await Network
                    .request(FRWAPI.Account.tokenTransfers(request))

                let list = response.transactions ?? []
                PageCache.cache.set(value: list, forKey: self.transactionsCacheKey)

                await MainActor.run {
                    self.recentTransfers = list
                }
            } catch {
                debugPrint("TokenDetailViewModel -> fetchTransactionsData request failed: \(error)")
            }
        }
    }
}

extension TokenDetailViewModel {
    func refreshButtonState() {
        // Swap
        if (RemoteConfigManager.shared.config?.features.swap ?? false) == true {
            // don't show when current is Linked account
            if WalletManager.shared.selectedChildAccount != nil || ChildAccountManager.shared
                .selectedChildAccount != nil
            {
                showSwapButton = false
            } else {
                showSwapButton = true
            }
        } else {
            showSwapButton = false
        }

        // buy
        if RemoteConfigManager.shared.config?.features.onRamp ?? false == true,
           flow.chainID == .mainnet
        {
            if WalletManager.shared.selectedChildAccount != nil {
                showBuyButton = false
            } else {
                showBuyButton = token.isFlowCoin ? true : false
            }

        } else {
            showBuyButton = false
        }
        // delete custom token
        showDeleteToken = token.findCustomToken() != nil
    }
}
