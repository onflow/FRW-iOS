//
//  Flow WalletAPI+Utils.swift
//  Flow Wallet
//
//  Created by Selina on 28/10/2022.
//

import Foundation
import Moya

// MARK: - FRWAPI.Utils

extension FRWAPI {
    enum Utils {
        case currencyRate(Currency)
        case retoken(String, String)
        case flowAddress(String)
        case coinbase(String)
    }
}

// MARK: - FRWAPI.Utils + TargetType, AccessTokenAuthorizable

extension FRWAPI.Utils: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        return .bearer
    }

    var baseURL: URL {
        switch self {
        case .currencyRate:
            return Config.get(.lilico)
        case .retoken:
            #if LILICOPROD
            return .init(string: "https://scanner.lilico.app")!
            #else
            return .init(string: "https://dev-scanner.lilico.app")!
            #endif
        case .flowAddress:
            return .init(string: "https://production.key-indexer.flow.com/")!
        case .coinbase:
          return Config.get(.lilicoWeb)
        }
    }

    var path: String {
        switch self {
        case .currencyRate:
            return "/v1/crypto/exchange"
        case .retoken:
            return "/retoken"
        case let .flowAddress(publicKey):
            let result = publicKey.stripHexPrefix()
            return "/key/\(result)"
        case let .coinbase(address):
          return "v4/onramp/coinbase"
        }
    }

    var method: Moya.Method {
        switch self {
        case .currencyRate, .flowAddress:
            return .get
        case .retoken, .coinbase:
            return .post
        }
    }

    var task: Task {
        switch self {
        case let .currencyRate(toCurrency):
            return .requestParameters(
                parameters: ["from": "USD", "to": toCurrency.rawValue],
                encoding: URLEncoding.queryString
            )
        case let .retoken(token, address):
            return .requestJSONEncodable(["token": token, "address": address])
        case .flowAddress:
            return .requestPlain
        case let .coinbase(address):
          return .requestJSONEncodable(["address": address])
        }
    }

    var headers: [String: String]? {
      return FRWAPI.commonHeaders
    }
}
