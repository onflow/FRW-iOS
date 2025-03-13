//
//  BalanceProvider.swift
//  FRW
//
//  Created by cat on 2024/5/31.
//

import Flow
import Foundation

@available(*, deprecated, renamed: "TokenBalanceProvider", message: "")
class BalanceProvider: ObservableObject {
    // MARK: Internal

    @Published
    var balances: [String: String] = [:]

    func refreshBalance() {
        Task {
            await fetchFlowFlowBalance()
            await fetchEVMFlowBalance()
            await fetchChildBalance()
        }
    }

    func balanceValue(at address: String) -> String? {
        guard let value = balances[address] else {
            return nil
        }
        return value
    }

    // MARK: Private

    private func fetchFlowFlowBalance() async {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }
        do {
            let balanceList = try await FlowNetwork.fetchBalance(at: Flow.Address(hex: address))
            guard let model = balanceList
                .first(where: { $0.key.lowercased().hasSuffix(".FlowToken".lowercased()) })
            else {
                return
            }
            balances[address] = model.value.formatCurrencyString()
        } catch {
            log.error("[Balance] fetch Flow flow balance :\(error)")
        }
    }

    private func fetchChildBalance() async {
        do {
            for model in ChildAccountManager.shared.childAccounts {
                if let address = model.addr {
                    let balanceList = try await FlowNetwork
                        .fetchBalance(at: Flow.Address(hex: address))
                    guard let model = balanceList
                        .first(where: { $0.key.lowercased().hasSuffix("FlowToken".lowercased()) })
                    else {
                        return
                    }
                    balances[address] = model.value.formatCurrencyString()
                }
            }
        } catch {
            log.error("[Balance] fetch Flow flow balance :\(error)")
        }
    }

    private func fetchEVMFlowBalance() async {
        do {
            guard let evmAccount = EVMAccountManager.shared.accounts.first else { return }
            try await EVMAccountManager.shared.refreshBalance(address: evmAccount.address)
            let balance = EVMAccountManager.shared.balance
            balances[evmAccount.showAddress] = balance.doubleValue.formatCurrencyString()
        } catch {
            log.error("[Balance] fetch EVM flow balance :\(error)")
        }
    }
}
