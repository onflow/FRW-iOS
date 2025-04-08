//
//  TokenBalanceHandler.swift
//  FRW
//
//  Created by Hao Fu on 22/2/2025.
//

import Flow
import Foundation
import Web3Core

class TokenBalanceHandler: ObservableObject {
    // MARK: Lifecycle

    private var cache: [String: TokenBalanceProvider] = [:]
    
    @Published
    public var flowBalance: [String: Decimal] = [:]
    
    @Published
    public var isLoadingFlowBalance: Bool = false
    
    public init() {}

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
    
    func getAvailableFlowBalance(address: String,
                                 network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
                                 forceReload: Bool = false) async throws -> Decimal? {
        
        if (flowBalance[address] != nil), !forceReload {
            return flowBalance[address]
        }
        
        guard let first = FWAddressDector.create(address: address) else {
            return nil
        }
        
        isLoadingFlowBalance = true
        defer { isLoadingFlowBalance = false }
        
        let provider = generateProvider(address: first, network: network)
        let dict = try await provider.getAvailableFlowBalance(addresses: [address])
        for (key, value) in dict {
            flowBalance[key] = value
        }
        return dict[address]
    }
    
    func getAvailableFlowBalance(addresses: [String],
                                 network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
                                 forceReload: Bool = false) async throws -> [String: Decimal] {
        
        if flowBalance.keys.contains(addresses), !forceReload {
            return Dictionary(uniqueKeysWithValues: zip(addresses, flowBalance.values))
        }
        
        guard let first = FWAddressDector.create(address: addresses.first) else {
            return [:]
        }
        
        isLoadingFlowBalance = true
        defer { isLoadingFlowBalance = false }
        
        let provider = generateProvider(address: first, network: network)
        let dict = try await provider.getAvailableFlowBalance(addresses: addresses)
        for (key, value) in dict {
            flowBalance[key] = value
        }
        return dict
    }

    func getSupportTokens(address: FWAddress,
                          network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
                          ignoreCache: Bool = true) async throws -> [TokenModel]
    {
        let provider = generateProvider(address: address, network: network)
        return try await provider.getSupportTokens()
    }

    /// `ignoreCache` it should be with the expiration of time or other,ensure the validity of the data
    func getActivatedTokens(address: FWAddress,
                            network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
                            ignoreCache: Bool = true) async throws -> [TokenModel]
    {
        let provider = generateProvider(address: address, network: network)
        return try await provider.getActivatedTokens(address: address, in: .whitelistAndCustom)
    }

    func getFTBalance(
        address: FWAddress,
        network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
        ignoreCache: Bool = true
    ) async throws -> [TokenModel] {
        let provider = generateProvider(address: address, network: network)
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
        let provider = generateProvider(address: address, network: network)
        return try await provider.getNFTCollections(address: address)
    }

    func getNFTCollectionDetail(
        address: FWAddress,
        network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork,
        collectionIdentifier: String,
        offset: String
    ) async throws -> NFTListResponse {
        let provider = generateProvider(address: address, network: network)
        return try await provider.getNFTCollectionDetail(
            address: address,
            collectionIdentifier: collectionIdentifier,
            offset: offset
        )
    }

    func getAllNFTsUnderCollection(address: FWAddress, collectionIdentifier: String, network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork, progressHandler: @escaping (Int, Int) -> Void) async throws -> [NFTModel] {
        guard try (await getNFTCollections(address: address).first(where: { $0.id == collectionIdentifier })) != nil else {
            throw TokenBalanceProviderError.collectionNotFound
        }
        let provider = generateProvider(address: address, network: network)
        return try await provider.getAllNFTsUnderCollection(
            address: address,
            collectionIdentifier: collectionIdentifier,
            progressHandler: progressHandler
        )
    }
}

// MARK: - Private

extension TokenBalanceHandler {
    private func generateProvider(
        address: FWAddress,
        network: FlowNetworkType,
        ignoreCache: Bool = false
    ) -> TokenBalanceProvider {
        if ignoreCache {
            cache[address.cacheKey] = nil
        }
        if let provider = cache[address.cacheKey] {
            return provider
        }
        let provider: TokenBalanceProvider
        switch address.type {
        case .cadence:
            provider = CadenceTokenBalanceProvider(network: network)
        case .evm:
            provider = EVMTokenBalanceProvider(network: network)
        }
        cache[address.cacheKey] = provider
        return provider
    }
}

