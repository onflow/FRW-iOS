//
//  DAppModel.swift
//  Flow Wallet
//
//  Created by Hao Fu on 29/8/2022.
//

import Foundation

struct DAppModel: Codable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case name, url
        case testnetURL = "testnet_url"
        case sandboxnetURL = "sandboxnet_url"
        case crescendoURL = "crescendo_url"
        case description
        case logo, category
    }

    let name: String
    let url: URL
    let testnetURL: URL?
    let sandboxnetURL: URL?
    let crescendoURL: URL?
    let description: String
    let logo: URL
    let category: String

    var id: URL {
        url
    }

    var networkURL: URL? {
        return switch currentNetwork {
        case .mainnet: url
        case .testnet: testnetURL
        default: url
        }
    }

    var host: String? {
        var host = url.host
        if currentNetwork == .testnet {
            host = testnetURL?.host
        }
        return host
    }
}
