//
//  EVMTokenResponse.swift
//  FRW
//
//  Created by cat on 2024/4/29.
//

import BigInt
import Foundation
import Web3Core
import web3swift

// MARK: - EVMTokenResponse

struct EVMTokenResponse: Codable {
    let chainId: Int
    let address: String
    let symbol: String
    let name: String
    let decimals: Int
    let logoURI: String
    let balance: String?
    let flowIdentifier: String?

    var flowBalance: Decimal {
        guard let bal = balance, let value = BigUInt(bal) else {
            return 0
        }

        let result = Utilities.formatToPrecision(
            value,
            units: .custom(decimals),
            formattingDecimals: decimals
        )
        return Decimal(string: result) ?? Decimal(0)
    }

    var uniKey: String {
        address
    }

    func toTokenModel(type: TokenModel.TokenType) -> TokenModel {
        let model = TokenModel(
            type: type,
            name: name,
            address: FlowNetworkModel(
                mainnet: address,
                testnet: address,
                crescendo: address
            ),
            contractName: "",
            storagePath: FlowTokenStoragePath(
                balance: "",
                vault: "",
                receiver: ""
            ),
            decimal: decimals,
            icon: .init(string: logoURI),
            symbol: symbol,
            website: nil,
            evmAddress: address,
            flowIdentifier: flowIdentifier,
            balance: BigUInt(balance ?? "-1"),
            avaibleBalance: BigUInt(balance ?? "-1")
        )
        return model
    }
}

// MARK: - EVMCollection

struct EVMCollection: Codable {
    let chainId: Int
    let address: String
    let symbol: String
    let name: String
    let tokenURI: String
    let logoURI: String
    let balance: String?
    let flowIdentifier: String?
    let nftIds: [String]
    let nfts: [EVMNFT]

    func toNFTCollection() -> NFTCollection {
        let contractName = flowIdentifier?.split(separator: ".")[2] ?? ""
        let contractAddress = flowIdentifier?.split(separator: ".")[1] ?? ""
        let info = NFTCollectionInfo(
            id: flowIdentifier ?? "",
            name: name,
            contractName: String(contractName),
            address: String(contractAddress),
            logo: logoURI,
            banner: nil,
            officialWebsite: nil,
            description: nil,
            path: ContractPath(
                storagePath: "",
                publicPath: "",
                privatePath: nil,
                publicCollectionName: nil,
                publicType: nil,
                privateType: nil
            ),
            evmAddress: address,
            flowIdentifier: flowIdentifier
        )
        let list = nfts.map { NFTModel(
            $0
                .toNFT(
                    collectionAddress: String(contractAddress),
                    contractName: String(contractName)
                ),
            in: info
        ) }
        let model = NFTCollection(
            collection: info,
            count: nfts.count,
            ids: nftIds,
            evmNFTs: list
        )
        return model
    }
}

// MARK: - EVMNFT

struct EVMNFT: Codable {
    let id: String
    let name: String
    let thumbnail: String

    func toNFT() -> NFTResponse {
        NFTResponse(
            id: id,
            name: name,
            description: nil,
            thumbnail: thumbnail,
            externalURL: nil,
            contractAddress: nil,
            evmAddress: nil,
            address: nil,
            collectionID: nil,
            collectionName: nil,
            collectionDescription: nil,
            collectionSquareImage: nil,
            collectionExternalURL: nil,
            collectionContractName: nil,
            collectionBannerImage: nil,
            traits: nil,
            postMedia: NFTPostMedia(
                title: nil,
                image: thumbnail,
                description: nil,
                video: nil,
                isSvg: nil
            )
        )
    }

    func toNFT(collectionAddress: String, contractName: String) -> NFTResponse {
        NFTResponse(
            id: id,
            name: name,
            description: nil,
            thumbnail: thumbnail,
            externalURL: nil,
            contractAddress: collectionAddress,
            evmAddress: nil,
            address: nil,
            collectionID: nil,
            collectionName: nil,
            collectionDescription: nil,
            collectionSquareImage: nil,
            collectionExternalURL: nil,
            collectionContractName: contractName,
            collectionBannerImage: nil,
            traits: nil,
            postMedia: NFTPostMedia(
                title: nil,
                image: thumbnail,
                description: nil,
                video: nil,
                isSvg: nil
            )
        )
    }
}
