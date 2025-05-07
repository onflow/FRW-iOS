//
//  FTV3Response.swift
//  FRW
//
//  Created by cat on 4/29/25.
//

import Foundation

// only used when fetch
struct FTResponse: Codable {
    let tokens: [FTTokenModel]
}

struct FTTokenModel: Codable {
    let address: String
    let contractName: String?
    let path: FTTokenModel.Path?
    let evmAddress: String?
    let flowAddress: String?
    let symbol: String
    let name: String
    let description: String?
    let decimals: Int?
    let logoURI: String?
    let flowIdentifier: String?
    let website: URL?
    let isVerified: Bool?

    func toTokenModel() -> TokenModel {
        TokenModel(name: name, symbol: symbol, description: description, contractAddress: address, contractName: contractName ?? "", storagePath: path?.storagePath, receiverPath: path?.receiverPath, balancePath: path?.balancePath, identifier: flowIdentifier, isVerified: isVerified, logoURI: logoURI, priceInUSD: nil, balanceInUSD: nil, priceInFLOW: nil, balanceInFLOW: nil, currency: nil, priceInCurrency: nil, balanceInCurrency: nil, displayBalance: nil, decimal: decimals, evmAddress: evmAddress, website: website)
    }
}

extension FTTokenModel {
    struct Path: Codable {
        let vault: String?
        let receiver: String?
        let balance: String?

        var storagePath: FlowPath? {
            parsePath(value: vault)
        }

        var receiverPath: FlowPath? {
            parsePath(value: receiver)
        }

        var balancePath: FlowPath? {
            parsePath(value: balance)
        }

        private func parsePath(value: String?) -> FlowPath? {
            let tmp = value?.removePrefix("/")
            guard let list = tmp?.components(separatedBy: "/"), list.count == 2 else {
                return nil
            }
            return FlowPath(domain: list[0], identifier: list[1])
        }
    }
}
