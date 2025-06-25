//
//  ConfirmFromMultiBackupViewModel.swift
//  FRW
//
//  Created by cat on 6/26/25.
//

import Foundation

// RestoreMultiAccountViewModel
final class ConfirmFromMultiBackupViewModel: ObservableObject {
    var items: [[MultiBackupManager.StoreItem]]
    @Published var accounts: [AccountModel] = []
    @Published var hideAccount: [String] = []

    init(items: [[MultiBackupManager.StoreItem]]) {
        self.items = items
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
//        let fetcher = AccountFetcher()
//        let result = try? await fetcher.fetchAccountInfo(list)
//        if let result {
//            await MainActor.run {
//                self.accounts = result
//            }
//        }
    }

    func onImportAccount() {
//        let filterAccount = list.filter { account in
//            !hideAccount.contains(account.address.hexAddr.lowercased())
//        }
//        guard filterAccount.count > 0 else {
//            return
//        }
//        startImport(validAccount: filterAccount)
    }
}
