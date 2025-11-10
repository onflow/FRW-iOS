//
//  KeyStoreLoginViewModel.swift
//  FRW
//
//  Refactored version using LoginViewModelProtocol
//  Created by cat on 2024/12/28.
//

import Flow
import FlowWalletKit
import Foundation
import SwiftUI
import WalletCore
import Web3Core

// MARK: - KeyStoreLoginViewModel

final class KeyStoreLoginViewModel: ObservableObject, LoginViewModelProtocol {
    // MARK: - LoginViewModelProtocol Required Properties

    typealias KeyType = FlowWalletKit.PrivateKey

    @Published var wantedAddress: String = ""
    @Published var buttonState: VPrimaryButtonState = .disabled
    @Published var wallet: FlowWalletKit.Wallet? = nil
    var cryptoKey: FlowWalletKit.PrivateKey?
    var account: Flow.Account? = nil

    // MARK: - Specific Properties

    @Published var json: String = ""
    @Published var password: String = ""
    var userName: String = ""

    // MARK: - UI Update Methods

    @MainActor
    func update(json _: String) {
        update()
    }

    @MainActor
    func update(password _: String) {
        update()
    }

    func update(address _: String) {}

    @MainActor
    private func update() {
        updateButtonState()
    }

    private func updateButtonState() {
        buttonState = (json.isEmpty || password.isEmpty) ? .disabled : .enabled
    }

    // MARK: - LoginViewModelProtocol Required Methods

    func onSubmit() {
        UIApplication.shared.endEditing()
        HUD.loading()

        Task {
            do {
                // Restore private key from keystore JSON
                cryptoKey = try PrivateKey.restore(
                    json: json,
                    password: password,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )

                guard cryptoKey != nil else {
                    HUD.error(title: "invalid_data".localized)
                    HUD.dismissLoading()
                    return
                }

                // Create wallet with restored key
                wallet = FlowWalletKit.Wallet(type: .key(cryptoKey!))

                // Fetch all addresses (common logic from protocol)
                try await fetchAllAddresses()

                HUD.dismissLoading()

                // Select account (common logic from protocol)
                selectAccountFromWallet()

            } catch let error as FlowWalletKit.FWKError {
                handleFWKError(error)
                HUD.dismissLoading()
            } catch {
                HUD.error(title: "invalid_data".localized)
                HUD.dismissLoading()
            }
        }
    }

    func getP256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_P256)?.hexValue
    }

    func getSecp256PublicKey() -> String? {
        cryptoKey?.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue
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

    // MARK: - Error Handling

    private func handleFWKError(_ error: FlowWalletKit.FWKError) {
        switch error {
        case .invaildKeyStorePassword:
            HUD.error(title: "invalid_password".localized)
        case .invaildKeyStoreJSON:
            HUD.error(title: "invalid_json".localized)
        default:
            HUD.error(title: "invalid_data".localized)
        }
    }
}
