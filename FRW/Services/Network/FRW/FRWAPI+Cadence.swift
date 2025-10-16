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
        case signAsFeePayer(SignPayerRequest)
    }
}

// MARK: - FRWAPI.Cadence + TargetType, AccessTokenAuthorizable

extension FRWAPI.Cadence: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        switch self {
        case .list, .signAsBridgeFeePayer, .signAsFeePayer:
            return Config.get(.lilicoWeb)
        }
    }

    var path: String {
        switch self {
        case .list:
            return "v2/scripts"
        case .signAsBridgeFeePayer:
            return "signAsBridgePayer"
        case .signAsFeePayer:
          return "signAsFeePayer"
        }
    }

    var method: Moya.Method {
        switch self {
        case .list:
            return .get
        case .signAsBridgeFeePayer, .signAsFeePayer:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .list:
            return .requestParameters(parameters: [:], encoding: URLEncoding.queryString)
        case let .signAsBridgeFeePayer(request):
            return .requestJSONEncodable(request)
        case let .signAsFeePayer(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        var headers = FRWAPI.commonHeaders
        headers["version"] = CadenceManager.shared.version
        return headers
    }
}
