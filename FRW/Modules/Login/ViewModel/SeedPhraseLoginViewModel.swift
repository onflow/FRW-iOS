//
//  SeedPhraseLoginViewModel.swift
//  FRW
//
//  Refactored version using LoginViewModelProtocol
//  Created by cat on 2024/12/28.
//

import Flow
import FlowWalletKit
import Foundation
import UIKit
import WalletCore

// MARK: - SeedPhraseLoginViewModel

final class SeedPhraseLoginViewModel: ObservableObject, LoginViewModelProtocol {
    // MARK: - LoginViewModelProtocol Required Properties

    typealias KeyType = FlowWalletKit.SeedPhraseKey

    @Published var wantedAddress: String = ""
    @Published var buttonState: VPrimaryButtonState = .disabled
    var wallet: FlowWalletKit.Wallet? = nil
    var cryptoKey: FlowWalletKit.SeedPhraseKey?
    var account: Flow.Account? = nil

    // MARK: - Specific Properties

    @Published var words: String = ""
    @Published var derivationPath: String = ""
    @Published var passphrase: String = ""
    @Published var isAdvanced: Bool = false
    @Published var suggestions: [String] = []
    @Published var hasError: Bool = false

    // MARK: - UI Update Methods

    func updateWords(_ text: String) {
        let original = text.condenseWhitespace()
        let words = original.split(separator: " ")
        hasError = false

        // Validate each word
        for word in words {
            if Mnemonic.search(prefix: String(word)).isEmpty {
                hasError = true
                break
            }
        }

        let valid = Mnemonic.isValid(mnemonic: original)

        // Update suggestions
        if text.last == " " || valid {
            suggestions = []
        } else {
            suggestions = Mnemonic.search(prefix: String(words.last ?? ""))
        }

        updateState()
    }

    func updateState() {
        if isAdvanced {
            buttonState = words.isEmpty || derivationPath.isEmpty ? .disabled : .enabled
        } else {
            buttonState = words.isEmpty ? .disabled : .enabled
        }
    }

    func onAdvance() {
        isAdvanced.toggle()
        updateState()
    }

    // MARK: - LoginViewModelProtocol Required Methods

    func onSubmit() {
        UIApplication.shared.endEditing()

        let rawMnemonic = words.condenseWhitespace()

        Task {
            // Validate HD wallet
            guard let hdWallet = HDWallet(mnemonic: rawMnemonic, passphrase: passphrase) else {
                HUD.error(title: "invalid_data".localized)
                return
            }

            // Validate advanced options
            if isAdvanced && derivationPath.isEmpty {
                HUD.error(title: "required_info_not".localized)
                return
            }

            // Create seed phrase key
            if isAdvanced && !derivationPath.isEmpty {
                cryptoKey = FlowWalletKit.SeedPhraseKey(
                    hdWallet: hdWallet,
                    storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage,
                    derivationPath: derivationPath,
                    passphrase: passphrase
                )
            } else {
                cryptoKey = FlowWalletKit.SeedPhraseKey(
                    hdWallet: hdWallet,
                    storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage
                )
            }

            guard cryptoKey != nil else {
                HUD.error(title: "invalid_data".localized)
                return
            }

            // Create wallet with seed phrase key
            wallet = FlowWalletKit.Wallet(
                type: .key(cryptoKey!),
                networks: [currentNetwork]
            )

            HUD.loading()

            // Fetch all addresses (common logic from protocol)
            try await fetchAllAddresses()

            HUD.dismissLoading()

            // Select account (common logic from protocol)
            selectAccountFromWallet()
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
        guard let seedPhraseKey = cryptoKey else {
            throw LoginError.missingKey
        }

        try await UserManager.shared.importLogin(
            by: address,
            userName: userName,
            flowKey: flowKey,
            privateKey: seedPhraseKey,
            isImport: isImport
        )
    }
}
