//
//  AccountListViewModel.swift
//  FRW
//
//  Created by cat on 6/10/25.
//

import Combine
import Foundation

class AccountListViewModel: ObservableObject {
    @Published var isUpdateFlag = false

    private var cancellableSet = Set<AnyCancellable>()

    init() {
        WalletManager.shared.$walletAccount
            .compactMap { $0 }
            .flatMap { $0.$info }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isUpdateFlag.toggle()
            }
            .store(in: &cancellableSet)

        UserManager.shared.$accountsFilter
            .compactMap { $0 }
            .flatMap { $0.$filterAccounts }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isUpdateFlag.toggle()
            }
            .store(in: &cancellableSet)
    }
}
