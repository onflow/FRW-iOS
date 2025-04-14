//
//  CadenceManager+Secure.swift
//  FRW
//
//  Created by Hao Fu on 14/4/2025.
//

import Foundation
import CryptoKit

extension CadenceManager {
    
    func verifySignature(signature: String, data: Data) -> Bool? {
        let pubKeyStr = ServiceConfig.shared.scriptPublicKey
        guard let pubKey = try? P256.Signing.PublicKey(rawRepresentation: pubKeyStr.hexValue.data),
              let sig = try? P256.Signing.ECDSASignature(rawRepresentation: signature.hexValue)
//              let data = message.data(using: .utf8)
        else {
            return nil
        }
        let hashedData = SHA256.hash(data: data)
        return pubKey.isValidSignature(sig, for: hashedData)
    }
    
}
