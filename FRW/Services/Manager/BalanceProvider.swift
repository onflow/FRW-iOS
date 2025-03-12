//
//  BalanceProvider.swift
//  FRW
//
//  Created by cat on 2024/5/31.
//

import Flow
import Foundation

class BalanceProvider: ObservableObject {
    // MARK: Internal

    @Published
    var balances: [String: String] = [:]

    func refreshBalance() {
        Task {
            var list: [String] = []
            if let primaryAddress = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress() {
                list.append(primaryAddress)
            }
            let child = ChildAccountManager.shared.childAccounts.compactMap { $0.addr }
            list.append(contentsOf: child)
            let coa = EVMAccountManager.shared.accounts.compactMap { $0.address }
            list.append(contentsOf: coa)
            do {
                let result = try await FlowNetwork.getFlowBalanceForAnyAccount(address: list)
                await MainActor.run {
                    self.balances = result.compactMapValues { $0?.formatCurrencyString() }
                    log.debug(self.balances)
                }
            } catch {
                log.error(error)
            }
        }
    }

    func balanceValue(at address: String) -> String? {
        guard let value = balances[address] else {
            return nil
        }
        return value
    }
}
