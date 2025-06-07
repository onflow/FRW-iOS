//
//  UserManager+Accounts.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import FlowWalletKit
import Foundation

/*
 It may not be good to put it here,
 In the future, it may be restructured into a separate class management about account.
 */
extension UserManager {
    func listenWallet() {
        WalletManager.shared.$walletEntity
            .compactMap { $0 }
            .flatMap { $0.$isLoading }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in

                self?.refreshAccounts()
            }
            .store(in: &cancellableSet)
    }

    func unlinkedAccount() {
        refreshAccounts()
    }

    func mainAccount(by address: String) -> AccountInfoProtocol? {
        for list in accounts {
            for account in list {
                if account.account.infoAddress.lowercased() == address.lowercased() {
                    return account.mainAccount ?? account.account
                }
            }
        }
        return nil
    }

    private func refreshAccounts() {
        Task {
            do {
                let list = await WalletManager.shared.currentNetworkAccounts
                let fetcher = AccountFetcher()
                accounts = try await fetcher.fetchAccountInfo(list)
            } catch {
                log.error("fetch accounts failed.")
            }
        }
    }
}
