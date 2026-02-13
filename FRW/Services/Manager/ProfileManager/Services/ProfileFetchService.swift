//
//  ProfileFetchService.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Flow
import FlowWalletKit
import Foundation

// MARK: - ProfileFetchService

/// Service responsible for fetching profile data from network/blockchain
final class ProfileFetchService: ProfileFetchServiceProtocol {
    // MARK: Lifecycle

    init(keyService: ProfileKeyServiceProtocol) {
        self.keyService = keyService
    }

    // MARK: Internal

    // MARK: - ProfileFetchServiceProtocol Implementation

    func fetchAccounts(for profiles: [ProfileModel]) async throws -> [ProfileModel] {
        let network = currentNetwork
        let supportNetworks: Set<Flow.ChainID> = [network]

        return try await withThrowingTaskGroup(of: ProfileModel?.self) { group in
            for profile in profiles {
                group.addTask { [weak self] in
                    guard let self else { return nil }
                    return try await self.fetchAccountsForProfile(
                        profile,
                        networks: supportNetworks,
                        targetNetwork: network
                    )
                }
            }

            var results: [ProfileModel] = []
            for try await result in group {
                if let profile = result {
                    results.append(profile)
                }
            }
            return results
        }
    }

    func fetchBalances(for profiles: [ProfileModel]) async throws -> [ProfileModel] {
        // Collect all addresses from all profiles
        let addresses = profiles.flatMap { profile in
            profile.accounts.flatMap { $0 }.compactMap { $0.address }
        }

        guard !addresses.isEmpty else { return profiles }

        // Fetch all balances in one batch request
        let balanceProvider = CadenceTokenBalanceProvider()
        let balances = try await balanceProvider.getAvailableFlowBalance(addresses: addresses)

        // Update profiles with balances
        return profiles.map { profile in
            let updatedGroups = profile.accounts.map { group in
                group.map { account in
                    guard let balance = balances[account.address] else {
                        return account
                    }
                    return account.copyWith(balance: balance.doubleValue)
                }
            }
            return profile.updatingAccounts(to: updatedGroups)
        }
    }
    
    func fetchERC20Balances(for profiles: [ProfileModel]) async throws -> [ProfileModel] {
        let coaAddresses = profiles.flatMap { profile in
            profile.accounts.flatMap { $0 }
                .filter { $0.type == .coa }
                .compactMap { $0.address }
        }

        guard !coaAddresses.isEmpty else { return profiles }
        let erc20Balances = await fetchERC20DisplayBalancesForAddresses(coaAddresses)
        let nonZeroCount = erc20Balances.values.filter { $0 > 0 }.count
        let totalErc20Balance = erc20Balances.values.reduce(0, +)
        log.debug("[ProfileFetch] ERC20 summary: \(nonZeroCount)/\(coaAddresses.count) non-zero, total=\(totalErc20Balance)")

        return profiles.map { profile in
            let updatedGroups = profile.accounts.map { group in
                group.map { account in
                    guard account.type == .coa,
                          let erc20Balance = erc20Balances[account.address]
                    else {
                        return account
                    }

                    return account.copyWith(erc20Balance: erc20Balance)
                }
            }
            return profile.updatingAccounts(to: updatedGroups)
        }
    }
    
    func fetchNFTCounts(for profiles: [ProfileModel]) async throws -> [ProfileModel] {
        // Collect all COA addresses
        let coaAddresses = profiles.flatMap { profile in
            profile.accounts.flatMap { $0 }
                .filter { $0.type == .coa }
                .compactMap { $0.address }
        }

        guard !coaAddresses.isEmpty else { return profiles }

        // Fetch NFT counts in parallel
        let nftCounts = await fetchNFTCountsForAddresses(coaAddresses)

        // Update profiles with NFT counts
        return profiles.map { profile in
            let updatedGroups = profile.accounts.map { group in
                group.map { account in
                    guard account.type == .coa,
                          let count = nftCounts[account.address],
                          count > 0
                    else {
                        return account
                    }
                    return account.copyWith(nftCount: count)
                }
            }
            return profile.updatingAccounts(to: updatedGroups)
        }
    }

    func fetchAllAccountInfo(for profiles: [ProfileModel]) async throws -> [ProfileModel] {
        // Pipeline: Accounts → Balances → ERC20 → NFTs
        let withAccounts = try await fetchAccounts(for: profiles)
        log.debug("[ProfileFetch] Fetched accounts for \(withAccounts.count) profiles")

        let withBalances = try await fetchBalances(for: withAccounts)
        log.debug("[ProfileFetch] Fetched balances")

        let withERC20 = try await fetchERC20Balances(for: withBalances)
        log.debug("[ProfileFetch] Fetched ERC20 balances")

        let withNFTs = try await fetchNFTCounts(for: withERC20)
        log.debug("[ProfileFetch] Fetched NFT counts")

        return withNFTs
    }

    // MARK: Private

    private let keyService: ProfileKeyServiceProtocol

    // MARK: - Private Methods

    private func fetchAccountsForProfile(
        _ profile: ProfileModel,
        networks: Set<Flow.ChainID>,
        targetNetwork: Flow.ChainID
    ) async throws -> ProfileModel? {
        guard let provider = keyService.findKeyProvider(uid: profile.uid) else {
            log.warning("[ProfileFetch] No key provider for \(profile.uid)")
            return nil
        }

        var walletAccounts: [[WalletAccount]] = []
        let walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: networks)
        try? await walletEntity.fetchAccount()

        guard let accountList = walletEntity.accounts?[targetNetwork] else {
            return nil
        }

        // Process EOA addresses
        if let eoas = walletEntity.eoaAddress {
            let eoaAccounts = Array(eoas).compactMap {
                EOA($0, network: targetNetwork)?.toWalletAccount(userId: profile.uid)
            }
            if !eoaAccounts.isEmpty {
                walletAccounts.append(eoaAccounts)
            }
        }

        // Process each Flow account
        for account in accountList {
            if let accountGroup = try? await parseAccount(account: account, userId: profile.uid) {
                walletAccounts.append(accountGroup)
            }
        }

        return profile.updatingAccounts(to: walletAccounts)
    }

    private func parseAccount(
        account: FlowWalletKit.Account,
        userId: String?
    ) async throws -> [WalletAccount] {
        var list: [WalletAccount] = []

        try? await account.fetchAccount()
        list.append(account.toWalletAccount(userId: userId))

        // Add COA if exists
        if let coa = account.coa {
            list.append(coa.toWalletAccount(parentAddress: account.hexAddr, userId: userId))
        }

        // Add child accounts
        if let children = account.childs {
            let childAccounts = children.map {
                $0.toWalletAccount(parentAddress: account.hexAddr, userId: userId)
            }
            list.append(contentsOf: childAccounts)
        }

        return list
    }

  
    private func fetchNFTCountsForAddresses(_ addresses: [String]) async -> [String: Int] {
        await withTaskGroup(of: (String, Int)?.self) { group in
          let tokenProvider = await EVMTokenBalanceProvider()

            for address in addresses {
                group.addTask {
                    guard let fwAddress = FWAddressDector.create(address: address) else {
                        return nil
                    }
                    do {
                        let collections = try await tokenProvider.getNFTCollections(address: fwAddress)
                        let count = collections.reduce(0) { $0 + $1.count }
                        return (address, count)
                    } catch {
                        log.warning("[ProfileFetch] NFT fetch failed for \(address): \(error)")
                        return nil
                    }
                }
            }

            var results: [String: Int] = [:]
            for await result in group {
                if let (address, count) = result {
                    results[address] = count
                }
            }
            return results
        }
    }
    
    private func fetchERC20DisplayBalancesForAddresses(_ addresses: [String]) async -> [String: Double] {
        await withTaskGroup(of: (String, Double)?.self) { group in
            for address in addresses {
                group.addTask {
                    guard let fwAddress = FWAddressDector.create(address: address) else {
                        return nil
                    }
                    do {
                        // Force refresh to avoid stale cache after migration
                        let tokens = try await TokenBalanceHandler.shared.fetchUserTokens(address: fwAddress)
                        let sum = tokens.reduce(Decimal.zero) { partial, token in
                            guard let display = token.displayBalance,
                                  let value = Decimal(string: display),
                                  value > 0
                            else {
                                return partial
                            }
                            return partial + value
                        }
                        return (address, sum.doubleValue)
                    } catch {
                        log.warning("[ProfileFetch] ERC20 fetch failed for \(address): \(error)")
                        return nil
                    }
                }
            }

            var results: [String: Double] = [:]
            for await result in group {
                if let (address, sum) = result {
                    results[address] = sum
                }
            }
            return results
        }
    }
}
