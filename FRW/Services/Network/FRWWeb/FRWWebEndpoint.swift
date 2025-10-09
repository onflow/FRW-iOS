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
    case signAsPayer(SignPayerRequest)
    case signAsBridgePayer()
    case payerStatus
}

// MARK: TargetType

extension FRWWebEndpoint: TargetType {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        Config.get(.lilicoWeb)
    }

    var path: String {
        switch self {
        case .txTemplate:
            return "template"
        case .swapEstimate:
            return "swap/v1/\(LocalUserDefaults.shared.network.rawValue)/estimate"
        case .signAsPayer:
            return "signAsPayer"
        case .payerStatus:
            return "v1/payer/status"
        }
    }

    var method: Moya.Method {
        switch self {
        case .txTemplate, .signAsPayer:
            return .post
        case .swapEstimate, .payerStatus:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .payerStatus:
          return .requestPlain
        case let .txTemplate(request):
            return .requestJSONEncodable(request)
        case let .swapEstimate(request):
            return .requestParameters(
                parameters: request.dictionary ?? [:],
                encoding: URLEncoding.queryString
            )
        case let .signAsPayer(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        FRWAPI.commonHeaders
    }
}
