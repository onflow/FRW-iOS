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
            do {
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
                let wallet = FlowWalletKit.Wallet(type: .key(providerKey), networks: [chainId])
                HUD.loading()
                _ = try await wallet.fetchAllNetworkAccounts()
                HUD.dismissLoading()

                // TODO: #six testnet
                let chainId = currentNetwork
                let list = wallet.accounts?[chainId] ?? []
                var validAccount = list.filter { account in
                    let result = account.account.keys.filter { key in
                        key.weight >= 1000 && !key.revoked
                    }.count
                    return result > 0
                }

                if !wantedAddress.isEmpty {
                    validAccount = validAccount.filter { $0.hexAddr == wantedAddress }
                }
                guard validAccount.count > 0 else {
                    log.info("not_find_address".localized)
                    HUD.info(title: "not_find_address".localized)
                    return
                }

                let viewModel = ImportProfileViewModel(list: validAccount, keyProvider: providerKey)
                Router.route(to: RouteMap.RestoreLogin.importProfile(viewModel))
            } catch {
                log.error(error)
                HUD.error(title: "import_profile".localized, message: "import_profile_error".localized)
            }
        }
    }

    func onAdvance() {
        isAdvanced.toggle()
    }

    // MARK: Private

    private var providerKey: FlowWalletKit.SeedPhraseKey?
}
