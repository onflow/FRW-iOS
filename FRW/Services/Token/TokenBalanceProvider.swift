//
//  TokenBalanceProvider.swift
//  FRW
//
//  Created by Hao Fu on 25/2/2025.
//

import Flow
import Foundation

// MARK: - TokenBalanceProvider

protocol TokenBalanceProvider {
    var network: Flow.ChainID { get }
    var currency: Currency { get }
    var nftPageSize: Int { get }
    // cache
    var tokens: [TokenModel] { get }
    func fetchUserTokens(address: FWAddress) async throws -> [TokenModel]

    // TODO: Move this to `TokenBalanceHandler`
    func getAvailableFlowBalance(addresses: [String]) async throws -> [String: Decimal]

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

    func getAvailableFlowBalance(addresses: [String]) async throws -> [String: Decimal] {
        let result = try await FlowNetwork.getFlowBalanceForAnyAccount(addresses: addresses)
        return result
    }

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
