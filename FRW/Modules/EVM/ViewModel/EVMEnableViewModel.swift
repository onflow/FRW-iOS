//
//  EVMEnableViewModel.swift
//  FRW
//
//  Created by cat on 2024/2/26.
//

import SwiftUI

class EVMEnableViewModel: ObservableObject {
    @Published
    var state: VPrimaryButtonState = .enabled

    func onSkip() {
        Router.pop()
    }

    func onClickEnable() {
        let minBalance = 0.000
        let result = WalletManager.shared.activatedCoins.filter { tokenModel in

            if tokenModel.isFlowCoin {
                let balance = WalletManager.shared.getBalance(with: tokenModel)
                log.debug("[EVM] enable check balance: \(balance)")
                return balance.doubleValue >= minBalance
            }
            return false
        }
        guard result.count == 1 else {
            HUD.error(title: "", message: "evm_check_balance".localized)
            return
        }

        Task {
            do {
                state = .loading
                try await EVMAccountManager.shared.enableEVM()
                await EVMAccountManager.shared.refreshSync()
                if let address = EVMAccountManager.shared.accounts.first?.showAddress {
                    WalletManager.shared.changeSelectedAccount(address: address, type: .coa)
                }
                state = .enabled
                Router.pop()
                ConfettiManager.show()
            } catch {
                state = .enabled
                HUD.error(title: "Enable EVM failed.")
                log.error("Enable EVM failer: \(error)")
            }
        }
    }

    func onClickLearnMore() {
        let evmUrl = "https://flow.com/upgrade/crescendo/evm"
        guard let url = URL(string: evmUrl) else { return }
        UIApplication.shared.open(url)
    }
}
