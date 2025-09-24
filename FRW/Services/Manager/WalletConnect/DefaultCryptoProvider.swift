//
//  DefaultCryptoProvider.swift
//  FRW
//
//  Created by cat on 2024/6/12.
//

import BigInt
import CryptoSwift
import Foundation
import secp256k1
import WalletCore
import Web3Core

import WalletConnectSigner

struct DefaultCryptoProvider: CryptoProvider {
    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        guard let data = SECP256K1.recoverPublicKey(hash: message, signature: signature.serialized)
        else {
            throw WalletError.emptyPublicKey
        }
        return data
    }

    public func keccak256(_ data: Data) -> Data {
        let digest = SHA3(variant: .keccak256)
        let bytes = [UInt8](data)
        let hash = digest.calculate(for: bytes.withUnsafeBytes { Array($0) })
        return Data(hash)
    }
}
