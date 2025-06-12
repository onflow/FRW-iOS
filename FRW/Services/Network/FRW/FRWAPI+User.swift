//
//  Flow WalletAPI+Account.swift
//  Flow Wallet
//
//  Created by Hao Fu on 19/5/2022.
//

import Foundation
import Moya

// MARK: - FRWAPI.User

extension FRWAPI {
    enum User {
        case login(LoginRequest)
        case register(RegisterRequest)
        case checkUsername(String)
        case userAddress
        case userAddressV2
        case userInfo
        case userWallet
        case search(String)
        case manualCheck
        case crescendo(NetworkRequest)
        case keys
        case devices(String)
        case syncDevice(SyncInfo.DeviceInfo)
        case addSigned(SignedRequest)
        case updateDevice(String)
        case checkimport(String)
        case loginWithImport(RestoreImportRequest)
        case createAddress(CreateAddress)
    }
}

// MARK: - FRWAPI.User + TargetType, AccessTokenAuthorizable

extension FRWAPI.User: TargetType, AccessTokenAuthorizable {
    var authorizationType: AuthorizationType? {
        .bearer
    }

    var baseURL: URL {
        Config.get(.lilico)
    }

    var path: String {
        switch self {
        case .login:
            return "/v3/login"
        case .checkUsername:
            return "/v1/user/check"
        case .register:
            return "/v3/register"
        case .userAddress:
            return "/v1/user/address"
        case .userAddressV2:
            return "/v2/user/address"
        case .userInfo:
            return "/v1/user/info"
        case .userWallet:
            return "/v2/user/wallet"
        case .search:
            return "/v1/user/search"
        case .manualCheck:
            return "/v1/user/manualaddress"
        case .crescendo:
            return "/v1/user/address/network"
        case .keys:
            return "/v1/user/keys"
        case .devices:
            return "/v1/user/device"
        case .syncDevice:
            return "/v3/sync"
        case .addSigned:
            return "/v3/signed"
        case .updateDevice:
            return "/v1/user/device"
        case .checkimport:
            return "/v3/checkimport"
        case .loginWithImport:
            return "/v3/import"
        case .createAddress:
            return "/v2/user/manualaddress"
        }
    }

    var method: Moya.Method {
        switch self {
        case .checkUsername, .userInfo, .userWallet, .search, .keys, .devices, .checkimport:
            return .get
        case .login, .register, .userAddress, .userAddressV2, .manualCheck, .crescendo, .syncDevice, .addSigned,
             .updateDevice, .loginWithImport, .createAddress:
            return .post
        }
    }

    var task: Task {
        switch self {
        case .userAddress, .userInfo, .userWallet, .manualCheck, .keys, .userAddressV2:
            return .requestPlain
        case let .checkUsername(username):
            return .requestParameters(
                parameters: ["username": username],
                encoding: URLEncoding.queryString
            )
        case let .register(request):
            return .requestCustomJSONEncodable(request, encoder: FRWAPI.jsonEncoder)
        case let .login(request):
            return .requestCustomJSONEncodable(request, encoder: FRWAPI.jsonEncoder)
        case let .search(keyword):
            return .requestParameters(
                parameters: ["keyword": keyword],
                encoding: URLEncoding.queryString
            )
        case let .devices(uuid):
            return .requestParameters(
                parameters: ["device_id": uuid],
                encoding: URLEncoding.queryString
            )
        case let .syncDevice(request):
            return .requestCustomJSONEncodable(request, encoder: FRWAPI.jsonEncoder)
        case let .addSigned(request):
            return .requestCustomJSONEncodable(request, encoder: FRWAPI.jsonEncoder)
        case let .crescendo(request):
            return .requestCustomJSONEncodable(request, encoder: FRWAPI.jsonEncoder)
        case let .updateDevice(uuid):
            return .requestJSONEncodable(["device_id": uuid])
        case let .checkimport(key):
            return .requestParameters(parameters: ["key": key], encoding: URLEncoding.queryString)
        case let .loginWithImport(request):
            return .requestCustomJSONEncodable(request, encoder: FRWAPI.jsonEncoder)
        case let .createAddress(request):
            return .requestJSONEncodable(request)
        }
    }

    var headers: [String: String]? {
        var headers = FRWAPI.commonHeaders
        switch self {
        case .crescendo:
            headers["Network"] = "crescendo"
        default:
            break
        }

        return headers
    }
}
