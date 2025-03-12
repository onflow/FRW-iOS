//
//  TokenBalanceHandler.swift
//  FRW
//
//  Created by Hao Fu on 22/2/2025.
//

import Flow
import Foundation
import Web3Core

class TokenBalanceHandler {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    // Default Flow token metadata from token list
    // https://github.com/Outblock/token-list-jsons/blob/outblock/jsons/mainnet/flow/default.json#L6-L35
    static let flowTokenJsonStr =
        """
        {
          "chainId": 747,
          "address": "0x<FlowTokenAddress>",
          "contractName": "",
          "path": {
            "vault": "/storage/flowTokenVault",
            "receiver": "/public/flowTokenReceiver",
            "balance": "/public/flowTokenBalance"
          },
          "symbol": "FLOW",
          "name": "Flow",
          "description": "",
          "decimals": 18,
          "flowIdentifier": "A.<FlowTokenAddress>.FlowToken",
          "logoURI": "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.1654653399040a61.FlowToken/logo.svg",
          "tags": [
            "Verified",
            "Featured",
            "utility-token"
          ],
          "extensions": {
            "coingeckoId": "flow",
            "discord": "http://discord.gg/flow",
            "documentation": "https://developers.flow.com/references/core-contracts/flow-token",
            "github": "https://github.com/onflow/flow-core-contracts",
            "twitter": "https://twitter.com/flow_blockchain",
            "website": "https://flow.com/",
            "displaySource": "0xa2de93114bae3e73",
            "pathSource": "0xa2de93114bae3e73"
          }
        }
        """

    static let shared = TokenBalanceHandler()

    static func flowTokenAddress(network: FlowNetworkType) -> String {
        switch network {
        case .mainnet:
            return "0x1654653399040a61"
        case .testnet:
            return "0x7e60df042a9c0868"
        }
    }

    static func getFlowTokenModel(network: FlowNetworkType) -> SingleToken? {
        let address = flowTokenAddress(network: network).stripHexPrefix()
        guard let data = flowTokenJsonStr
            .replacingOccurrences(of: "<FlowTokenAddress>", with: address)
            .data(using: .utf8)
        else {
            return nil
        }
        return try? FRWAPI.jsonDecoder.decode(SingleToken.self, from: data)
    }

    func getSupportTokens(address: FWAddress,
                          network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork) async throws -> [TokenModel]
    {
        let provider = try generateProvider(address: address, network: network)
        return try await provider.getSupportTokens()
    }

    func getActivatedTokens(address: FWAddress,
                            tokens: [TokenModel]?,
                            network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork) async throws -> [TokenModel]
    {
        let provider = try generateProvider(address: address, network: network)
        return try await provider.getActivatedTokens(address: address, in: tokens)
    }

    func getFTBalance(
        address: FWAddress,
        network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork
    ) async throws -> [TokenModel] {
        let provider = try generateProvider(address: address, network: network)
        return try await provider.getFTBalance(address: address)
    }

    func getFTBalanceWithId(
        address: FWAddress,
        network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
        tokenId: String
    ) async throws -> TokenModel? {
        let models = try await getFTBalance(address: address, network: network)
        return models.first { $0.id == tokenId }
    }

    func getNFTCollections(
        address: FWAddress,
        network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork
    ) async throws -> [NFTCollection] {
        let provider = try generateProvider(address: address, network: network)
        return try await provider.getNFTCollections(address: address)
    }

    func getNFTCollectionDetail(
        address: FWAddress,
        network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
        collectionIdentifier: String,
        offset: Int
    ) async throws -> NFTListResponse {
        let provider = try generateProvider(address: address, network: network)
        return try await provider.getNFTCollectionDetail(
            address: address,
            collectionIdentifier: collectionIdentifier,
            offset: offset
        )
    }

    // MARK: Private

    private func generateProvider(
        address: FWAddress,
        network: FlowNetworkType
    ) throws -> TokenBalanceProvider {
        switch address.type {
        case .cadence:
            return CadenceTokenBalanceProvider(network: network)
        case .evm:
            return EVMTokenBalanceProvider(network: network)
        }
    }
}
