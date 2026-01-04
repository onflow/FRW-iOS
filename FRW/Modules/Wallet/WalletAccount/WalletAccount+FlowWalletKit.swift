//
//  WalletAccount+FlowWalletKit.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Foundation
import FlowWalletKit

// MARK: - FlowWalletKit.Account → WalletAccount

extension FlowWalletKit.Account {
    /// Convert FlowWalletKit Account to native WalletAccount
    /// - Parameter userId: Optional user ID for multi-user support
    /// - Returns: Native WalletAccount with display info populated from WalletUser
    /// - Note: Assets default to .notLoaded, call loadAssets() separately
    func toWalletAccount(userId: String? = nil) -> WalletAccount {
        let addr = address.hexAddr
        let user = WalletUser.get(address: addr, userId: userId)

        return WalletAccount(
            id: UUID().uuidString,
            address: addr,
            type: .main,
            network: currentNetwork,
            user: user,
            childInfo: nil,
            parent: nil,
            isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
            assets: .notLoaded
        )
    }

    /// Get WalletUser for this account (for backward compatibility)
    func walletAccountUser() -> WalletUser {
        let addr = address.hexAddr
        let user = WalletUser.get(address: addr)
        return user
    }
}

// MARK: - FlowWalletKit.ChildAccount → WalletAccount

extension FlowWalletKit.ChildAccount {
    /// Convert FlowWalletKit ChildAccount to native WalletAccount
    /// - Parameters:
    ///   - parentAddress: Parent account address, defaults to current main account
    ///   - userId: Optional user ID for multi-user support
    /// - Returns: Native WalletAccount with parent relationship
    /// - Note: Child accounts use avatar instead of emoji
    func toWalletAccount(
        parentAddress: String? = WalletManager.shared.mainAccount?.hexAddr,
        userId: String? = nil
    ) -> WalletAccount {
        let addr = address.hexAddr

        let parentInfo: WalletAccount.ParentInfo? = parentAddress.map { parentAddr in
            let parentUser = WalletUser.get(address: parentAddr, userId: userId)
            return WalletAccount.ParentInfo(
                address: parentAddr,
                emoji: parentUser.emoji
            )
        }

        return WalletAccount(
            id: UUID().uuidString,
            address: addr,
            type: .child,
            network: currentNetwork,
            user: nil,
            childInfo: .init(avatar: icon?.absoluteString, name: name, desc: description),
            parent: parentInfo,
            isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
            assets: .notLoaded
        )
    }
}

// MARK: - FlowWalletKit.COA → WalletAccount

extension FlowWalletKit.COA {
    /// Convert FlowWalletKit COA (Cadence Owned Account) to native WalletAccount
    /// - Parameters:
    ///   - parentAddress: Parent Flow account address, defaults to current main account
    ///   - userId: Optional user ID for multi-user support
    /// - Returns: Native WalletAccount with COA type and parent relationship
    /// - Note: COA accounts are EVM accounts linked to a Flow account
    func toWalletAccount(
        parentAddress: String? = WalletManager.shared.mainAccount?.hexAddr,
        userId: String? = nil
    ) -> WalletAccount {
        let addr = address.addHexPrefix()
        let user = WalletUser.get(address: addr, userId: userId)

        let parentInfo: WalletAccount.ParentInfo? = parentAddress.map { parentAddr in
            let parentUser = WalletUser.get(address: parentAddr, userId: userId)
            return WalletAccount.ParentInfo(
                address: parentAddr,
                emoji: parentUser.emoji
            )
        }

        return WalletAccount(
            id: UUID().uuidString,
            address: addr,
            type: .coa,
            network: currentNetwork,
            user: user,
            childInfo: nil,
            parent: parentInfo,
            isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
            assets: .notLoaded
        )
    }
}

// MARK: - EOA → WalletAccount

extension EOA {
    /// Convert EOA (Externally Owned Account) to native WalletAccount
    /// - Parameters:
    ///   - parentAddress: Optional parent address (EOA accounts typically don't have parents)
    ///   - userId: Optional user ID for multi-user support
    /// - Returns: Native WalletAccount with EOA type
    /// - Note: EOA accounts are standalone EVM accounts not linked to Flow
    func toWalletAccount(
        parentAddress: String? = nil,
        userId: String? = nil
    ) -> WalletAccount {
        let addr = address.addHexPrefix()
        let user = WalletUser.get(address: addr, userId: userId)
        let parentInfo: WalletAccount.ParentInfo? = parentAddress.map { parentAddr in
            let parentUser = WalletUser.get(address: parentAddr, userId: userId)
            return WalletAccount.ParentInfo(
                address: parentAddr,
                emoji: parentUser.emoji
            )
        }
        return WalletAccount(
            id: UUID().uuidString,
            address: addr,
            type: .eoa,
            network: currentNetwork,
            user: user,
            childInfo: nil,
            parent: parentInfo,
            isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
            assets: .notLoaded
        )
    }
}

// MARK: - FlowWalletKit.Wallet Extensions

extension FlowWalletKit.Wallet {
    /// Build complete account hierarchy for current network
    /// - Parameter userId: Optional user ID for multi-user support
    /// - Returns: 2D array of WalletAccounts, grouped by account relationships
    /// - Note: First group is EOA accounts, followed by main account groups with their linked accounts
    func buildWalletAccounts(userId: String? = nil) async throws -> [[WalletAccount]] {
        var result: [[WalletAccount]] = []

        // EOA accounts for current network
        let eoa = eoaAddress?.compactMap({ EOA($0, network: currentNetwork)?.toWalletAccount(userId: userId) }) ?? []
        if !eoa.isEmpty {
            result.append(eoa)
        }

        // Safely unwrap accounts for the current network
        if let accountsByNetwork = accounts,
           let networkAccounts = accountsByNetwork[currentNetwork] {
            var linkedGroups: [[WalletAccount]] = []
            for account in networkAccounts {
                let group = try await account.buildWalletAccount(userId: userId)
                linkedGroups.append(group)
            }
            result.append(contentsOf: linkedGroups)
        }

        return result
    }
}

// MARK: - FlowWalletKit.Account Extensions

extension FlowWalletKit.Account {
    /// Build account group including main account and all linked accounts
    /// - Parameter userId: Optional user ID for multi-user support
    /// - Returns: Array of WalletAccounts with main account first, followed by linked accounts
    /// - Note: Automatically fetches linked accounts if not already loaded
    func buildWalletAccount(userId: String? = nil) async throws -> [WalletAccount] {
        if !hasLinkedAccounts {
            try await fetchAccount()
        }
        var result: [WalletAccount] = []
        let mainAccount = toWalletAccount(userId: userId)
        result.append(mainAccount)

        if let account = coa {
            let linkedAccount = account.toWalletAccount(parentAddress: mainAccount.address, userId: userId)
            result.append(linkedAccount)
        }

        if let childAccount = childs {
            let linkedAccounts = childAccount.map { $0.toWalletAccount(parentAddress: mainAccount.address, userId: userId) }
            result.append(contentsOf: linkedAccounts)
        }
        return result
    }
}
