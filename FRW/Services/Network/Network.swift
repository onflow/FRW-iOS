//
//  Network.swift
//  Flow Wallet
//
//  Created by Hao Fu on 2/1/22.
//

import Combine
import CombineMoya
import FirebaseAuth
import Foundation
import Haneke
import Moya

// MARK: - NetworkError

public enum NetworkError: Error {
    case unAuth
    case emptyIDToken
    case decodeFailed
    case emptyData
}

// MARK: - Network

enum Network {
    struct Response<T: Decodable>: Decodable {
        enum CodingKeys: String, CodingKey {
            case httpCode = "status"
            case message
            case data
        }

        let httpCode: Int
        let message: String?
        let data: T?
    }

    struct EmptyResponse: Decodable {
        enum CodingKeys: String, CodingKey {
            case httpCode = "status"
            case message
        }

        let httpCode: Int
        let message: String
    }

    static func fetchIDToken() async throws -> String {
        if let currentUser = Auth.auth().currentUser {
            return try await currentUser.getIDToken()
        }

        let result = try await Auth.auth().signInAnonymously()
        return try await result.user.getIDToken()
    }

    static func request<T: Decodable, U: TargetType>(
        _ target: U,
        decoder: JSONDecoder = FRWAPI.jsonDecoder,
        needToken: Bool = true
    ) async throws -> T {
        let token = try await fetchIDToken()
        let authPlugin = AccessTokenPlugin { _ in token }
//        let logPlugin = NetworkLoggerPlugin(configuration: .init(logOptions: .default))
        let provider = MoyaProvider<U>(plugins: needToken ? [authPlugin] : [])
        let result = await provider.asyncRequest(target)
        switch result {
        case let .success(response):
            do {
                let filterdResponse = try response.filterSuccessfulStatusCodes()
                let model = try decoder.decode(Response<T>.self, from: filterdResponse.data)
                guard let data = model.data else {
                    throw NetworkError.emptyData
                }
                return data
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
    }

    static func requestWithRawModel<T: Decodable, U: TargetType>(
        _ target: U,
        decoder: JSONDecoder = FRWAPI.jsonDecoder,
        needAuthToken: Bool = true
    ) async throws -> T {
        let token = try await fetchIDToken()
        let authPlugin = AccessTokenPlugin { _ in token }
        let provider =
            MoyaProvider<U>(
                plugins: needAuthToken ? [NetworkLoggerPlugin(), authPlugin] :
                    [NetworkLoggerPlugin()]
            )
        let result = await provider.asyncRequest(target)
        switch result {
        case let .success(response):
            do {
                let filterdResponse = try response.filterSuccessfulStatusCodes()
                let model = try decoder.decode(T.self, from: filterdResponse.data)
                return model
            } catch {
                throw error
            }
        case let .failure(error):
            throw error
        }
    }
    
    static func requestWithRawResponse<U: TargetType>(
        _ target: U,
        needToken: Bool = true
    ) async throws -> Moya.Response {
        let token = try await fetchIDToken()
        let authPlugin = AccessTokenPlugin { _ in token }
        let provider =
            MoyaProvider<U>(
                plugins: needToken ? [NetworkLoggerPlugin(), authPlugin] :
                    [NetworkLoggerPlugin()]
            )
        let result = await provider.asyncRequest(target)
        switch result {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }
}
