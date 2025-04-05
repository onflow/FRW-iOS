//
//  FRWAPI+Cadence.swift
//  FRW
//
//  Created by cat on 2024/3/6.
//

import Foundation
import Moya

// MARK: - FRWAPI.Cadence

extension FRWAPI {
    enum Cadence {
        case list
        case signAsBridgeFeePayer(SignPayerRequest)
    }
}

// MARK: - FRWAPI.Cadence + TargetType, AccessTokenAuthorizable

extension FRWAPI.Cadence: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        switch self {
        case .list, .signAsBridgeFeePayer:
            return Config.get(.lilicoWeb)
        }
    }

    var path: String {
        switch self {
        case .list:
            return "v2/scripts"
        case .signAsBridgeFeePayer:
            return "signAsBridgeFeePayer"
        }
    }

    var method: Moya.Method {
        switch self {
        case .list:
            return .get
        case let .signAsBridgeFeePayer(signPayerRequest):
            return .post
        }
    }

    var task: Task {
        switch self {
        case .list:
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case let .signAsBridgeFeePayer(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        var headers = FRWAPI.commonHeaders
        headers["version"] = CadenceManager.shared.version
        return headers
    }
}
