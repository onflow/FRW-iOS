//
//  TurboModule+Onboard.swift
//  FRW
//
//  Created by cat on 12/11/25.
//

import Foundation
import FlowWalletKit
import WalletCore
import Flow
import UserNotifications
import FirebaseAuth
import Firebase

extension TurboModuleSwift {
  @objc
  static func generateSeedPhrase(strength: NSNumber?) async throws -> [String: Any] {

    let mnemonicStrength = strength?.int32Value ?? 128
    guard let hdWallet = HDWallet(strength: mnemonicStrength, passphrase: "") else {
        HUD.error(title: "invalid_data".localized)
      throw RNBridgeError.mnemonicGenerationFailed
    }

    let key = FlowWalletKit.SeedPhraseKey(hdWallet: hdWallet, storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage)

    guard let publicKey = key.publicKey(signAlgo: .ECDSA_SECP256k1) else {
      throw RNBridgeError.accountCreationFailed
    }
    let publicKeyHex = publicKey.hexString
    let accountKey = RNBridge.AccountKey(
      publicKey: publicKeyHex,
      hashAlgoStr: Flow.HashAlgorithm.SHA2_256.id,
      signAlgoStr: Flow.SignatureAlgorithm.ECDSA_SECP256k1.id,
      weight: 1000,
      hashAlgo: Flow.HashAlgorithm.SHA2_256.index,
      signAlgo: Flow.SignatureAlgorithm.ECDSA_SECP256k1.index
    )

    let response = RNBridge.SeedPhraseGenerationResponse(
      mnemonic: hdWallet.mnemonic,
      accountKey: accountKey,
      drivepath: FlowWalletKit.SeedPhraseKey.derivationPath
    )

    return try response.toDictionary()
  }

  @objc
  static func registerSecureTypeAccount(username: String) async throws -> [String: Any] {
    print("TurboModuleSwift: registerSecureTypeAccount called")
    do {
      let result = try await UserManager.shared.register(username)
      guard let txid = result else {
        throw RNBridgeError.accountCreationFailed
      }
      let response = RNBridge.CreateAccountResponse(
        success: true,
        address: "",
        username: username,
        accountType: .hardware,
        txId: txid,
        error: ""
      )

      return try response.toDictionary()
    } catch {
      let response = RNBridge.CreateAccountResponse(
        success: false,
        address: "",
        username: username,
        accountType: .hardware,
        txId: "",
        error: error.localizedDescription
      )
      return try response.toDictionary()
    }
  }

  @objc
  static func initSecureEnclaveWallet(txId: String) async throws -> [String: Any] {
    print("TurboModuleSwift: initSecureEnclaveWallet called")
    guard let uid = UserManager.shared.RNRegisterInfo[txId] else {
      return [
        "success": false,
        "address": "",
        "error": "Secure Enclave wallet initialization not yet implemented in WalletManager"
      ]
    }
    let result = await WalletManager.shared.keyProvider(with: uid)?.keyType == .secureEnclave
    let address = await WalletManager.shared.getPrimaryWalletAddress() ?? ""
    return [
      "success": result,
      "address": result ? address : "",
      "error": ""
    ]
  }

  @objc
  static func signInWithCustomToken(customToken: String) async throws {
    print("TurboModuleSwift: signInWithCustomToken called")
    try await Auth.auth().signIn(withCustomToken: customToken)
  }

  @objc
  static func saveMnemonic(mnemonic: String, customToken: String, txId: String, username: String) async throws {
    print("TurboModuleSwift: saveMnemonic called")
    try await UserManager.shared.restoreLogin(withMnemonic: mnemonic)

  }

  // MARK: - Screen Security
  @objc
  static func setScreenSecurityLevel(level: String) {
    print("TurboModuleSwift: setScreenSecurityLevel called")
    log.info("Screen Security level:\(level)")
    switch level {
    case "secure":
      break
    default:
      break
    }

  }

  // MARK: - Notification Permissions
  @objc
  static func requestNotificationPermission() async throws -> Bool {
    print("TurboModuleSwift: requestNotificationPermission called")
    return await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        continuation.resume(returning: granted)
      }
    }
  }

  @objc
  static func checkNotificationPermission() async throws -> Bool {
    print("TurboModuleSwift: checkNotificationPermission called")
    return await withCheckedContinuation { continuation in
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        let granted = settings.authorizationStatus == .authorized
        print("TurboModuleSwift: result: \(granted)")
        continuation.resume(returning: granted)
      }
    }
  }

  // MARK: - Device Info
  @objc
  static func getDeviceId() -> String {
    print("TurboModuleSwift: getDeviceId called")
    return UUIDManager.appUUID()
  }

}
