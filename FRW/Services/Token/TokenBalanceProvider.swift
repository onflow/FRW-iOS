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
    var nftPageSize: Int { get }
    // cache
    var whiteListTokens: [TokenModel] { get }
    var activetedTokens: [TokenModel] { get }
    // get tokens
    func getSupportTokens() async throws -> [TokenModel]
    func getActivatedTokens(address: FWAddress, in mode: TokenListMode) async throws -> [TokenModel]
    // get balance > 0
    func getFTBalance(address: FWAddress) async throws -> [TokenModel]
    func getFTBalanceWithId(address: FWAddress, tokenId: String) async throws -> TokenModel?

    func getNFTCollections(address: FWAddress) async throws -> [NFTCollection]

    func getAllNFTsUnderCollection(
        address: FWAddress,
        collectionIdentifier: String,
        progressHandler: @escaping (_ current: Int, _ total: Int) -> Void
    ) async throws -> [NFTModel]

    func getNFTCollectionDetail(
        address: FWAddress,
        collectionIdentifier: String,
        offset: String
    ) async throws -> NFTListResponse
}

extension TokenBalanceProvider {
    var nftPageSize: Int { 50 }

    func getFTBalanceWithId(address: FWAddress, tokenId: String) async throws -> TokenModel? {
        let models = try await getFTBalance(address: address)
        return models.first { $0.id == tokenId }
    }

    func getNFTCollections(address: FWAddress) async throws -> [NFTCollection] {
        let list: [NFTCollection] = try await Network.request(
            FRWAPI.NFT.userCollection(
                address.hexAddr,
                address.type
            )
        )
        let sorted = list.sorted(by: { $0.count > $1.count })
        return sorted
    }

    func getNFTCollectionDetail(
        address: FWAddress,
        collectionIdentifier: String,
        offset: String
    ) async throws -> NFTListResponse {
        let request = NFTCollectionDetailListRequest(
            address: address.hexAddr,
            collectionIdentifier: collectionIdentifier,
            offset: offset,
            limit: nftPageSize
        )
        let response: NFTListResponse = try await Network.request(
            FRWAPI.NFT.collectionDetailList(
                request,
                address.type
            )
        )
        return response
    }
}
