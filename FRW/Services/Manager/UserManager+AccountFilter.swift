//
//  UserManager+AccountFilter.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import FlowWalletKit
import Foundation
import SwiftUI

class AccountFilter {
    private let filterAccountsKey = LocalUserDefaults.Keys.filterAccount.rawValue

    @Published var filterAccounts: [String: [String]] = [:]

    init() {
        filterAccounts = loadFilterAccounts()
    }

    private func loadFilterAccounts() -> [String: [String]] {
        guard let data = UserDefaults.standard.data(forKey: filterAccountsKey) else { return [:] }
        if let dict = try? JSONDecoder().decode([String: [String]].self, from: data) {
            return dict
        }
        return [:]
    }

    private func saveFilterAccounts() {
        if let data = try? JSONEncoder().encode(filterAccounts) {
            UserDefaults.standard.set(data, forKey: filterAccountsKey)
        }
    }
}

extension AccountFilter {
    func inFilter(with account: FlowWalletKit.Account) -> Bool {
        guard let key = account.fullWeightKey?.publicKey.hex.prefix(8) else {
            return false
        }
        let address = account.hexAddr
        let publicKey = String(key)
        return filterAccounts[publicKey]?.contains(address.lowercased()) ?? false
    }

    func addFilter(with account: FlowWalletKit.Account) {
        let address = account.hexAddr
        guard let currentAddr = WalletManager.shared.selectedAccountAddress, address.lowercased() != currentAddr.lowercased() else {
            return
        }
        guard let key = account.fullWeightKey?.publicKey.hex.prefix(8) else {
            return
        }
        let publicKey = String(key)
        var list = filterAccounts[publicKey] ?? []
        if !list.contains(address.lowercased()) {
            list.append(address.lowercased())
            filterAccounts[publicKey] = list
        }
        saveFilterAccounts()
    }

    func removeFilter(with account: FlowWalletKit.Account) {
        let address = account.hexAddr
        guard let key = account.fullWeightKey?.publicKey.hex.prefix(8) else {
            return
        }
        let publicKey = String(key)
        var list = filterAccounts[publicKey] ?? []
        list.removeAll { $0 == address.lowercased() }
        filterAccounts[publicKey] = list
        saveFilterAccounts()
    }
}
