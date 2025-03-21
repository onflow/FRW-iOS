//
//  FWAddress.swift
//  FRW
//
//  Created by Hao Fu on 24/2/2025.
//

import Flow
import Foundation
import Web3Core

// MARK: - VMType

enum VMType: String {
    case cadence
    case evm

    // MARK: Internal

    func toTokenType() -> TokenModel.TokenType {
        switch self {
        case .cadence:
            return .cadence
        case .evm:
            return .evm
        }
    }
}

// MARK: - FWAddress

protocol FWAddress {
    var type: VMType { get }
    var hexAddr: String { get }

    var cacheKey: String { get }
}

extension FWAddress {
    var cacheKey: String {
        "\(type.rawValue)-\(hexAddr)"
    }
}

// MARK: - FWAddressDector

enum FWAddressDector {
    static func create(address: String?) -> FWAddress? {
        guard let address, !address.isEmpty else {
            return nil
        }

        let hexAddr = address.addHexPrefix()

        if let ethAddr = EthereumAddress(hexAddr) {
            return ethAddr
        }

        return Flow.Address(hex: hexAddr.stripHexPrefix())
    }
}

// MARK: - Flow.Address + FWAddress

extension Flow.Address: FWAddress {
    var type: VMType {
        .cadence
    }

    var hexAddr: String {
        hex
    }
}

// MARK: - EthereumAddress + FWAddress

extension EthereumAddress: FWAddress {
    var type: VMType {
        .evm
    }

    var hexAddr: String {
        address
    }
}
