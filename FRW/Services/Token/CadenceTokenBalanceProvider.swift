//
//  CadenceTokenBalanceProvider.swift
//  FRW
//
//  Created by Hao Fu on 22/2/2025.
//

import BigInt
import Flow
import Foundation
import Web3Core

class CadenceTokenBalanceProvider: TokenBalanceProvider {
    // MARK: Lifecycle

    init(network: Flow.ChainID = currentNetwork) {
        self.network = network
        currency = CurrencyCache.cache.currentCurrency
    }

    // MARK: Internal

    var tokens: [TokenModel] = []
    var network: Flow.ChainID
    var currency: Currency

    func fetchUserTokens(address: any FWAddress) async throws -> [TokenModel] {
        guard let addr = address as? Flow.Address else {
            throw WalletError.invaildAddress
        }
        currency = CurrencyCache.cache.currentCurrency
        let query = FRWAPI.TokenQuery(address: addr.hexAddr, currency: currency.rawValue, network: network)
        let response: TokenModelResponse = try await Network.request(FRWAPI.Token.cadence(query))
        let availableBalanceToUse = response.storage?.availableBalanceToUse
        var tokenList: [TokenModel] = response.result ?? []
        if let balance = availableBalanceToUse {
            tokenList = tokenList.map { token in
                var model = token
                if model.isFlowCoin {
                    model.availableBalanceToUse = balance
                }
                return model
            }
        }
        tokenList.sort { lhs, rhs in
            // THREAD-SAFE FIX: Pure Swift Decimal comparison without ObjC bridging
            guard let lBalString = lhs.balanceInUSD,
                  let rBalString = rhs.balanceInUSD,
                  let lBal = Decimal(string: lBalString),
                  let rBal = Decimal(string: rBalString) else {
                return false // Put invalid balances at end
            }
            return lBal > rBal
        }
        tokens = tokenList
        return tokenList
    }

    func getFTBalance(address: FWAddress) async throws -> [TokenModel] {
        guard tokens.isEmpty || currency != CurrencyCache.cache.currentCurrency else {
            return tokens
        }
        return try await fetchUserTokens(address: address)
    }

    func getAllNFTsUnderCollection(address: FWAddress, collectionIdentifier: String, progressHandler: @escaping (Int, Int) -> Void) async throws -> [NFTModel] {
        guard let collection = try await getNFTCollections(address: address).first(where: { $0.id == collectionIdentifier }) else {
            throw TokenBalanceProviderError.collectionNotFound
        }

        return try await withThrowingTaskGroup(of: [NFTModel].self) { group in
            var completedCount = 0
            group.addTask {
                let total = collection.count
                let pageCount = (total + self.nftPageSize - 1) / self.nftPageSize

                // Parallel requests for each page of this collection
                let nfts = try await withThrowingTaskGroup(of: NFTListResponse?.self) { subGroup in
                    for page in 0 ..< pageCount {
                        let offset = page * self.nftPageSize
                        subGroup.addTask {
                            do {
                                let response = try await self.getNFTCollectionDetail(
                                    address: address,
                                    collectionIdentifier: collection.id,
                                    offset: String(offset)
                                )
                                completedCount += response.nfts?.count ?? 0
                                progressHandler(completedCount, total)
                                return response
                            } catch {
                                log.error(error)
                                return nil
                            }
                        }
                    }

                    var collectionNFTs = [NFTModel]()
                    for try await subResult in subGroup {
                        if let nftModels = subResult?.nfts?.map({ nftResponse in
                            NFTModel(nftResponse, in: subResult?.collection)
                        }) {
                            collectionNFTs.append(contentsOf: nftModels)
                        }
                    }
                    return collectionNFTs
                }

                return nfts
            }

            // Aggregate results from all collections
            var finalResults = [NFTModel]()
            for try await result in group {
                finalResults.append(contentsOf: result)
            }
            return finalResults
        }
    }
}
