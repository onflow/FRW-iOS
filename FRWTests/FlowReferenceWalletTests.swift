//
//  Flow WalletTests.swift
//  Flow WalletTests
//
//  Created by Hao Fu on 26/6/2022.
//

import Flow
@testable import FRW_dev
import WalletCore
import XCTest

// MARK: - NewStakingInfoInner

struct NewStakingInfoInner: Codable {
    let id: UInt32
    let nodeID: String
    let tokensCommitted: Decimal
    let tokensStaked: Decimal
    let tokensUnstaking: Decimal
    let tokensRewarded: Decimal
    let tokensUnstaked: Decimal
    let tokensRequestedToUnstake: Decimal
}

// MARK: - LilicoTests

final class LilicoTests: XCTestCase {
//    func testStakeDecode() async throws {
//        do {
//            flow.configure(chainID: .mainnet)
//            let address = Flow.Address(hex: "0x84221fe0294044d7")
//            let replacedCadence = CadenceTemplate.queryStakeInfo
//                .replace(by: ScriptAddress.addressMap(on: .mainnet))
//            let model = try await flow.accessAPI.executeScriptAtLatestBlock(
//                script: Flow.Script(text: replacedCadence),
//                arguments: [.address(address)]
//            )
//            .decode([NewStakingInfoInner].self)
//
//            print(model)
//        } catch {
//            print(error)
//        }
//    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testStakeDecode() async throws {
        do {
//            flow.configure(chainID: .mainnet)
//            let address = Flow.Address(hex: "0x84221fe0294044d7")
//            let replacedCadence = CadenceTemplate.queryStakeInfo
//                .replace(by: ScriptAddress.addressMap(on: .mainnet))
//            let model = try await flow.accessAPI.executeScriptAtLatestBlock(
//                script: Flow.Script(text: replacedCadence),
//                arguments: [.address(address)]
//            )
//            .decode([NewStakingInfoInner].self)

//            print(model)
        } catch {
            print(error)
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
        let value = "color"
        let list = value.split(separator: ":", omittingEmptySubsequences: true)
        print(list)
    }

    func testBackupEncrypt() throws {
        let item = BackupManager.DriveItem()
        item.username = "testusername"
        item.uid = "123"
        item.data = ""
        item.version = "1"
        item.time = "\(Int(Date().timeIntervalSince1970 * 1000))"
        let array = [item]

        let encryptString = try BackupManager.shared.encryptList(array)
        let result = try BackupManager.shared.decryptHexString(encryptString)

        XCTAssert(result.first?.username == "testusername")
    }

    func testBackupDecrypt() throws {
        let encryptString =
            "1c04b3adcfddd1e83df51a3c264d33b0431c4c09025955c4555fa975bee8374781989d7769c53a8574da22c301ca3725093e9f6f4712d627181f3413a95ce9bcb243cb9681437c9e660b72887c1db379eaf1b11373bb8d6e1c85641597713392"
        let result = try BackupManager.shared.decryptHexString(encryptString)

        XCTAssert(result.first?.username == "testusername")
    }

    func testDecryptFromExtension() throws {
        let string =
            "1a38ed73a7434afac133942a1ede0c563813a3023e2b54538d0f9decac69388a56bd3ed9cf70b3bd45727e77581f592dd6277889714d6a1cb0a6719207d60661a679eee55c5bfb2c89c74e6d4e9d35c7d979e33d2eaf9b3f75631b4577bc347d41545afebd53e2d90443683b956ca69ebe169d660169a9df76c7299f515f849be6a612be27ac0837c3ce533fa2d5dd75d7169fc9442e41046835d86bfd3fc28972fce77b37417ba3a86790452a7d75ab2728c68dacd586ebf1cf5fd9e69c1c5be3323b3621e149208acac36eba6f1ca6cc767c585134c29e9082892cade31dab13f8a6985d4f269d6f90cb476793a578be6f474e1ead0833970ff9be1c50c7a5eea8fe873f0dc3408eea4390d2c3c325a8c2310a71026b6758e8fc6b5f1339a8bec9d1f6b81a6d75836dec3052a7edd26af01279dfe3245c83fac6a6ee758c75d7aa5b4718d04c9586f6ef0e18d1447365ee8ae4d7c6f7e40b8cc84122fb86f499fba4022a11226be295d7143c1a6ed8dac3f190781a7a969dbcb30e606e64b292f011868213003f9e28e250c62829ecf86f04e5a0466f617593800b3ca9d7751a43a82bdf2abde51a5f85acd5eaff6fab963909a3a702ce7eac292b07f84942e73cfb692d05c532d8488fd09d92df3081fb36d4237437687f0ddb1c974b06485f916b8b1f22b0c6ef2ca2d30ceb384110d5fb610128f29bf91d1a8dd14d3f9f4d65610825d6588fa0df7caabe4b488ca17dd141cb29c7f6402d3728d14a6d3f"
        let resultList = try BackupManager.shared.decryptHexString(string)
        XCTAssert(!resultList.isEmpty)
    }

    func testMnemonicEncryptAndDecrypt() throws {
        let wallet = HDWallet(strength: WalletManager.mnemonicStrength, passphrase: "")
        guard let mnemonic = wallet?.mnemonic, !mnemonic.isEmpty,
              let mnemonicData = mnemonic.data(using: .utf8)
        else {
            XCTAssert(false)
            return
        }

        let pwd = "12345678"
        let hexString = try BackupManager.shared.encryptMnemonic(mnemonicData, password: pwd)

        let decryptMnemonic = try BackupManager.shared.decryptMnemonic(hexString, password: pwd)
        XCTAssert(decryptMnemonic == mnemonic)
    }

    func testMnemonicDecryptWithWrongPassword() throws {
        let wallet = HDWallet(strength: WalletManager.mnemonicStrength, passphrase: "")
        guard let mnemonic = wallet?.mnemonic, !mnemonic.isEmpty,
              let mnemonicData = mnemonic.data(using: .utf8)
        else {
            XCTAssert(false)
            return
        }

        let pwd = "12345678"
        let hexString = try BackupManager.shared.encryptMnemonic(mnemonicData, password: pwd)

        let wrongPwd = "12345670"
        XCTAssertThrowsError(try BackupManager.shared.decryptMnemonic(
            hexString,
            password: wrongPwd
        ))
    }
}
