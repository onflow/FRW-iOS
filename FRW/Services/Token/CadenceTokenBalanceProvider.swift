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

    static let AvailableFlowToken = "availableFlowToken"

    init(network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork) {
        self.network = network

        // TODO: Add token list cache
    }

    // MARK: Internal

    var network: FlowNetworkType

    func getSupportTokens() async throws -> [TokenModel] {
        let coinInfo: SingleTokenResponse = try await Network
            .requestWithRawModel(GithubEndpoint.ftTokenList(network))
        let models = coinInfo.tokens.map { $0.toTokenModel(type: .cadence, network: network) }
        let result = models.filter { $0.getAddress()?.isEmpty == false }
        return result
    }

    func getActivatedTokens(address: any FWAddress, in list: [TokenModel]?) async throws -> [TokenModel] {
        guard let addr = address as? Flow.Address else {
            throw EVMError.addressError
        }
        var allTokens: [TokenModel] = list ?? []
        if allTokens.isEmpty {
            let list = try await getSupportTokens()
            allTokens.append(contentsOf: list)
        }
        let balance = try await FlowNetwork.fetchTokenBalance(address: addr)
        let availableFlowBalance = balance[CadenceTokenBalanceProvider.AvailableFlowToken]

        var activeModels: [TokenModel] = []
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
        return activeModels
    }

    func getFTBalance(address: FWAddress) async throws -> [TokenModel] {
        let list = try await getActivatedTokens(address: address, in: nil)
        let sorted = list.filter { model in
            guard let balance = model.balance else {
                return false
            }
            return balance > 0
        }
        return sorted
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
        offset: Int
    ) async throws -> NFTListResponse {
        let request = NFTCollectionDetailListRequest(
            address: address.hexAddr,
            collectionIdentifier: collectionIdentifier,
            offset: offset,
            limit: EVMTokenBalanceProvider.nftLimit
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
