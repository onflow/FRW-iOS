//
//  Web3Provider.swift
//  FRW
//
//  Created by cat on 2024/5/16.
//

import BigInt
import Flow
import Foundation
import web3swift

enum FlowProvider {
    enum ABIType: String {
        case erc721
        case erc1155
    }

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

        static func NFTContract(_ type: FlowProvider.ABIType = .erc721) async throws -> web3swift.Web3.Contract? {
            var abi = Web3Utils.erc721ABI
            switch type {
            case .erc721:
                abi = Web3Utils.erc721ABI
            case .erc1155:
                abi = Web3Utils.erc1155ABI
            }
            let web3 = try await FlowProvider.Web3.default()
            let erc721Contract = web3?.contract(abi)
            return erc721Contract
        }
    }
}
