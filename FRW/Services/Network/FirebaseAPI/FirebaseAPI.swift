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
    @available(*, deprecated, renamed: "Please use FRWWebEndpoint.signAsPayer instead", message: "Don't use this anymore")
    case signAsPayer(SignPayerRequest)
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
        case .signAsPayer:
            return "/signAsPayer"
        case .moonPay:
            return "/moonPaySignature"
        }
    }

    var method: Moya.Method {
        switch self {
        case .moonPay, .signAsPayer:
            return .post
        }
    }

    var task: Task {
        switch self {
        case let .moonPay(request):
            return .requestJSONEncodable(request)
        case let .signAsPayer(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        FRWAPI.commonHeaders
    }
}
