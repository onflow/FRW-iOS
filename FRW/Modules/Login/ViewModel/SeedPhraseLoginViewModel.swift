//
//  SeedPhraseLoginViewModel.swift
//  FRW
//
//  Created by cat on 2024/9/27.
//

import Flow
import FlowWalletKit
import Foundation
import UIKit
import WalletCore

// MARK: - SeedPhraseLoginViewModel

final class SeedPhraseLoginViewModel: ObservableObject {
    // MARK: Internal

    @Published
    var words: String = ""
    @Published
    var wantedAddress: String = ""
    @Published
    var derivationPath: String = ""
    @Published
    var passphrase: String = ""

    @Published
    var buttonState: VPrimaryButtonState = .disabled
    @Published
    var isAdvanced: Bool = false

    @Published var suggestions: [String] = []
    @Published var hasError: Bool = false

    func updateWords(_ text: String) {
        let original = text.condenseWhitespace()
        let words = original.split(separator: " ")
        hasError = false
        for word in words {
            if Mnemonic.search(prefix: String(word)).isEmpty {
                hasError = true
                break
            }
        }

        let valid = Mnemonic.isValid(mnemonic: original)

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

    func onSubmit() {
        UIApplication.shared.endEditing()
        let chainId = currentNetwork
        let rawMnemonic = words.condenseWhitespace()
        Task {
            guard let hdWallet = HDWallet(mnemonic: rawMnemonic, passphrase: passphrase) else {
                HUD.error(title: "invalid_data".localized)
                return
            }
            if isAdvanced && derivationPath.isEmpty {
                HUD.error(title: "required_info_not".localized)
                return
            }
            if isAdvanced && !derivationPath.isEmpty {
                providerKey = FlowWalletKit.SeedPhraseKey(
                    hdWallet: hdWallet,
                    storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage,
                    derivationPath: derivationPath,
                    passphrase: passphrase
                )
            } else {
                providerKey = FlowWalletKit.SeedPhraseKey(
                    hdWallet: hdWallet,
                    storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage
                )
            }
            guard let providerKey = providerKey else {
                return
            }
            wallet = FlowWalletKit.Wallet(type: .key(providerKey), networks: [chainId])
            HUD.loading()
            try await fetchAllAddresses()
            HUD.dismissLoading()
            if wantedAddress.isEmpty {
                await self.showAllAccounts()
            } else {
                let chainId = currentNetwork
                guard let keys = wallet?.flowAccounts?[chainId] else {
                    return
                }
                guard let account = keys.filter({ $0.address.hex == wantedAddress }).first else {
                    HUD.error(title: "not_find_address".localized)
                    return
                }
                selectedAccount(by: account)
            }
        }
    }

    // fetch all addresses of Public Key
    func fetchAllAddresses() async throws {
        do {
            _ = try await wallet?.fetchAllNetworkAccounts()
        } catch {
            log.error("\(error.localizedDescription)")
        }
    }

    func selectedAccount(by account: Flow.Account) {
        self.account = account
        checkPublicKey()
    }

    func createUserName(callback: @escaping (String) -> Void) {
        let viewModel = ImportUserNameViewModel { name in
            if !name.isEmpty {
                callback(name)
            }
        }
        Router.route(to: RouteMap.RestoreLogin.importUserName(viewModel))
    }

    func checkPublicKey() {
        let keys = account?.keys.filter {
            $0.publicKey.description == p256PublicKey || $0.publicKey
                .description == secp256PublicKey
        }
        guard let selectedKey = keys?.first,
              let address = account?.address.hex, let privateKey = providerKey
        else {
            log.error("[Import] keys of account not match the public:\(String(describing: p256PublicKey)) or \(String(describing: secp256PublicKey))")
            return
        }
        guard selectedKey.weight >= 1000 else {
            HUD.error(title: "account_key_weight_less".localized)
            return
        }
        guard !selectedKey.revoked else {
            HUD.error(title: "account_key_done_revoked_tips".localized)
            return
        }
        Task {
            HUD.loading()
            do {
                let publicKey = selectedKey.publicKey.description
                let response: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.User.checkimport(publicKey))
                if response.httpCode == 409 {
                    try await UserManager.shared.importLogin(
                        by: address,
                        userName: "",
                        flowKey: selectedKey,
                        privateKey: privateKey
                    )
                    HUD.dismissLoading()
                    Router.popToRoot()
                } else if response.httpCode == 200 {
                    HUD.dismissLoading()
                    createUserName { name in
                        Task {
                            HUD.loading()
                            try await UserManager.shared.importLogin(
                                by: address,
                                userName: name,
                                flowKey: selectedKey,
                                privateKey: privateKey,
                                isImport: true
                            )
                            HUD.dismissLoading()
                            Router.popToRoot()
                        }
                    }
                }
            } catch {
                if let code = error.moyaCode() {
                    if code == 409 {
                        do {
                            HUD.loading()
                            try await UserManager.shared.importLogin(
                                by: address,
                                userName: "",
                                flowKey: selectedKey,
                                privateKey: privateKey
                            )
                            HUD.dismissLoading()
                            Router.popToRoot()
                        } catch {
                            log.error("[Import] login 409 :\(error)")
                        }
                    }
                }
                log.error("[Import] check public key own error:\(error)")
            }
        }
    }

    func onAdvance() {
        isAdvanced.toggle()
    }

    // MARK: Private

    private var providerKey: FlowWalletKit.SeedPhraseKey?
    private var wallet: FlowWalletKit.Wallet? = nil
    private var account: Flow.Account? = nil

    // select one address
    @MainActor
    private func showAllAccounts() {
        let chainId = currentNetwork
        let list = wallet?.flowAccounts?[chainId] ?? []

        let viewModel = ImportAccountsViewModel(list: list) { [weak self] account in
            log.info("[Import] selected address: \(account.address.hex)")
            self?.selectedAccount(by: account)
        }
        Router.route(to: RouteMap.RestoreLogin.importAddress(viewModel))
    }
}

extension SeedPhraseLoginViewModel {
    private var p256PublicKey: String? {
        (try? providerKey?.publicKey(signAlgo: .ECDSA_P256))?.hexValue.dropPrefix("04")
    }

    private var secp256PublicKey: String? {
        (try? providerKey?.publicKey(signAlgo: .ECDSA_SECP256k1))?.hexValue.dropPrefix("04")
    }
}
