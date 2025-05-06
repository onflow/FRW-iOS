//
//  ManagerTokensViewModel.swift
//  FRW
//
//  Created by cat on 5/6/25.
//

import Combine
import Foundation

class ManagerTokensViewModel: ObservableObject {
    private var cancellableSet = Set<AnyCancellable>()
    @Published var list: [ManagerTokensViewModel.Item] = []
    @Published var searchText: String = "" {
        didSet {
            update()
        }
    }

    init() {
        WalletManager.shared.filterToken.$hideTokens
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.update()
            }
            .store(in: &cancellableSet)
    }

    private func update() {
        let allTokens = WalletManager.shared.activatedCoins
        let result = allTokens.map { token in
            ManagerTokensViewModel.Item(token: token,
                                        isOpen: WalletManager.shared.filterToken.isOpen(token: token))
        }
        list = result.filter { item in
            if searchText.isEmpty {
                return true
            }
            if item.token.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            if item.token.contractName.localizedCaseInsensitiveContains(searchText) {
                return true
            }

            if let symbol = item.token.symbol, symbol.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            return false
        }
    }
}

extension ManagerTokensViewModel {
    struct Item: Identifiable {
        let token: TokenModel
        var isOpen: Bool

        var id: String {
            token.contractId
        }
    }
}
