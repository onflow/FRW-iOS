//
//  KeyStoreLoginViewModel.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import Foundation
import WalletCore
import Web3Core

import Flow
import FlowWalletKit
import SwiftUI

// MARK: - KeyStoreLoginViewModel

final class KeyStoreLoginViewModel: ObservableObject {
    // MARK: Internal

    @Published
    var json: String = ""
    @Published
    var password: String = ""
    @Published
    var wantedAddress: String = ""

    @Published
    var buttonState: VPrimaryButtonState = .disabled

    var userName: String = ""

    @Published
    var wallet: FlowWalletKit.Wallet? = nil

    @MainActor
    func update(json _: String) {
        update()
    }

    @MainActor
    func update(password _: String) {
        update()
    }

    func update(address _: String) {}

    func onSumbit() {
        UIApplication.shared.endEditing()
        HUD.loading()
        Task {
            do {
                privateKey = try PrivateKey.restore(
                    json: json,
                    password: password,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )
                guard let privateKey else {
                    HUD.error(title: "invalid_data".localized)
                    return
                }
                let wallet = FlowWalletKit.Wallet(type: .key(privateKey))
                HUD.loading()
                _ = try await wallet.fetchAllNetworkAccounts()
                HUD.dismissLoading()

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

                let viewModel = ImportProfileViewModel(list: validAccount, keyProvider: privateKey)
                Router.route(to: RouteMap.RestoreLogin.importProfile(viewModel))

            } catch let error as FlowWalletKit.FWKError {
                if error == FlowWalletKit.FWKError.invaildKeyStorePassword {
                    HUD.error(title: "invalid_password".localized)
                } else if error == FlowWalletKit.FWKError.invaildKeyStoreJSON {
                    HUD.error(title: "invalid_json".localized)
                } else {
                    HUD.error(title: "invalid_data".localized)
                }
                HUD.dismissLoading()
            } catch {
                HUD.error(title: "invalid_data".localized)
                HUD.dismissLoading()
            }
        }
    }

    // MARK: Private

    private var privateKey: FlowWalletKit.PrivateKey?

    @MainActor
    private func update() {
        updateButtonState()
    }

    private func updateButtonState() {
        buttonState = (json.isEmpty || password.isEmpty) ? .disabled : .enabled
    }
}
