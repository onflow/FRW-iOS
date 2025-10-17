//
//  FirebaseAPI.swift
//  Flow Wallet
//
//  Created by Hao Fu on 5/9/2022.
//

import BigInt
import Flow
import Foundation
import Moya

// MARK: - FirebaseAPI

enum FirebaseAPI {
    case moonPay(MoonPayRequest)
}

// MARK: TargetType, AccessTokenAuthorizable

extension FirebaseAPI: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        Config.get(.firebaseFunction)
    }

    var path: String {
        switch self {
        case .moonPay:
            return "/moonPaySignature"
        }
    }

    var method: Moya.Method {
        switch self {
        case .moonPay:
            return .post
        }
    }

    var task: Task {
        switch self {
        case let .moonPay(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        FRWAPI.commonHeaders
    }
}
