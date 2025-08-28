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

    // ADD: Thread-safe queue for cache access
    private let cacheQueue = DispatchQueue(label: "com.outblock.frw.tokenbalance.cache", attributes: .concurrent)
    private var cache: [String: TokenBalanceProvider] = [:]

    @Published
    public var flowBalance: [String: Decimal] = [:]

    @Published
    public var isLoadingFlowBalance: Bool = false

    public init() {}

    // MARK: Internal

    static let shared = TokenBalanceHandler()

    func getAvailableFlowBalance(address: String,
                                 network: Flow.ChainID = currentNetwork,
                                 forceReload: Bool = false) async throws -> Decimal?
    {
        if flowBalance[address] != nil, !forceReload {
            return flowBalance[address]
        }

        guard let first = FWAddressDector.create(address: address) else {
            return nil
        }

        isLoadingFlowBalance = true
        defer { isLoadingFlowBalance = false }

      let provider = await generateProvider(address: first, network: network)
        let dict = try await provider.getAvailableFlowBalance(addresses: [address])
        for (key, value) in dict {
            flowBalance[key] = value
        }
        return dict[address]
    }

    func getAvailableFlowBalance(addresses: [String],
                                 network: Flow.ChainID = currentNetwork,
                                 forceReload: Bool = false) async throws -> [String: Decimal]
    {
        if flowBalance.keys.contains(addresses), !forceReload {
            return Dictionary(uniqueKeysWithValues: zip(addresses, flowBalance.values))
        }

        guard let first = FWAddressDector.create(address: addresses.first) else {
            return [:]
        }

        isLoadingFlowBalance = true
        defer { isLoadingFlowBalance = false }

      let provider = await generateProvider(address: first, network: network)
        let dict = try await provider.getAvailableFlowBalance(addresses: addresses)
        for (key, value) in dict {
            flowBalance[key] = value
        }
        return dict
    }

    func fetchUserTokens(address: FWAddress, network: Flow.ChainID = currentNetwork, ignoreCache _: Bool = true) async throws -> [TokenModel] {
      let provider = await generateProvider(address: address, network: network)
        return try await provider.fetchUserTokens(address: address)
    }

    func getFTBalance(
        address: FWAddress,
        network: Flow.ChainID = currentNetwork,
        ignoreCache _: Bool = true
    ) async throws -> [TokenModel] {
      let provider = await generateProvider(address: address, network: network)
        return try await provider.getFTBalance(address: address)
    }

    func getFTBalanceWithId(
        address: FWAddress,
        network: Flow.ChainID = currentNetwork,
        tokenId: String
    ) async throws -> TokenModel? {
        let models = try await getFTBalance(address: address, network: network)
        return models.first { $0.id == tokenId }
    }

    func getNFTCollections(
        address: FWAddress,
        network: Flow.ChainID = currentNetwork
    ) async throws -> [NFTCollection] {
      let provider = await generateProvider(address: address, network: network)
        return try await provider.getNFTCollections(address: address)
    }

    func getNFTCollectionDetail(
        address: FWAddress,
        network: Flow.ChainID = currentNetwork,
        collectionIdentifier: String,
        offset: String
    ) async throws -> NFTListResponse {
      let provider = await generateProvider(address: address, network: network)
        return try await provider.getNFTCollectionDetail(
            address: address,
            collectionIdentifier: collectionIdentifier,
            offset: offset
        )
    }

    func getAllNFTsUnderCollection(
        address: FWAddress,
        collectionIdentifier: String,
        network: Flow.ChainID = currentNetwork,
        progressHandler: @escaping (Int, Int) -> Void
    ) async throws -> [NFTModel] {
      let provider = await generateProvider(address: address, network: network)
        return try await provider.getAllNFTsUnderCollection(
            address: address,
            collectionIdentifier: collectionIdentifier,
            progressHandler: progressHandler
        )
    }
}

// MARK: - Private

extension TokenBalanceHandler {
  @MainActor private func generateProvider(
        address: FWAddress,
        network: Flow.ChainID,
        ignoreCache: Bool = false
    ) -> TokenBalanceProvider {
        if ignoreCache {
            cacheQueue.async(flags: .barrier) {
                self.cache[address.cacheKey] = nil
            }
        }

        // Read access to cache
        var provider: TokenBalanceProvider?
        cacheQueue.sync {
            provider = cache[address.cacheKey]
        }

        if let existingProvider = provider {
            return existingProvider
        }

        let newProvider: TokenBalanceProvider
        switch address.type {
        case .cadence:
            newProvider = CadenceTokenBalanceProvider(network: network)
        case .evm:
            newProvider = EVMTokenBalanceProvider(network: network)
        }

        // Write access to cache
        cacheQueue.async(flags: .barrier) {
            self.cache[address.cacheKey] = newProvider
        }

        return newProvider
    }
}
