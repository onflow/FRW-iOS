//
//  SymmetricEncryptionTests.swift
//  DapperProTests
//
//  Created by Hao Fu on 7/10/2022.
//

@testable import FRW_dev
import XCTest

final class SymmetricEncryptionTests: XCTestCase {
    let key = "0123456789"
    let seedPhrase = "upgrade snack buzz employ female cute quote kit rack couple toddler glare"
    let base64Encrypted =
        "R1GTsKkvL8lL1MTztxur3NDAvaJv6g6adciYhRxe/Jg1/aY87WbNzdwV2HhWpfSAn6AwezSOZ+nhJLmP1Ck37Zx4SBXU14rVW1Lzw8vcxfLJRSDEW3Cmx4N8jlx78xyMrQCEJTM="

    let AESBase64Encrypted =
        "W1+ejoJBIqZ1vwDxWeic38QjTjXeP0p827gzwHOw5v9YTFQltrvlEaGa336AUAbJbZxfUFBVIgLQbIelN2FQ6rlUUkP7TWIIGD6rdjkr7GSFtCTjHqvkxyTLVlMGeKDIYX9md3I="

    // MARK: - ChaChaPoly

    // Encryption
    func testChaChaPoly() throws {
        let dataToEncrypt = seedPhrase.data(using: .utf8)!
        let cipher = ChaChaPolyCipher(key: key)!
        let encryptedData = try! cipher.encrypt(data: dataToEncrypt)
        let deCryptedData = try cipher.decrypt(combinedData: encryptedData)
        let deCryptedStr = String(data: deCryptedData, encoding: .utf8)!
        XCTAssertEqual(seedPhrase, deCryptedStr)
    }

    // Decryption
    func testChaChaPolyDecryption() throws {
        let encryptedData = Data(base64Encoded: base64Encrypted)!
        let cipher = ChaChaPolyCipher(key: key)!
        let deCryptedData = try cipher.decrypt(combinedData: encryptedData)
        let deCryptedStr = String(data: deCryptedData, encoding: .utf8)!
        XCTAssertEqual(seedPhrase, deCryptedStr)
    }

    // MARK: - AES GCM

    // Encryption
    func testAESGCM() throws {
        let dataToEncrypt = seedPhrase.data(using: .utf8)!
        let cipher = AESGCMCipher(key: key)!
        let encryptedData = try! cipher.encrypt(data: dataToEncrypt)
        let deCryptedData = try cipher.decrypt(combinedData: encryptedData)
        let deCryptedStr = String(data: deCryptedData, encoding: .utf8)!
        XCTAssertEqual(seedPhrase, deCryptedStr)
    }

    // Decryption
    func testAESDecryption() throws {
        let encryptedData = Data(base64Encoded: AESBase64Encrypted)!
        let cipher = AESGCMCipher(key: key)!
        let deCryptedData = try cipher.decrypt(combinedData: encryptedData)
        let deCryptedStr = String(data: deCryptedData, encoding: .utf8)!
        XCTAssertEqual(seedPhrase, deCryptedStr)
    }
}
