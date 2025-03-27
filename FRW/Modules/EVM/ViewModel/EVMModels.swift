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

// MARK: - EVMTransactionExecuted

struct EVMTransactionExecuted: Codable {
    let hash: [UInt8]?

    var hashString: String? {
        guard let hash = hash else {
            return nil
        }
        return Data(hash).hexValue.addHexPrefix()
    }
}

// MARK: - EVMTransactionReceive

struct EVMTransactionReceive: Codable {
    let to: String?
    let from: String?
    let value: String?
    let gas: String?
    let data: String?

    var amount: BigUInt {
        let defaultValue = BigUInt(0)
        guard let balance = value else { return defaultValue }
        guard let value = BigUInt(from: balance) else { return defaultValue }
        return value
    }

    var amountValue: String {
        Utilities.formatToPrecision(amount, formattingDecimals: 64)
    }

    var bigAmount: BigUInt {
        let defaultValue = BigUInt(0)
        guard let balance = value else { return defaultValue }
        guard let value = BigUInt(from: balance) else { return defaultValue }
        return value
    }

    var gasValue: BigUInt {
        let defaultValue = BigUInt(WalletManager.defaultGas)
        guard let gasStr = gas else { return defaultValue }
        guard let value = BigUInt(gasStr.stripHexPrefix(), radix: 16) else { return defaultValue }
        return value
    }

    var dataValue: Data? {
        guard let dataStr = data else { return nil }
        return Data(hex: dataStr)
    }

    var toAddress: String? {
        to?.stripHexPrefix()
    }
}
