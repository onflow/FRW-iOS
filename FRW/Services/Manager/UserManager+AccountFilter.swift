//
//  UserManager+AccountFilter.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import Foundation
import SwiftUI

class AccountFilter {
    private let filterAccountsKey = LocalUserDefaults.Keys.filterAccount.rawValue
    var filterAccounts: [String: [String]] = [:]

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
    var currentFilter: [String] {
        guard let uid = UserManager.shared.activatedUID else {
            return []
        }
        return filterAccounts[uid] ?? []
    }

    func inFilter(address: String) -> Bool {
        currentFilter.contains(address.lowercased())
    }

    func addFilter(uid: String, address: String) {
        guard let currentAddr = WalletManager.shared.selectedAccountAddress, address.lowercased() != currentAddr.lowercased() else {
            return
        }
        var list = filterAccounts[uid] ?? []
        if !list.contains(address.lowercased()) {
            list.append(address.lowercased())
            filterAccounts[uid] = list
        }
        saveFilterAccounts()
    }

    func removeFilter(uid: String, address: String) {
        var list = filterAccounts[uid] ?? []
        list.removeAll { $0 == address.lowercased() }
        filterAccounts[uid] = list
        saveFilterAccounts()
    }
}
