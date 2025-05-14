//
//  FRWAPI+EVM.swift
//  FRW
//
//  Created by cat on 2024/4/29.
//

import Foundation
import Moya

// MARK: - FRWAPI.EVM

extension FRWAPI {
    enum EVM {
        case tokenList(String)
        case nfts(String?)
        case decodeData(String,String)
    }
}

// MARK: - FRWAPI.EVM + TargetType, AccessTokenAuthorizable

extension FRWAPI.EVM: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        switch self {
        case .tokenList, .nfts, .decodeData:
            return Config.get(.lilicoWeb)
        }
    }

    var path: String {
        switch self {
        case let .tokenList(addr):
            return "v3/evm/\(addr)/fts"
        case let .nfts(addr):
            if let addr = addr {
                return "v2/evm/\(addr)/nfts"
            }
            return "v2/evm/nfts"
        case .decodeData(_, _):
            return "evm/decodeData"
        }
    }

    var method: Moya.Method {
        switch self {
        case .decodeData:
            return .post
        default:
            return .get
        }
    }

    var task: Task {
        let network = currentNetwork.rawValue

        switch self {
        case .tokenList, .nfts:
            return .requestParameters(
                parameters: ["network": network],
                encoding: URLEncoding.queryString
            )
        case .decodeData(let address, let data):
            return .requestJSONEncodable(["to": address, "data": data])
        }
    }

    var headers: [String: String]? {
        let headers = FRWAPI.commonHeaders
        return headers
    }
}
