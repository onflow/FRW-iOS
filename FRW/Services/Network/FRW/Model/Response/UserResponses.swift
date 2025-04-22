//
//  UserResponses.swift
//  Flow Wallet
//
//  Created by Hao Fu on 3/1/22.
//

import Foundation
import Flow

// MARK: - CheckUserResponse

struct CheckUserResponse: Codable {
    let unique: Bool
    let username: String
}

// MARK: - LoginResponse

struct LoginResponse: Codable {
    let customToken: String
    let id: String
}

// MARK: - RegisterResponse

struct RegisterResponse: Codable {
    let customToken: String
    let id: String
    let txId: String?
}

// MARK: - UserInfoResponse

struct UserInfoResponse: Codable {
    let avatar: String
    let nickname: String
    let username: String
    let `private`: Int
}

// MARK: - UserWalletResponse

struct UserWalletResponse: Codable {
    let id: String
    let username: String?
    let wallets: [WalletResponse]?

    var currentNetworkWalletModel: WalletResponse? {
        wallets?
            .first(where: {
                $0.chainId == currentNetwork.rawValue && $0.blockchain != nil
            })
    }

    func getNetworkWalletModel(network: Flow.ChainID) -> WalletResponse? {
        wallets?.first(where: { $0.chainId == network.rawValue && $0.blockchain != nil })
    }
}

// MARK: - WalletResponse

struct WalletResponse: Codable {
    let color: String?
    let icon: String?
    let name: String?
    let id: Int
    let chainId: String
    let blockchain: [BlockChainResponse]?

    var isEmptyBlockChain: Bool {
        if let blockchain = blockchain, !blockchain.isEmpty {
            return false
        } else {
            return true
        }
    }

    var getAddress: String? {
        blockchain?.first?.address
    }

    var getName: String? {
        blockchain?.first?.name
    }
}

// MARK: - BlockChainResponse

struct BlockChainResponse: Codable {
    let id: Int
    let chainId: String
    let name: String?
    let address: String?
    let coins: [String]?
}

// MARK: - UserSearchResponse

struct UserSearchResponse: Codable {
    let users: [UserInfo]?
}

// struct CoinsResponse: Codable {
//    let decimal: Int
//    let isToken: Bool
//    let name: String
//    let symbol: String
// }
