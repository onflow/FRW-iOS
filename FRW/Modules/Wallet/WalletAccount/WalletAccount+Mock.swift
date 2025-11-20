//
//  WalletAccount+Mock.swift
//  FRW
//
//  Created by cat on 11/20/25.
//

import Foundation
import Flow

#if DEBUG

// MARK: - WalletAccount Mock Data

extension WalletAccount {
    /// Creates a mock main account for previews and testing
    static func mockMain(
        id: String = "mock-main-1",
        name: String = "Panda",
        emoji: WalletEmoji = .panda,
        address: String = "0x8888888888888ab",
        network: Flow.ChainID = .mainnet,
        isActive: Bool = true,
        balance: Double = 550.66,
        nftCount: Int = 0
    ) -> WalletAccount {
        WalletAccount(
            id: id,
            address: address,
            type: .main,
            network: network,
            displayInfo: DisplayInfo(
                name: name,
                emoji: emoji,
                avatar: nil
            ),
            parent: nil,
            isActive: isActive,
            assets: .loaded(balance: balance, nftCount: nftCount)
        )
    }
    
    /// Creates a mock child account for previews and testing
    static func mockChild(
        id: String = "mock-child-1",
        name: String = "Penguin",
        emoji: WalletEmoji = .penguin,
        address: String = "0x123456",
        network: Flow.ChainID = .mainnet,
        parentAddress: String? = nil,
        parentEmoji: WalletEmoji? = nil,
        isActive: Bool = false,
        balance: Double? = nil,
        nftCount: Int? = nil
    ) -> WalletAccount {
        let parent: ParentInfo?
        if let parentAddress, let parentEmoji {
            parent = ParentInfo(address: parentAddress, emoji: parentEmoji)
        } else {
            parent = nil
        }
        
        let assets: AssetData
        if let balance, let nftCount {
            assets = .loaded(balance: balance, nftCount: nftCount)
        } else {
            assets = .notLoaded
        }
        
        return WalletAccount(
            id: id,
            address: address,
            type: .child,
            network: network,
            displayInfo: DisplayInfo(
                name: name,
                emoji: emoji,
                avatar: nil
            ),
            parent: parent,
            isActive: isActive,
            assets: assets
        )
    }
    
    /// Creates a mock COA (Cadence-owned account) for previews and testing
    static func mockCOA(
        id: String = "mock-coa-1",
        name: String = "EVM Account",
        emoji: WalletEmoji = .avocado,
        address: String = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        network: Flow.ChainID = .mainnet,
        parentAddress: String? = nil,
        parentEmoji: WalletEmoji? = nil,
        isActive: Bool = false,
        balance: Double = 1.23,
        nftCount: Int = 0
    ) -> WalletAccount {
        let parent: ParentInfo?
        if let parentAddress, let parentEmoji {
            parent = ParentInfo(address: parentAddress, emoji: parentEmoji)
        } else {
            parent = nil
        }
        
        return WalletAccount(
            id: id,
            address: address,
            type: .coa,
            network: network,
            displayInfo: DisplayInfo(
                name: name,
                emoji: emoji,
                avatar: nil
            ),
            parent: parent,
            isActive: isActive,
            assets: .loaded(balance: balance, nftCount: nftCount)
        )
    }
    
    /// Creates a mock EOA (externally-owned account) for previews and testing
    static func mockEOA(
        id: String = "mock-eoa-1",
        name: String = "External Wallet",
        emoji: WalletEmoji = .butterfly,
        address: String = "0x9876543210abcdef",
        network: Flow.ChainID = .mainnet,
        isActive: Bool = false,
        balance: Double = 10.5,
        nftCount: Int = 5
    ) -> WalletAccount {
        WalletAccount(
            id: id,
            address: address,
            type: .eoa,
            network: network,
            displayInfo: DisplayInfo(
                name: name,
                emoji: emoji,
                avatar: nil
            ),
            parent: nil,
            isActive: isActive,
            assets: .loaded(balance: balance, nftCount: nftCount)
        )
    }
}

#endif
