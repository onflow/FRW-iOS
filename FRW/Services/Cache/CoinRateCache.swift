//
//  CoinRateCache.swift
//  Flow Wallet
//
//  Created by Selina on 23/6/2022.
//

import Combine
import Haneke
import SwiftUI

extension CoinRateCache {
    struct CoinRateModel: Codable, Hashable {
        static func == (lhs: CoinRateCache.CoinRateModel, rhs: CoinRateCache.CoinRateModel) -> Bool {
            return lhs.symbol == rhs.symbol
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(symbol)
        }

        let updateTime: TimeInterval
        let symbol: String
        let summary: CryptoSummaryResponse
    }
}

private let CacheUpdateInverval = TimeInterval(30)

class CoinRateCache {
    static let cache = CoinRateCache()

    private var queue = DispatchQueue(label: "CoinRateCache.cache")
    private var addPrices: [CryptoSummaryResponse.AddPrice] = []
    private var _summarys = Set<CoinRateModel>()
    var summarys: Set<CoinRateModel> {
        queue.sync {
            _summarys
        }
    }

    private var isRefreshing = false

    private var cancelSets = Set<AnyCancellable>()

    init() {
        loadFromCache()

        NotificationCenter.default.publisher(for: .quoteMarketUpdated).sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refresh()
            }
        }.store(in: &cancelSets)

        WalletManager.shared.$activatedCoins.sink { _ in
            DispatchQueue.main.async {
                self.refresh()
            }
        }.store(in: &cancelSets)

        NotificationCenter.default.publisher(for: .willResetWallet)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.willReset()
            }.store(in: &cancelSets)
    }

    @objc private func willReset() {
        queue.sync {
            _summarys.removeAll()
        }
        saveToCache()
    }

    func getSummary(for symbol: String) -> CryptoSummaryResponse? {
        return summarys.first { $0.symbol == symbol }?.summary
    }
}

extension CoinRateCache {
    private func loadFromCache() {
        queue.sync {
            if let cacheList = LocalUserDefaults.shared.coinSummarys {
                _summarys = Set(cacheList)
            } else {
                _summarys.removeAll()
            }
        }
    }

    private func saveToCache() {
        LocalUserDefaults.shared.coinSummarys = Array(summarys)
    }

    private func refresh() {
        if isRefreshing {
            return
        }

        guard let supportedCoins = WalletManager.shared.supportedCoins else {
            return
        }
        var evmCoins = WalletManager.shared.evmSupportedCoins

        

        log.debug("CoinRateCache -> start refreshing")
        isRefreshing = true
        Task {
            do {
                addPrices = try await Network.request(FRWAPI.Crypto.prices)
            } catch {
                log.error("[Wallet] CoinRateCache -> fetch add price", context: error)
            }
            // flow token
            if EVMAccountManager.shared.selectedAccount == nil {
                await withTaskGroup(of: Void.self) { group in
                    supportedCoins.forEach { coin in
                        group.addTask { [weak self] in
                            do {
                                try await self?.fetchCoinRate(coin)
                            } catch {
                                debugPrint("CoinRateCache -> fetchCoinRate:\(coin.symbol ?? "") failed: \(error)")
                            }
                        }
                    }
                    
                }
            }
            // evm token
            if EVMAccountManager.shared.selectedAccount != nil {
                await withTaskGroup(of: Void.self) { group in
                    
                    supportedCoins.forEach { coin in
                        if coin.isFlowCoin {
                            group.addTask { [weak self] in
                                do {
                                    try await self?.fetchCoinRate(coin)
                                } catch {
                                    debugPrint("CoinRateCache -> fetchCoinRate:\(coin.symbol ?? "") failed: \(error)")
                                }
                            }
                        }
                    }
                    
                    evmCoins?.forEach { coin in
                        group.addTask { [weak self] in
                            do {
                                try await self?.fetchCoinRate(coin)
                            } catch {
                                log.debug("CoinRateCache -> fetchCoinRate:\(coin.symbol ?? "") failed: \(error)")
                            }
                        }
                    }
                }
            }
            

            isRefreshing = false
            log.debug("CoinRateCache -> end refreshing")
        }
    }

    private func fetchCoinRate(_ coin: TokenModel) async throws {
        guard let symbol = coin.symbol else {
            return
        }

        if let old = summarys.first(where: { $0.symbol == symbol }) {
            let interval = abs(old.updateTime - Date().timeIntervalSince1970)
            if interval < CacheUpdateInverval {
                // still valid
                return
            }
        }

        guard let listedToken = coin.listedToken else {
            return
        }

        switch listedToken.priceAction {
        case let .query(coinPair):
            let market = LocalUserDefaults.shared.market
            let request = CryptoSummaryRequest(provider: market.rawValue, pair: coinPair)
            let response: CryptoSummaryResponse = try await Network.request(FRWAPI.Crypto.summary(request))
            await set(summary: response, forSymbol: symbol)
        case let .mirror(token):
            guard let mirrorTokenModel = WalletManager.shared.supportedCoins?.first(where: { $0.symbol == token.rawValue }) else {
                break
            }

            try await fetchCoinRate(mirrorTokenModel)

            guard let mirrorResponse = getSummary(for: token.rawValue) else {
                break
            }

            await set(summary: mirrorResponse, forSymbol: symbol)
        case let .fixed(price):
            let response = createFixedRateResponse(fixedRate: price, for: coin)
            await set(summary: response, forSymbol: symbol)
        }
    }

    private func createFixedRateResponse(fixedRate: Decimal, for token: TokenModel) -> CryptoSummaryResponse {
        var model: CryptoSummaryResponse.AddPrice?

        if EVMAccountManager.shared.selectedAccount != nil {
            model = addPrices.first { $0.evmAddress?.lowercased() == token.getAddress()?.lowercased() }
        } else {
            model = addPrices.first { $0.contractName.uppercased() == token.contractName.uppercased() }
        }

        let change = CryptoSummaryResponse.Change(absolute: 0, percentage: 0)
        let price = CryptoSummaryResponse.Price(last: model?.rateToUSD ?? fixedRate.doubleValue,
                                                low: fixedRate.doubleValue,
                                                high: fixedRate.doubleValue,
                                                change: change)
        let result = CryptoSummaryResponse.Result(price: price)
        return CryptoSummaryResponse(result: result)
    }

    @MainActor
    private func set(summary: CryptoSummaryResponse, forSymbol: String) {
        let model = CoinRateModel(updateTime: Date().timeIntervalSince1970, symbol: forSymbol, summary: summary)
        _ = queue.sync {
            _summarys.update(with: model)
        }
        saveToCache()
        NotificationCenter.default.post(name: .coinSummarysUpdated, object: nil)
    }
}
