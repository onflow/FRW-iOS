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
    var whiteListTokens: [TokenModel] = []
    var activetedTokens: [TokenModel] = []

    // MARK: Lifecycle

    static let AvailableFlowToken = "availableFlowToken"

    init(network: Flow.ChainID = currentNetwork) {
        self.network = network
    }

    // MARK: Internal

    var network: Flow.ChainID

    func getSupportTokens() async throws -> [TokenModel] {
        guard whiteListTokens.isEmpty else {
            return whiteListTokens
        }
        let coinInfo: SingleTokenResponse = try await Network
            .requestWithRawModel(GithubEndpoint.ftTokenList(network), needAuthToken: false)
        let models = coinInfo.tokens.map { $0.toTokenModel(type: .cadence, network: network) }
        whiteListTokens = models.filter { $0.getAddress()?.isEmpty == false }
        return whiteListTokens
    }

    func getActivatedTokens(address: any FWAddress, in _: TokenListMode = .whitelist) async throws -> [TokenModel] {
        guard let addr = address as? Flow.Address else {
            throw EVMError.addressError
        }
        guard activetedTokens.isEmpty else {
            return activetedTokens
        }
        var allTokens: [TokenModel] = whiteListTokens
        if allTokens.isEmpty {
            let list = try await getSupportTokens()
            allTokens.append(contentsOf: list)
        }
        let balance = try await FlowNetwork.fetchTokenBalance(address: addr)
        let availableFlowBalance = balance[CadenceTokenBalanceProvider.AvailableFlowToken]

        var result: [TokenModel] = []
        for key in balance.keys {
            if let value = balance[key] {
                if var model = allTokens.first(where: { $0.vaultIdentifier == key }) {
                    model.balance = Utilities.parseToBigUInt(
                        String(format: "%f", value),
                        decimals: model.decimal
                    ) ?? BigUInt(0)

                    model.avaibleBalance = Utilities.parseToBigUInt(
                        String(format: "%f", model.isFlowCoin ? (availableFlowBalance ?? value) : value),
                        decimals: model.decimal
                    ) ?? BigUInt(0)
                    result.append(model)
                }
            }
        }

        // Sort by balance
        activetedTokens = result.sorted { lhs, rhs in
            guard let lBal = lhs.balance, let rBal = rhs.balance else {
                return true
            }
            return lBal > rBal
        }

        return activetedTokens
    }

    func getFTBalance(address: FWAddress) async throws -> [TokenModel] {
        let list = try await getActivatedTokens(address: address)
        return list
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
