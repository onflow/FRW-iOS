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
        let list = WalletManager.shared.currentNetworkAccounts
        Task {
            var results: [[AccountModel]] = []
            await withTaskGroup(of: [AccountModel]?.self) { group in
                for account in list {
                    group.addTask {
                        do {
                            return try await self.fetchMetadata(account: account)
                        } catch {
                            log.info("[SideMenu] fetch child or coa failed:\(error)")
                            return nil
                        }
                    }
                }
                for await result in group {
                    if let result = result {
                        results.append(result)
                    }
                }
            }
            let sortedResult = results.sorted { lhs, rhs in

                guard let l = lhs.first, let r = rhs.first else { return false }

                let lFlow = Double(l.flowCount) ?? 0
                let rFlow = Double(r.flowCount) ?? 0
                if lFlow != rFlow {
                    return lFlow > rFlow
                }
                return l.nftCount > r.nftCount
            }
            await MainActor.run {
                self.accounts = sortedResult
            }
        }
    }

    private func fetchMetadata(account: FlowWalletKit.Account) async throws -> [AccountModel] {
        try? await account.fetchAccount()
        let countInfo = await fetchCount(account: account)

        var tmp: [AccountModel] = []
        let mainInfo = countInfo[account.hexAddr] ?? .empty
        tmp.append(AccountModel(account: account, flowCount: String(mainInfo.flowBalance), nftCount: mainInfo.nftCounts))
        if let coa = account.coa {
            let coaInfo = countInfo[coa.address] ?? .empty
            tmp.append(AccountModel(account: coa, mainAccount: account, flowCount: String(coaInfo.flowBalance), nftCount: coaInfo.nftCounts))
        }
        if let child = account.childs {
            let result = child.map { child in
                let childInfo = countInfo[child.address.hexAddr] ?? .empty
                return AccountModel(account: child, mainAccount: account, flowCount: String(childInfo.flowBalance), nftCount: childInfo.nftCounts)
            }
            let sortedResult = result.sorted { lhs, rhs in
                let lhsFlow = Double(lhs.flowCount) ?? 0
                let rhsFlow = Double(rhs.flowCount) ?? 0
                if lhsFlow != rhsFlow {
                    return lhsFlow > rhsFlow
                }
                return lhs.nftCount > rhs.nftCount
            }
            tmp.append(contentsOf: sortedResult)
        }
        return tmp
    }

    private func fetchCount(account: FlowWalletKit.Account) async -> [String: FlowNFTCountModel] {
        do {
            var addressList: [String] = [account.hexAddr]
            if let address = account.coa?.address {
                addressList.append(address)
            }
            if let childs = account.childs {
                addressList.append(contentsOf: childs.map { $0.address.hexAddr })
            }
            let countInfo = try await FlowNetwork.getFlowTokenAndNFTCount(addresses: addressList)
            return countInfo
        } catch {
            log.error(error)
            return [:]
        }
    }
}
