//
//  FRWAPI+Token.swift
//  FRW
//
//  Created by cat on 4/28/25.
//

import Flow
import Foundation
import Moya

extension FRWAPI {
    struct TokenQuery: Codable {
        let address: String
        let currency: String
        let network: Flow.ChainID

        init(address: String, currency: String = "USD", network: Flow.ChainID = .mainnet) {
            self.address = address
            self.currency = currency
            self.network = network
        }
    }

    enum Token {
        case cadence(TokenQuery)
        case evm(TokenQuery)
        case all(VMType, Flow.ChainID)
    }
}

extension FRWAPI.Token: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        return Config.get(.lilicoWeb)
    }

    var path: String {
        switch self {
        case let .cadence(query):
            return "v4/cadence/tokens/ft/\(query.address)"
        case let .evm(query):
            return "v4/evm/tokens/ft/\(query.address)"
        case .all:
            return "v3/fts/full"
        }
    }

    var method: Moya.Method {
        .get
    }

    var task: Task {
        switch self {
        case let .cadence(tokenQuery):
            return .requestParameters(parameters: ["currency": tokenQuery.currency, "network": tokenQuery.network.name], encoding: URLEncoding())
        case let .evm(tokenQuery):
            return .requestParameters(parameters: ["currency": tokenQuery.currency, "network": tokenQuery.network.name], encoding: URLEncoding())
        case let .all(type, network):
            return .requestParameters(parameters: ["chain_type": type == .evm ? "evm" : "flow", "network": network.name], encoding: URLEncoding())
        }
    }

    var headers: [String: String]? {
        let headers = FRWAPI.commonHeaders
        return headers
    }
}
