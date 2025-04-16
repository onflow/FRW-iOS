//
//  GithubEndpoint.swift
//  Flow Wallet
//
//  Created by Hao Fu on 16/1/22.
//

import Foundation
import Moya
import Flow

// MARK: - GithubEndpoint

enum GithubEndpoint {
    case collections
    case ftTokenList(Flow.ChainID)
    case EVMNFTList(Flow.ChainID)
    case EVMTokenList(Flow.ChainID)
}

// MARK: TargetType

extension GithubEndpoint: TargetType {
    var baseURL: URL {
        URL(string: "https://raw.githubusercontent.com")!
    }

    var path: String {
        switch self {
        case .collections:
            return "/Outblock/Assets/main/nft/nft.json"
        case let .ftTokenList(network):
            return "/Outblock/token-list-jsons/outblock/jsons/\(network.rawValue)/flow/\(isDevModel ? "dev" : "default").json"
        case let .EVMNFTList(network):
            return "/Outblock/token-list-jsons/outblock/jsons/\(network.rawValue)/flow/nfts.json"
        case let .EVMTokenList(network):
            return "/Outblock/token-list-jsons/outblock/jsons/\(network.rawValue)/evm/\(isDevModel ? "dev" : "default").json"
        }
    }

    var method: Moya.Method {
        .get
    }

    var task: Task {
        .requestPlain
    }

    var headers: [String: String]? {
        nil
    }
}
