//
//  ImportProfileViewModel.swift
//  FRW
//
//  Created by cat on 6/7/25.
//

import Flow
import FlowWalletKit
import Foundation

class ImportProfileViewModel: ObservableObject {
    let list: [FlowWalletKit.Account]
    let keyProvider: any FlowWalletKit.KeyProtocol
    @Published var accounts: [[AccountModel]] = []
    @Published var hideAccount: [String] = []

    init(list: [FlowWalletKit.Account], keyProvider: any FlowWalletKit.KeyProtocol) {
        self.list = list
        accounts = list.map { AccountFetcher.regroup(account: $0, with: [:]) }
        self.keyProvider = keyProvider
        hideAccount = hideAccount
    }

    func isCheck(_ account: AccountModel) -> Bool {
        !hideAccount.contains(account.account.infoAddress.lowercased())
    }

    func onClick(_ account: AccountModel) {
        let address = account.account.infoAddress.lowercased()
        if hideAccount.contains(address) {
            hideAccount.removeAll { $0 == address }
        } else {
            hideAccount.append(address)
        }
    }

    func fetchInfo() async {
        let fetcher = AccountFetcher()
        let result = try? await fetcher.fetchAccountInfo(list)
        if let result {
            await MainActor.run {
                self.accounts = result
            }
        }
    }

    func onImportAccount() {
        let filterAccount = list.filter { account in
            !hideAccount.contains(account.address.hexAddr.lowercased())
        }
        guard filterAccount.count > 0 else {
            return
        }
        startImport(validAccount: filterAccount)
    }
}

extension ImportProfileViewModel {
    fileprivate func startImport(validAccount: [FlowWalletKit.Account]) {
        /*

         */
        let filterAccount = validAccount
        var validKey: Flow.AccountKey?
        for account in filterAccount {
            for key in account.account.keys {
                if isValidKey(key: key) {
                    validKey = key
                    break
                }
            }
        }
        guard let selectedKey = validKey, let address = filterAccount.first?.address.hexAddr else {
            let tmpKey = list.first?.account.keys.first?.publicKey.description ?? "empty"
            log.error("not found valid key in \(tmpKey)")
            return
        }

        Task {
            HUD.loading()
            do {
                let publicKeyStr = selectedKey.publicKey.description
                let response: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.User.checkimport(publicKeyStr))
                HUD.dismissLoading()
                if response.httpCode == 200 {
                    createUserName { [weak self] name in
                        guard let self = self else {
                            HUD.dismissLoading()
                            return
                        }
                        Task {
                            do {
                                HUD.loading()
                                try await UserManager.shared.importLogin(
                                    by: address,
                                    userName: name,
                                    flowKey: selectedKey,
                                    privateKey: self.keyProvider,
                                    isImport: true
                                )
                                HUD.dismissLoading()
                                Router.popToRoot()
                            } catch {
                                HUD.dismissLoading()
                                log.error(error)
                            }
                        }
                    }
                } else {
                    HUD.dismissLoading()
                    log.error("import account failed. \(response.httpCode):\(response.message)")
                }

            } catch {
                if let code = error.moyaCode(), code == 409 {
                    do {
                        try await UserManager.shared.importLogin(
                            by: address,
                            userName: "",
                            flowKey: selectedKey,
                            privateKey: keyProvider
                        )
                        HUD.dismissLoading()
                        Router.popToRoot()
                    } catch {
                        HUD.dismissLoading()
                        log.error("[Import] login 409 :\(error)")
                    }
                } else {
                    HUD.dismissLoading()
                    log.error("[Import] check public key own error:\(error)")
                }
            }
        }
    }

    func createUserName(callback: @escaping (String) -> Void) {
        let viewModel = ImportUserNameViewModel { name in
            if !name.isEmpty {
                callback(name)
            }
        }
        Router.route(to: RouteMap.RestoreLogin.importUserName(viewModel))
    }

    private func isValidKey(key: Flow.AccountKey) -> Bool {
        let publicKey = key.publicKey.description
        let result = (publicKey == keyProvider.p256PublicKey || publicKey == keyProvider.secp256PublicKey)
        return result
    }
}

private extension FlowWalletKit.KeyProtocol {
    var p256PublicKey: String? {
        publicKey(signAlgo: .ECDSA_P256)?.hexValue
    }

    var secp256PublicKey: String? {
        publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue
    }
}
