//
//  BridgeModels.swift
//  FRW
//
//  Auto-generated from TypeScript bridge types
//  Do not edit manually
//

import Foundation

enum RNBridge {
    enum AccountType: String, Codable {
        case main = "main"
        case child = "child"
        case evm = "evm"
    }

    enum ScreenType: String, Codable {
        case sendAsset = "send-asset"
        case tokenDetail = "token-detail"
    }

    struct EmojiInfo: Codable {
        let emoji: String
        let name: String
        let color: String
    }

    struct Contact: Codable {
        let id: String
        let name: String
        let address: String
        let avatar: String?
        let username: String?
        let contactName: String?
    }

    struct AddressBookContact: Codable {
        let id: String
        let name: String
        let address: String
        let avatar: String?
        let username: String?
        let contactName: String?
    }

    struct WalletAccount: Codable {
        let id: String
        let name: String
        let address: String
        let emojiInfo: EmojiInfo?
        let parentEmoji: EmojiInfo?
        let parentAddress: String?
        let avatar: String?
        let isActive: Bool
        let type: AccountType?
        let balance: String?
        let nfts: String?
    }

    struct RecentContactsResponse: Codable {
        let contacts: [Contact]
    }

    struct WalletAccountsResponse: Codable {
        let accounts: [WalletAccount]
    }

    struct AddressBookResponse: Codable {
        let contacts: [AddressBookContact]
    }

    struct SendToConfig: Codable {
        let selectedToken: TokenModel?
        let fromAccount: WalletAccount?
        let selectedNFTs: [NFTModel]?
        let targetAddress: String?
    }

    struct InitialProps: Codable {
        let screen: ScreenType
        let sendToConfig: SendToConfig?
    }

    struct EnvironmentVariables: Codable {
        let NODE_API_URL: String
        let GO_API_URL: String
        let INSTABUG_TOKEN: String
    }

    struct Currency: Codable {
        let name: String
        let symbol: String
        let rate: String
    }

    struct NFTModel: Codable {
        let id: String?
        let name: String?
        let description: String?
        let thumbnail: String?
        let externalURL: String?
        let collectionName: String?
        let collectionContractName: String?
        let contractAddress: String?
        let evmAddress: String?
        let address: String?
        let contractName: String?
        let collectionDescription: String?
        let collectionSquareImage: String?
        let collectionBannerImage: String?
        let collectionExternalURL: String?
        let flowIdentifier: String?
        let postMedia: NFTPostMedia?
        let contractType: String?
        let amount: String?
        let type: WalletType
    }

    struct NFTPostMedia: Codable {
        let image: String?
        let isSvg: Bool?
        let description: String?
        let title: String?
    }

    struct TokenModel: Codable {
        let type: WalletType
        let name: String
        let symbol: String?
        let description: String?
        let balance: String?
        let contractAddress: String?
        let contractName: String?
        let storagePath: FlowPath?
        let receiverPath: FlowPath?
        let balancePath: FlowPath?
        let identifier: String?
        let isVerified: Bool?
        let logoURI: String?
        let priceInUSD: String?
        let balanceInUSD: String?
        let priceInFLOW: String?
        let balanceInFLOW: String?
        let currency: String?
        let priceInCurrency: String?
        let balanceInCurrency: String?
        let displayBalance: String?
        let availableBalanceToUse: String?
        let change: String?
        let decimal: Int?
        let evmAddress: String?
        let website: String?
    }

    enum WalletType: String, Codable {
        case flow = "flow"
        case evm = "evm"
    }

    struct FlowPath: Codable {
        let domain: String?
        let identifier: String?
    }

}
