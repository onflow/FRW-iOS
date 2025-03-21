//
//  CoinRateCache.swift
//  Flow Wallet
//
//  Created by Selina on 23/6/2022.
//

import Combine
import Haneke
import SwiftUI

// MARK: - CoinRateCache.CoinRateModel

extension CoinRateCache {
    struct CoinRateModel: Codable, Hashable {
        let updateTime: TimeInterval
        let contractId: String
        let summary: CryptoSummaryResponse

        static func == (
            lhs: CoinRateCache.CoinRateModel,
            rhs: CoinRateCache.CoinRateModel
        ) -> Bool {
            lhs.contractId == rhs.contractId
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(contractId)
        }
    }
}

private let CacheUpdateInverval = TimeInterval(30)

// MARK: - CoinRateCache

class CoinRateCache {
    // MARK: Lifecycle

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

    // MARK: Internal

    static let cache = CoinRateCache()

    var summarys: Set<CoinRateModel> {
        queue.sync {
            _summarys
        }
    }

    func getSummary(by contractId: String) -> CryptoSummaryResponse? {
        guard !contractId.isEmpty else {
            return nil
        }
        return summarys.first { $0.contractId == contractId }?.summary
    }

    // MARK: Private

    private var queue = DispatchQueue(label: "CoinRateCache.cache")
    private var addPrices: [CryptoSummaryResponse.AddPrice] = []
    private var _summarys = Set<CoinRateModel>()
    private var isRefreshing = false

    private var cancelSets = Set<AnyCancellable>()

    @objc
    private func willReset() {
        queue.sync {
            _summarys.removeAll()
        }
        saveToCache()
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

        let supportedCoins = WalletManager.shared.activatedCoins

        log.debug("CoinRateCache -> start refreshing")
        isRefreshing = true
        Task {
            do {
                addPrices = try await Network.request(FRWAPI.Crypto.prices)
            } catch {
                log.error("[Wallet] CoinRateCache -> fetch add price", context: error)
            }
            await withTaskGroup(of: Void.self) { group in
                for coin in supportedCoins {
                    group.addTask { [weak self] in
                        do {
                            try await self?.fetchCoinRate(coin)
                        } catch {
                            log.debug(
                                "CoinRateCache -> fetchCoinRate:\(coin.contractId) failed: \(error)"
                            )
                        }
                    }
                }
            }

            isRefreshing = false
            log.debug("CoinRateCache -> end refreshing")
        }
    }

    private func fetchCoinRate(_ coin: TokenModel) async throws {
        let contractId = coin.contractId
        if let old = summarys.first(where: { $0.contractId == contractId }) {
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
            let response: CryptoSummaryResponse = try await Network
                .request(FRWAPI.Crypto.summary(request))
            await set(summary: response, forContractId: contractId)
        case let .mirror(token):
            guard let mirrorTokenModel = WalletManager.shared.supportedCoins?
                .first(where: { $0.symbol == token.rawValue })
            else {
                break
            }

            try await fetchCoinRate(mirrorTokenModel)

            guard let mirrorResponse = getSummary(by: contractId) else {
                break
            }

            await set(summary: mirrorResponse, forContractId: contractId)
        case let .fixed(price):
            let response = createFixedRateResponse(fixedRate: price, for: coin)
            await set(summary: response, forContractId: contractId)
        }
    }

    private func createFixedRateResponse(
        fixedRate: Decimal,
        for token: TokenModel
    ) -> CryptoSummaryResponse {
        var model: CryptoSummaryResponse.AddPrice?

        if EVMAccountManager.shared.selectedAccount != nil {
            model = addPrices
                .first { $0.evmAddress?.lowercased() == token.getAddress()?.lowercased() }
        } else {
            model = addPrices
                .first { $0.contractName.uppercased() == token.contractName.uppercased() }
        }

        let change = CryptoSummaryResponse.Change(absolute: 0, percentage: 0)
        let price = CryptoSummaryResponse.Price(
            last: model?.rateToUSD ?? fixedRate.doubleValue,
            low: fixedRate.doubleValue,
            high: fixedRate.doubleValue,
            change: change
        )
        let result = CryptoSummaryResponse.Result(price: price)
        return CryptoSummaryResponse(result: result)
    }

    @MainActor
    private func set(summary: CryptoSummaryResponse, forContractId: String) {
        let model = CoinRateModel(
            updateTime: Date().timeIntervalSince1970,
            contractId: forContractId,
            summary: summary
        )
        _ = queue.sync {
            _summarys.update(with: model)
        }
        saveToCache()
        NotificationCenter.default.post(name: .coinSummarysUpdated, object: nil)
    }
}
