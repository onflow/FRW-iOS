//
//  WalletManager+Crypto.swift
//  FRW
//
//  Created by Hao Fu on 7/4/2025.
//

import Foundation
import WalletCore
import Flow

// MARK: - Helper

extension WalletManager {
    
    static func encryptionAES(
        key: String,
        iv: String = LocalEnvManager.shared.aesIV,
        data: Data
    ) throws -> Data {
        guard var keyData = key.data(using: .utf8), let ivData = iv.data(using: .utf8) else {
            throw LLError.aesKeyEncryptionFailed
        }
        if keyData.count > 16 {
            keyData = keyData.prefix(16)
        } else {
            keyData = keyData.paddingZeroRight(blockSize: 16)
        }

        guard let encrypted = AES.encryptCBC(key: keyData, data: data, iv: ivData, mode: .pkcs7)
        else {
            throw LLError.aesEncryptionFailed
        }
        return encrypted
    }

    static func decryptionAES(
        key: String,
        iv: String = LocalEnvManager.shared.aesIV,
        data: Data
    ) throws -> Data {
        guard var keyData = key.data(using: .utf8), let ivData = iv.data(using: .utf8) else {
            throw LLError.aesKeyEncryptionFailed
        }

        if keyData.count > 16 {
            keyData = keyData.prefix(16)
        } else {
            keyData = keyData.paddingZeroRight(blockSize: 16)
        }

        guard let decrypted = AES.decryptCBC(key: keyData, data: data, iv: ivData, mode: .pkcs7)
        else {
            throw LLError.aesEncryptionFailed
        }
        return decrypted
    }

    static func encryptionChaChaPoly(key: String, data: Data) throws -> Data {
        guard let cipher = ChaChaPolyCipher(key: key) else {
            throw EncryptionError.initFailed
        }
        return try cipher.encrypt(data: data)
    }

    static func decryptionChaChaPoly(key: String, data: Data) throws -> Data {
        guard let cipher = ChaChaPolyCipher(key: key) else {
            throw EncryptionError.initFailed
        }
        return try cipher.decrypt(combinedData: data)
    }
}
