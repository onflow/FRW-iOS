//
//  JSModels.swift
//  Flow Wallet
//
//  Created by Selina on 5/9/2022.
//

import UIKit

// MARK: - FCLResponseProtocol

protocol FCLResponseProtocol {
    func uniqueId() -> String
}

// MARK: - JSFCLServiceModelWrapper

struct JSFCLServiceModelWrapper: Codable {
    let service: Service
}

// MARK: - FCLIdentity

struct FCLIdentity: Codable {
    let address: String
}

// MARK: - FCLProvider

struct FCLProvider: Codable {
    let address: String
    let description: String
    let icon: String
    let name: String
}

// MARK: - FCLExtension

struct FCLExtension: Codable {
    let endpoint: String?
    let f_type: String?
    let f_vsn: String?
    let id: String?
    let identity: FCLIdentity?
    let method: String?
    let provider: FCLProvider?
    let type: String?
    let uid: String?
}

// MARK: - FCLSimpleService

struct FCLSimpleService: Codable {
    let type: FCLServiceType
}

// MARK: - FCLApp

struct FCLApp: Codable {
    let icon: String?
    let title: String?
}

// MARK: - FCLClient

struct FCLClient: Codable {
    let extensions: [FCLExtension]?
    let fclLibrary: String?
    let fclVersion: String?
    let hostname: String?
    let network: String?
}

// MARK: - FCLServices

struct FCLServices: Codable {
    enum CodingKeys: String, CodingKey {
        case openIDScopes = "OpenID.scopes"
    }

    let openIDScopes: String?
}

// MARK: - FCLResponseConfig

struct FCLResponseConfig: Codable {
    let app: FCLApp?
    let client: FCLClient?
    let services: FCLServices?
}

// MARK: - FCLSimpleResponse

struct FCLSimpleResponse: Codable {
    let service: FCLSimpleService
    let type: String
    let config: FCLResponseConfig?

    var serviceType: FCLServiceType {
        service.type
    }

    var network: String? {
        config?.client?.network
    }

    var networkIsMatch: Bool {
        guard let network = network, !network.isEmpty else {
            return true
        }

        return network.lowercased() == currentNetwork.rawValue
    }
}

// MARK: - AuthzTransaction

struct AuthzTransaction: Codable {
    let url: String?
    let title: String?
    let voucher: Voucher
}
