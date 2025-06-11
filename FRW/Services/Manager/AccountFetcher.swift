//
//  AccountFetcher.swift
//  FRW
//
//  Created by cat on 6/7/25.
//

import FlowWalletKit
import Foundation

struct AccountFetcher {
    func fetchAccountInfo(_ list: [FlowWalletKit.Account]) async throws -> [AccountModel] {
        var results: [AccountModel] = []
        await withTaskGroup(of: AccountModel?.self) { group in
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

            let lFlow = Double(lhs.flowCount) ?? 0
            let rFlow = Double(rhs.flowCount) ?? 0
            if lFlow != rFlow {
                return lFlow > rFlow
            }
            return lhs.nftCount > lhs.nftCount
        }
        return sortedResult
    }

    private func fetchMetadata(account: FlowWalletKit.Account) async throws -> AccountModel {
        try? await account.fetchAccount()
        let countInfo = await fetchCount(account: account)
        return AccountFetcher.regroup(account: account, with: countInfo)
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

extension AccountFetcher {
    static func regroup(account: FlowWalletKit.Account, with info: [String: FlowNFTCountModel]) -> AccountModel {
        var linkedAccount: [AccountModel] = []
        if let coa = account.coa {
            let coaInfo = info[coa.address] ?? .empty
            linkedAccount.append(AccountModel(account: coa, mainAccount: account, flowCount: String(coaInfo.flowBalance), nftCount: coaInfo.nftCounts, linkedAccounts: []))
        }
        if let child = account.childs {
            let result = child.map { child in
                let childInfo = info[child.address.hexAddr] ?? .empty
                return AccountModel(account: child, mainAccount: account, flowCount: String(childInfo.flowBalance), nftCount: childInfo.nftCounts, linkedAccounts: [])
            }
            let sortedResult = result.sorted { lhs, rhs in
                let lhsFlow = Double(lhs.flowCount) ?? 0
                let rhsFlow = Double(rhs.flowCount) ?? 0
                if lhsFlow != rhsFlow {
                    return lhsFlow > rhsFlow
                }
                return lhs.nftCount > rhs.nftCount
            }
            linkedAccount.append(contentsOf: sortedResult)
        }

        let mainInfo = info[account.hexAddr] ?? .empty
        let model = AccountModel(account: account, flowCount: String(mainInfo.flowBalance), nftCount: mainInfo.nftCounts, linkedAccounts: linkedAccount)
        return model
    }
}
