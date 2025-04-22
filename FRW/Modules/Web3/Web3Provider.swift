//
//  Web3Provider.swift
//  FRW
//
//  Created by cat on 2024/5/16.
//

import BigInt
import Foundation
import web3swift
import Flow

enum FlowProvider {
    struct Web3 {
        static func `default`(
            networkType: Flow.ChainID = currentNetwork
        ) async throws -> web3swift.Web3? {
            let provider = try await Web3HttpProvider(
                url: networkType.evmURL,
                network: .Custom(networkID: BigUInt(networkType.networkID))
            )
            return web3swift.Web3(provider: provider)
        }

        static func defaultContract() async throws -> web3swift.Web3.Contract? {
            let web3 = try await FlowProvider.Web3.default()
            return web3?.contract(Web3Utils.erc20ABI)
        }

        /// for nft
        static func erc721NFTContract() async throws -> web3swift.Web3.Contract? {
            let web3 = try await FlowProvider.Web3.default()
            let erc721Contract = web3?.contract(Web3Utils.erc721ABI)
            return erc721Contract
        }
    }
}
