//
//  EVMModels.swift
//  FRW
//
//  Created by cat on 2024/4/24.
//

import BigInt
import Foundation
import Web3Core
import web3swift

struct EVMTransactionExecuted: Codable {
    let hash: [UInt8]?

    var hashString: String? {
        guard let hash = hash else {
            return nil
        }
        return Data(hash).hexValue.addHexPrefix()
    }
}

struct EVMTransactionReceive: Codable {
    let to: String?
    let from: String?
    let value: String?
    let gas: String?
    let data: String?

    var amount: String {
        let defaultValue = "0"
        guard let balance = value else { return defaultValue }
        guard let value = BigUInt(from: balance) else { return defaultValue }
        return Utilities.formatToPrecision(value, formattingDecimals: 64)
    }

    var gasValue: UInt64 {
        let defaultValue: UInt64 = WalletManager.defaultGas
        guard let gasStr = gas else { return defaultValue }
        guard let value = UInt64(gasStr.stripHexPrefix(), radix: 16) else { return defaultValue }
        return value
    }

    var dataValue: Data? {
        guard let dataStr = data else { return nil }
        return Data(hex: dataStr)
    }

    var toAddress: String? {
        return to?.stripHexPrefix()
    }
}
