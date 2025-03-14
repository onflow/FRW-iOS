//
//  EVMTokenBalanceHandler.swift
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

    init(network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork) {
        self.network = network

        // TODO: Add token list cache
    }

    // MARK: Internal

    var network: FlowNetworkType

    func getFTBalance(address: FWAddress) async throws -> [TokenModel] {
        guard let addr = address as? Flow.Address else {
            throw EVMError.addressError
        }

        let coinInfo: SingleTokenResponse = try await Network
            .requestWithRawModel(GithubEndpoint.ftTokenList(network))
        let models = coinInfo.tokens.map { $0.toTokenModel(type: .cadence, network: network) }
        let balance = try await FlowNetwork.fetchBalance(at: addr)

        var activeModels: [TokenModel] = []
        balance.keys.forEach { key in
            if let value = balance[key], value > 0 {
                if var model = models.first(where: { $0.contractId == key }) {
                    model.balance = Utilities.parseToBigUInt(
                        String(format: "%f", balance[key] ?? 0),
                        decimals: model.decimal
                    ) ?? BigUInt(0)
                    activeModels.append(model)
                }
            }
        }

        // Sort by balance
        let sorted = activeModels.sorted { lhs, rhs in
            guard let lBal = lhs.balance, let rBal = rhs.balance else {
                return true
            }
            return lBal > rBal
        }

        return sorted
    }
    
    func getAllNFTsUnderCollection(address: FWAddress, collectionIdentifier: String, progressHandler: @escaping (Int, Int) -> ()) async throws -> [NFTModel] {
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
                    for page in 0..<pageCount {
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
