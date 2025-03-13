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
    func getAllNFTs(address: FWAddress) async throws -> [NFTModel]
    func getNFTCollectionDetail(
        address: FWAddress,
        collectionIdentifier: String,
        offset: Int
    ) async throws -> NFTListResponse
}

// MARK: - Default implementations

extension TokenBalanceProvider {
    static var nftLimit: Int { 50 }
}

extension TokenBalanceProvider {
    func getFTBalanceWithId(address: FWAddress, tokenId: String) async throws -> TokenModel? {
        let models = try await getFTBalance(address: address)
        return models.first { $0.id == tokenId }
    }
}

extension TokenBalanceProvider {
    func getAllNFTs(address: FWAddress) async throws -> [NFTModel] {
        let collections = try await getNFTCollections(address: address)

        return try await withThrowingTaskGroup(of: [NFTModel].self) { group in
            for collection in collections {
                group.addTask {
                    let total = collection.count
                    let pageCount = (total + Self.nftLimit - 1) / Self.nftLimit

                    // Parallel requests for each page of this collection
                    let nfts = try await withThrowingTaskGroup(of: NFTListResponse?.self) { subGroup in
                        for page in 0..<pageCount {
                            let offset = page * Self.nftLimit
                            subGroup.addTask {
                                do {
                                    let response = try await self.getNFTCollectionDetail(
                                        address: address,
                                        collectionIdentifier: collection.id,
                                        offset: offset
                                    )
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
