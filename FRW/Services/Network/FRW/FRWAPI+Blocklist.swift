//
//  FRWAPI+Blocklist.swift
//  FRW
//
//  Created by cat on 4/8/25.
//

import Foundation
import Moya

extension FRWAPI {
    enum Blocklist {
        case domain
    }
}

extension FRWAPI.Blocklist: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        switch self {
        case .domain:
            return URL(string:"https://flow-blocklist.vercel.app")!
        }
    }

    var path: String {
        switch self {
        case .domain:
            return "/api/domain"
        }
    }

    var method: Moya.Method {
        switch self {
        case .domain:
            return .get
        }
    }

    var task: Task {
        let network = LocalUserDefaults.shared.flowNetwork.rawValue

        switch self {
        case .domain:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        let headers = FRWAPI.commonHeaders
        return headers
    }
}
