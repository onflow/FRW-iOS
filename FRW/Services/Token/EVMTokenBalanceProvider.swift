//
//  EVMTokenBalanceHandler.swift
//  FRW
//
//  Created by Hao Fu on 22/2/2025.
//

import Foundation
import Web3Core

class EVMTokenBalanceProvider: TokenBalanceProvider {
    // MARK: Lifecycle

    init(network: FlowNetworkType = LocalUserDefaults.shared.flowNetwork) {
        self.network = network
        // TODO: Add token list cache
    }

    // MARK: Internal

    var network: FlowNetworkType

    func getFTBalance(address: FWAddress) async throws -> [TokenModel] {
        guard let addr = address as? EthereumAddress,
              let web3 = try await FlowProvider.Web3.default(networkType: network) else {
            throw EVMError.rpcError
        }

        let flowBalance = try await web3.eth.getBalance(for: addr)

        // The SimpleHash API doesn't return token metadata like logo and flowIdentifier
        // Hence, we need fetch the metadata from token list first
        let response: [EVMTokenResponse] = try await Network
            .request(FRWAPI.EVM.tokenList(address.hexAddr))
        var models = response.map { $0.toTokenModel(type: .evm) }
        let tokenMetadataResponse: SingleTokenResponse = try await Network
            .requestWithRawModel(GithubEndpoint.EVMTokenList(network))

        if let flowToken = TokenBalanceHandler.getFlowTokenModel(network: network) {
            var flowModel = flowToken.toTokenModel(type: .evm, network: network)
            flowModel.balance = flowBalance
            models.insert(flowModel, at: 0)
        }

        let updateModels: [TokenModel] = models.compactMap { model in
            var newModel = model
            if let metadata = tokenMetadataResponse.tokens.first(where: { token in
                token.address.lowercased() == model.address.mainnet?.lowercased()
            }) {
                if let logo = metadata.logoURI {
                    newModel.icon = URL(string: logo)
                }
                newModel.flowIdentifier = metadata.flowIdentifier
            }
            return newModel
        }

        // Sort by balance
        let sorted = updateModels.sorted { lhs, rhs in
            guard let lBal = lhs.readableBalance, let rBal = rhs.readableBalance else {
                return true
            }
            return lBal > rBal
        }

        return sorted
    }
    
    func getAllNFTsUnderCollection(
        address: any FWAddress,
        collectionIdentifier: String,
        progressHandler: @escaping (Int, Int) -> ()
    ) async throws -> [NFTModel] {
        var nfts = [NFTModel]()
        var currentOffset: String? = "0"
        let nftsInCollection = try? await getNFTCollections(address: address).first { $0.id == collectionIdentifier }?.count
        
        while let offset = currentOffset {
            let response = try await self.getNFTCollectionDetail(
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
