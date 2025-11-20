//
//  WalletAccount.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Foundation
import Flow

// MARK: - WalletAccount

struct WalletAccount: Codable {
    // MARK: - Core Identity

    /// Unique identifier for the account
    let id: String

    /// Account address (hex format with 0x prefix)
    let address: String

    /// Account type (main, child, COA, EOA)
    let type: FWAccount.AccountType

    /// Network the account belongs to
    let network: Flow.ChainID

    // MARK: - Display Information

    /// User-customizable display info
    let user: WalletUser?
    let childInfo: ChildInfo?

    /// Parent account relationship (for linked accounts)
    let parent: ParentInfo?

    // MARK: - Account State

    /// Whether this account is currently selected
    let isActive: Bool

    /// Asset data (balance and NFT count)
    let assets: AssetData

    // MARK: - Nested Types

    /// Parent account information for linked accounts
    struct ParentInfo: Codable {
        let address: String
        let emoji: WalletEmoji
    }

    struct ChildInfo: Codable {
      let avatar: String?
      let name: String?
      let desc: String?
    }

    /// Asset data with loading state
    enum AssetData {
        case notLoaded
        case loading
        case loaded(balance: Double, nftCount: Int)
        case error(Error)

        var balance: Double? {
            if case .loaded(let balance, _) = self { return balance }
            return nil
        }

        var nftCount: Int? {
            if case .loaded(_, let count) = self { return count }
            return nil
        }

        var isReady: Bool {
            if case .loaded = self { return true }
            return false
        }
    }
}

// MARK: - Computed Properties

extension WalletAccount {
    /// Whether this COA account should be hidden in the UI
    /// Hidden when it has no balance and no NFTs
    var isHidden: Bool {
        guard type == .coa else { return false }
        guard case .loaded(let balance, let nftCount) = assets else {
            return false  // Don't hide if data not loaded yet
        }
        return balance == 0 && nftCount == 0
    }

    /// Formatted balance display string
    var displayBalance: String {
        guard let balance = assets.balance else {
            return "0.0 Flow"
        }
        return balance.formatDisplayFlowBalance
    }

    var displayName: String {
      if type == .child {
        return childInfo?.name ?? ""
      }
      return user?.name ?? ""
    }
    /// Whether assets are ready for display (COA accounts)
    var assetsReady: Bool {
        assets.isReady
    }
}

// MARK: - Equatable

extension WalletAccount: Equatable {
    static func == (lhs: WalletAccount, rhs: WalletAccount) -> Bool {
        lhs.id == rhs.id &&
        lhs.address == rhs.address &&
        lhs.type == rhs.type &&
        lhs.network == rhs.network &&
        lhs.displayName == rhs.displayName
    }
}

// MARK: - Identifiable

extension WalletAccount: Identifiable {}

// MARK: - Hashable

extension WalletAccount: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(address)
        hasher.combine(type)
        hasher.combine(displayName)
    }
}

// MARK: - AssetData Codable

extension WalletAccount.AssetData: Codable {
    private enum CodingKeys: String, CodingKey {
        case state
        case balance
        case nftCount
    }

    private enum State: String, Codable {
        case notLoaded
        case loading
        case loaded
        case error
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .notLoaded:
            try container.encode(State.notLoaded, forKey: .state)
        case .loading:
            try container.encode(State.loading, forKey: .state)
        case .loaded(let balance, let nftCount):
            try container.encode(State.loaded, forKey: .state)
            try container.encode(balance, forKey: .balance)
            try container.encode(nftCount, forKey: .nftCount)
        case .error:
            // Encode error state but don't persist error details
            try container.encode(State.error, forKey: .state)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let state = try container.decode(State.self, forKey: .state)

        switch state {
        case .notLoaded:
            self = .notLoaded
        case .loading:
            self = .loading
        case .loaded:
            let balance = try container.decode(Double.self, forKey: .balance)
            let nftCount = try container.decode(Int.self, forKey: .nftCount)
            self = .loaded(balance: balance, nftCount: nftCount)
        case .error:
            // Decode error state as notLoaded (errors are temporary and shouldn't be persisted)
            self = .notLoaded
        }
    }
}
