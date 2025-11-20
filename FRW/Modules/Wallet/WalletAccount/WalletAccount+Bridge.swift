//
//  WalletAccount+Bridge.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Foundation
import Flow

// MARK: - iOS Native → RN Bridge

extension WalletAccount {
    /// Convert iOS native WalletAccount to RN bridge type
    /// - Returns: RNBridge.WalletAccount for React Native communication
    func toRNBridge() -> RNBridge.WalletAccount {
        let emojiInfo = RNBridge.EmojiInfo(
            emoji: displayInfo.emoji.rawValue,
            name: displayInfo.emoji?.name ?? "",
            color: displayInfo.emoji?.colorHex ?? ""
        )

        let parentEmoji: RNBridge.EmojiInfo? = parent.map { parentInfo in
            RNBridge.EmojiInfo(
                emoji: parentInfo.emoji.rawValue,
                name: parentInfo.emoji.name,
                color: parentInfo.emoji.colorHex
            )
        }

        return RNBridge.WalletAccount(
            id: id,
            name: displayInfo.name,
            address: address,
            emojiInfo: emojiInfo,
            parentEmoji: parentEmoji,
            parentAddress: parent?.address,
            avatar: displayInfo.avatar,
            isActive: isActive,
            type: type.toRNBridgeType(),
            balance: assets.balance.map { String($0) },
            nfts: assets.nftCount.map { String($0) }
        )
    }
}

// MARK: - RN Bridge → iOS Native

extension RNBridge.WalletAccount {
    /// Convert RN bridge type to iOS native WalletAccount
    /// - Parameter network: The network this account belongs to
    /// - Returns: Native WalletAccount instance
    /// - Note: Asset data defaults to .notLoaded if not provided
    func toNativeAccount(network: Flow.ChainID) -> WalletAccount {
        let displayInfo = WalletAccount.DisplayInfo(
            name: name,
            emoji: WalletEmoji(name: emojiInfo?.emoji),
            avatar: avatar
        )

        let parentInfo: WalletAccount.ParentInfo? = {
            guard let parentAddress, let parentEmoji else { return nil }
            return WalletAccount.ParentInfo(
                address: parentAddress,
                emoji: WalletEmoji(name: parentEmoji.emoji)
            )
        }()

        let assetData: WalletAccount.AssetData = {
            if let balanceStr = balance,
               let nftStr = nfts,
               let balance = Double(balanceStr),
               let nftCount = Int(nftStr) {
                return .loaded(balance: balance, nftCount: nftCount)
            }
            return .notLoaded
        }()

        return WalletAccount(
            id: id,
            address: address,
            type: type?.toNativeType() ?? .main,
            network: network,
            displayInfo: displayInfo,
            parent: parentInfo,
            isActive: isActive,
            assets: assetData
        )
    }
}

// MARK: - Account Type Conversion

extension WalletAccount.AccountType {
    /// Convert native account type to RN bridge type
    func toRNBridgeType() -> RNBridge.AccountType {
        switch self {
        case .main: return .main
        case .child: return .child
        case .coa: return .evm
        case .eoa: return .eoa
        }
    }
}

extension RNBridge.AccountType {
    /// Convert RN bridge type to native account type
    /// - Note: Cannot distinguish COA from EOA without parent info
    func toNativeType() -> WalletAccount.AccountType {
        switch self {
        case .main: return .main
        case .child: return .child
        case .evm: return .coa  // Default to COA, refine with parent info
        case .eoa: return .eoa
        }
    }
}

// MARK: - Batch Conversion Helpers

extension Array where Element == WalletAccount {
    /// Convert array of native accounts to RN bridge types
    func toRNBridge() -> [RNBridge.WalletAccount] {
        map { $0.toRNBridge() }
    }
}

extension Array where Element == RNBridge.WalletAccount {
    /// Convert array of RN bridge accounts to native types
    /// - Parameter network: The network these accounts belong to
    func toNativeAccounts(network: Flow.ChainID) -> [WalletAccount] {
        map { $0.toNativeAccount(network: network) }
    }
}

// MARK: - 2D Array Conversion (for grouped accounts)

extension Array where Element == [WalletAccount] {
    /// Convert 2D array of native accounts to RN bridge types
    func toRNBridge() -> [[RNBridge.WalletAccount]] {
        map { $0.toRNBridge() }
    }
}

extension Array where Element == [RNBridge.WalletAccount] {
    /// Convert 2D array of RN bridge accounts to native types
    /// - Parameter network: The network these accounts belong to
    func toNativeAccounts(network: Flow.ChainID) -> [[WalletAccount]] {
        map { $0.toNativeAccounts(network: network) }
    }
}
