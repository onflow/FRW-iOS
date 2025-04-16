//
//  Flow WalletAPI.swift
//  Flow Wallet
//
//  Created by Hao Fu on 29/12/21.
//

import Foundation

enum FRWAPI {
    static var jsonEncoder: JSONEncoder {
        let coder = JSONEncoder()
        coder.keyEncodingStrategy = .convertToSnakeCase
        return coder
    }

    static var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    static var commonHeaders: [String: String] {
        let network = currentNetwork.rawValue
        return ["Network": network]
    }
}
