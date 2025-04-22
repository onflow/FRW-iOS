//
//  NetworkProvider.swift
//  FRW
//
//  Created by cat on 2024/5/16.
//

import Foundation
import Flow

extension Flow.ChainID {
    var networkID: Int {
        switch self {
        case .testnet:
            return 545
        case .mainnet:
            return 747
        default:
            return 747
        }
    }

    var evmURL: URL {
        switch self {
        case .testnet:
            return URL(string: "https://testnet.evm.nodes.onflow.org")!
        case .mainnet:
            return URL(string: "https://mainnet.evm.nodes.onflow.org")!
        default:
            return URL(string: "https://mainnet.evm.nodes.onflow.org")!
        }
    }
}
