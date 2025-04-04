//
//  EVMTokenBalanceProvider.swift
//  FRW
//
//  Created by Hao Fu on 22/2/2025.
//

import Foundation
import Web3Core

class EVMTokenBalanceProvider: TokenBalanceProvider {
    var whiteListTokens: [TokenModel] = []
    var activetedTokens: [TokenModel] = []

    // MARK: Lifecycle

    init(network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork) {
        self.network = network
    }

    // MARK: Internal

    var network: FlowNetworkType

    func getSupportTokens() async throws -> [TokenModel] {
        guard whiteListTokens.isEmpty else {
            return whiteListTokens
        }
        let tokenResponse: SingleTokenResponse = try await Network
            .requestWithRawModel(GithubEndpoint.EVMTokenList(network))
        var tokens: [TokenModel] = tokenResponse.conversion(type: .evm)
        if let flowToken = TokenBalanceHandler.getFlowTokenModel(network: network) {
            let flowModel = flowToken.toTokenModel(type: .evm, network: network)
            tokens.insert(flowModel, at: 0)
        }
        whiteListTokens = tokens
        return whiteListTokens
    }

    func getActivatedTokens(address: any FWAddress, in _: TokenListMode = .whitelistAndCustom) async throws -> [TokenModel] {
        guard let addr = address as? EthereumAddress,
              let web3 = try await FlowProvider.Web3.default(networkType: network)
        else {
            throw EVMError.rpcError
        }
        guard activetedTokens.isEmpty else {
            return activetedTokens
        }
        // fetch all tokens
        var allTokens: [TokenModel] = whiteListTokens
        if allTokens.isEmpty {
            let list = try await getSupportTokens()
            allTokens.append(contentsOf: list)
        }
        // add `flow` token
        let flowBalance = try await web3.eth.getBalance(for: addr)

        // The SimpleHash API doesn't return token metadata like logo and flowIdentifier
        // Hence, we need fetch the metadata from token list first
        let response: [EVMTokenResponse] = try await Network
            .request(FRWAPI.EVM.tokenList(address.hexAddr))
        var models = response.map { $0.toTokenModel(type: .evm) }

        if let flowToken = TokenBalanceHandler.getFlowTokenModel(network: network) {
            var flowModel = flowToken.toTokenModel(type: .evm, network: network)
            flowModel.balance = flowBalance
            flowModel.avaibleBalance = flowBalance
            models.insert(flowModel, at: 0)
        }

        let updateModels: [TokenModel] = models.compactMap { model in

            if let metadata = allTokens.first(where: { token in
                token.address.addressByNetwork(network.toFlowType())?.lowercased() == model.address.addressByNetwork(network.toFlowType())?.lowercased()
            }) {
                var newModel = model
                newModel.icon = metadata.iconURL
                newModel.flowIdentifier = metadata.flowIdentifier
                return newModel
            }
            return nil
        }
        let customToken = await fetchCustomBalance()
        activetedTokens.append(contentsOf: customToken)
        // Sort by balance
        activetedTokens = updateModels.sorted { lhs, rhs in
            guard let lBal = lhs.readableBalance, let rBal = rhs.readableBalance else {
                return true
            }
            return lBal > rBal
        }
        return activetedTokens
    }

    func getFTBalance(address: FWAddress) async throws -> [TokenModel] {
        let list = try await getActivatedTokens(address: address)
        return list
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
