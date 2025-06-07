//
//  PrivateKeyLoginViewModel.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import CryptoKit
import Flow
import FlowWalletKit
import Foundation
import UIKit
import WalletCore

// MARK: - PrivateKeyLoginViewModel

final class PrivateKeyLoginViewModel: ObservableObject {
    // MARK: Internal

    @Published
    var key: String = ""
    @Published
    var wantedAddress: String = ""
    @Published
    var buttonState: VPrimaryButtonState = .disabled

    var userName: String = ""

    var wallet: FlowWalletKit.Wallet? = nil

    @MainActor
    func update(key _: String) {
        update()
    }

    @MainActor
    func update(address _: String) {
        update()
    }

    func onSumbit() {
        UIApplication.shared.endEditing()
        HUD.loading()
        Task {
            do {
                guard let data = Data(hexString: key.stripHexPrefix()) else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }

                privateKey = try PrivateKey.restore(
                    secret: data,
                    storage: FlowWalletKit.PrivateKey.PKStorage
                )
                guard let privateKey = privateKey else {
                    HUD.dismissLoading()
                    HUD.error(title: "invalid_data".localized)
                    return
                }

                let wallet = FlowWalletKit.Wallet(type: .key(privateKey))

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

            } catch {
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
        buttonState = (key.isEmpty) ? .disabled : .enabled
    }
}
