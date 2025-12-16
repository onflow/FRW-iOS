//
//  PrivateKeyLoginViewModel.swift
//  FRW
//
//  Refactored version using LoginViewModelProtocol
//  Created by cat on 2024/12/28.
//

import CryptoKit
import Flow
import FlowWalletKit
import Foundation
import UIKit
import WalletCore

// MARK: - PrivateKeyLoginViewModel

final class PrivateKeyLoginViewModel: ObservableObject, LoginViewModelProtocol {
    // MARK: - LoginViewModelProtocol Required Properties

    typealias KeyType = FlowWalletKit.PrivateKey

    @Published var wantedAddress: String = ""
    @Published var buttonState: VPrimaryButtonState = .disabled
    var wallet: FlowWalletKit.Wallet? = nil
    var cryptoKey: FlowWalletKit.PrivateKey?
    var account: Flow.Account? = nil

    // MARK: - Specific Properties

    @Published var key: String = ""
    var userName: String = ""

    // MARK: - Initialization

    init() {
        // Setup any initial state
    }

    // MARK: - UI Update Methods

    @MainActor
    func update(key _: String) {
        update()
    }

    @MainActor
    func update(address _: String) {
        update()
    }

    @MainActor
    private func update() {
        updateButtonState()
    }

    private func updateButtonState() {
        buttonState = key.isEmpty ? .disabled : .enabled
    }

    // MARK: - LoginViewModelProtocol Required Methods

    func onSubmit() {
        UIApplication.shared.endEditing()
        HUD.loading()

        Task {
            do {
                // Restore private key from hex string
                guard let data = Data(hexString: key.stripHexPrefix()) else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }

                cryptoKey = try PrivateKey.restore(
                    secret: data,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )

                guard cryptoKey != nil else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }

                // Create wallet with restored key
                wallet = FlowWalletKit.Wallet(type: .key(cryptoKey!))

                // Fetch all addresses (common logic from protocol)
                try await fetchAllAddresses()

                HUD.dismissLoading()

                // Select account (common logic from protocol)
                selectAccountFromWallet()

            } catch {
                HUD.dismissLoading()
                HUD.error(title: "invalid_data".localized)
            }
        }
    }

    func getP256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_P256)?.hexValue.format()
    }

    func getSecp256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue.format()
    }

    func performLogin(
        address: String,
        userName: String,
        flowKey: Flow.AccountKey,
        isImport: Bool
    ) async throws {
        guard let privateKey = cryptoKey else {
            throw LoginError.missingKey
        }

        try await UserManager.shared.importLogin(
            by: address,
            userName: userName,
            flowKey: flowKey,
            privateKey: privateKey,
            isImport: isImport
        )
    }
}

// MARK: - LoginError

enum LoginError: Error {
    case missingKey
    case invalidData
}
