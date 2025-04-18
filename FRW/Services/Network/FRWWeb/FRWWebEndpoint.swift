//
//  FRWWebEndpoint.swift
//  Flow Wallet
//
//  Created by Hao Fu on 29/9/2022.
//

import Foundation
import Moya

// MARK: - FRWWebEndpoint

enum FRWWebEndpoint {
    case txTemplate(TxTemplateRequest)
    case swapEstimate(SwapEstimateRequest)
}

// MARK: TargetType

extension FRWWebEndpoint: TargetType {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        URL(string: "https://web.api.wallet.flow.com/api/")!
    }

    var path: String {
        switch self {
        case .txTemplate:
            return "template"
        case .swapEstimate:
            return "swap/v1/\(LocalUserDefaults.shared.network.rawValue)/estimate"
        }
    }

    var method: Moya.Method {
        switch self {
        case .txTemplate:
            return .post
        case .swapEstimate:
            return .get
        }
    }

    var task: Task {
        switch self {
        case let .txTemplate(request):
            return .requestJSONEncodable(request)
        case let .swapEstimate(request):
            return .requestParameters(
                parameters: request.dictionary ?? [:],
                encoding: URLEncoding.queryString
            )
        }
    }

    var headers: [String: String]? {
        FRWAPI.commonHeaders
    }
}
