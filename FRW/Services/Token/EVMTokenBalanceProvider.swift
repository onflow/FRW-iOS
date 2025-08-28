//
//  EVMTokenBalanceProvider.swift
//  FRW
//
//  Created by Hao Fu on 22/2/2025.
//

import Flow
import Foundation
import Web3Core

@MainActor
class EVMTokenBalanceProvider: TokenBalanceProvider {
    var tokens: [TokenModel] = []
    private var isLoading = false

    // MARK: Lifecycle

    init(network: Flow.ChainID = currentNetwork) {
        self.network = network
        currency = CurrencyCache.cache.currentCurrency
    }

    // MARK: Internal

    var network: Flow.ChainID
    var currency: Currency

    func fetchUserTokens(address: any FWAddress) async throws -> [TokenModel] {
        // EMERGENCY FIX: Prevent concurrent calls that cause memory corruption
        guard !isLoading else {
            print("⚠️ EVMTokenBalanceProvider: Concurrent fetch prevented")
            return tokens // Return cached tokens to prevent crash
        }
        
        guard let addr = address as? EthereumAddress
        else {
            throw EVMError.addressError
        }
        
        isLoading = true
        defer { isLoading = false }
        
        currency = CurrencyCache.cache.currentCurrency
        let response: [EVMTokenResponse] = try await Network.request(FRWAPI.Token.evm(.init(address: addr.hexAddr, currency: currency.rawValue, network: network)))
        tokens = response.compactMap { $0.toTokenModel(type: .evm) }
        let customToken = await fetchCustomBalance()
        tokens.append(contentsOf: customToken)
        
        // THREAD-SAFE FIX: Pure Swift Decimal comparison without ObjC bridging
        let tokensCopy = tokens.map { $0 } // Create defensive copy
        tokens = tokensCopy.sorted { lhs, rhs in
            // Convert String to Decimal directly, avoiding NSNumberFormatter bridging
            guard let lBalString = lhs.balanceInUSD,
                  let rBalString = rhs.balanceInUSD,
                  let lBal = Decimal(string: lBalString),
                  let rBal = Decimal(string: rBalString) else {
                return false // Put invalid balances at end
            }
            return lBal > rBal
        }
        
        return tokens
    }

    func getFTBalance(address: FWAddress) async throws -> [TokenModel] {
        guard tokens.isEmpty || currency != CurrencyCache.cache.currentCurrency else {
            return tokens
        }
        return try await fetchUserTokens(address: address)
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

    func getAllNFTsUnderCollection(
        address: any FWAddress,
        collectionIdentifier: String,
        progressHandler: @escaping (Int, Int) -> Void
    ) async throws -> [NFTModel] {
        var nfts = [NFTModel]()
        var currentOffset: String? = "0"
        let nftsInCollection = try? await getNFTCollections(address: address).first { $0.id == collectionIdentifier }?.count

        while let offset = currentOffset {
            let response = try await getNFTCollectionDetail(
                address: address,
                collectionIdentifier: collectionIdentifier,
                offset: offset
            )
            currentOffset = response.offset

            let newNFTs = response.nfts?.map { NFTModel($0, in: response.collection) } ?? []
            nfts.append(contentsOf: newNFTs)

            if let nftsInCollection {
                progressHandler(nfts.count, nftsInCollection)
            }
        }
        return nfts
    }
}

// MARK: - fetch custom token

extension EVMTokenBalanceProvider {
    private func fetchCustomBalance() async -> [TokenModel] {
        let manager = CustomTokenManager()
        await manager.fetchAllEVMBalance()
        let list = manager.list.map { $0.toToken() }
        let filterList = Dictionary(grouping: list, by: { $0.contractId }).values.compactMap { $0.last }
        return filterList
    }
}
