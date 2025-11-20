//
//  WalletUser.swift
//  FRW
//
//  Created by cat on 11/20/25.
//

import Foundation
import Flow

// MARK: - WalletUser

struct WalletUser: Codable {
    // MARK: Internal

    var emoji: WalletEmoji
    var name: String
    var address: String
    var network: Flow.ChainID

    // MARK: Lifecycle

    init(emoji: WalletEmoji, address: String) {
        self.emoji = emoji
        self.name = emoji.name
        self.address = address
        self.network = currentNetwork
    }

    init(from decoder: any Decoder) throws {
        let container: KeyedDecodingContainer<WalletUser.CodingKeys> = try decoder
            .container(keyedBy: WalletUser.CodingKeys.self)
        do {
            self.emoji = try container.decode(
                WalletEmoji.self,
                forKey: WalletUser.CodingKeys.emoji
            )
        } catch {
            self.emoji = WalletEmoji.avocado
        }

        self.name = try container.decode(
            String.self,
            forKey: WalletUser.CodingKeys.name
        )
        self.address = try container.decode(
            String.self,
            forKey: WalletUser.CodingKeys.address
        )
        self.network = try container.decode(
            Flow.ChainID.self,
            forKey: WalletUser.CodingKeys.network
        )
    }
}

// MARK: - Storage

extension WalletUser {
    private static let repository = WalletUserRepository()

    /// Get or create WalletUser for an address
    /// - Parameters:
    ///   - address: Wallet address
    ///   - userId: Optional user ID. If nil, uses current user
    /// - Returns: WalletUser with emoji and name
    static func get(address: String, userId: String? = nil) -> WalletUser {
        return repository.getUser(address: address, userId: userId)
    }

    /// Update user's emoji and name
    /// - Parameters:
    ///   - address: Wallet address to update
    ///   - emoji: New emoji
    ///   - name: Optional custom name. If nil, uses emoji's default name
    ///   - userId: Optional user ID. If nil, uses current user
    static func update(address: String, emoji: WalletEmoji, name: String? = nil, userId: String? = nil) {
        repository.updateUser(address: address, emoji: emoji, name: name, userId: userId)
    }
}

