//
//  TokenBalanceProvider.swift
//  FRW
//
//  Created by Hao Fu on 25/2/2025.
//

import Foundation

// MARK: - TokenBalanceProvider

protocol TokenBalanceProvider {
    var network: FlowNetworkType { get }
    func getFTBalance(address: FWAddress) async throws -> [TokenModel]
    func getFTBalanceWithId(address: FWAddress, tokenId: String) async throws -> TokenModel?
    func getNFTCollections(address: FWAddress) async throws -> [NFTCollection]
    func getAllNFTs(
        address: FWAddress,
        collectionIdentifier: String,
        progressHandler: @escaping (Double) -> ()
    ) async throws -> [NFTModel]
    func getNFTCollectionDetail(
        address: FWAddress,
        collectionIdentifier: String,
        offset: Int
    ) async throws -> NFTListResponse
}

// MARK: - Default implementations

extension TokenBalanceProvider {
    func getFTBalanceWithId(address: FWAddress, tokenId: String) async throws -> TokenModel? {
        let models = try await getFTBalance(address: address)
        return models.first { $0.id == tokenId }
    }
}

extension TokenBalanceProvider {
    func getAllNFTs(address: FWAddress, collectionIdentifier: String, progressHandler: @escaping (Double) -> ()) async throws -> [NFTModel] {
        guard let collection = try await getNFTCollections(address: address).first(where: { $0.id == collectionIdentifier }) else {
            throw TokenBalanceProviderError.collectionNotFound
        }
        
        return try await withThrowingTaskGroup(of: [NFTModel].self) { group in
            var completedCount = 0
            group.addTask {
                let total = collection.count
                let pageCount = (total + EVMTokenBalanceProvider.nftLimit - 1) / EVMTokenBalanceProvider.nftLimit
                
                // Parallel requests for each page of this collection
                let nfts = try await withThrowingTaskGroup(of: NFTListResponse?.self) { subGroup in
                    for page in 0..<pageCount {
                        let offset = page * EVMTokenBalanceProvider.nftLimit
                        subGroup.addTask {
                            do {
                                let response = try await self.getNFTCollectionDetail(
                                    address: address,
                                    collectionIdentifier: collection.id,
                                    offset: offset
                                )
                                completedCount += 1
                                progressHandler(Double(completedCount) / Double(pageCount))
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

// MARK: - Errors

enum TokenBalanceProviderError: Error {
    case collectionNotFound
}
