//
//  WalletUserRepository.swift
//  FRW
//
//  Created by cat on 11/20/25.
//

import Foundation
import Flow

// MARK: - WalletUserRepository

/// Internal repository for storing and retrieving WalletUser data
/// Not exposed publicly - use WalletUser static methods instead
final class WalletUserRepository {
    // MARK: Lifecycle

    init() {
        self.storage = LocalUserDefaults.shared.walletAccount ?? [:]
    }

    // MARK: Internal

    /// Get or create WalletUser for an address
    func getUser(address: String, userId: String? = nil) -> WalletUser {
        let key = userId ?? currentUserId
        let network = currentNetwork

        // Find existing user
        if let user = findUser(address: address, network: network, in: key) {
            return user
        }

        // Create new user
        return createUser(address: address, network: network, in: key)
    }

    /// Update WalletUser emoji and name
    func updateUser(address: String, emoji: WalletEmoji, name: String? = nil, userId: String? = nil) {
        let key = userId ?? currentUserId
        let network = currentNetwork

        guard var users = storage[key],
              let index = users.lastIndex(where: { $0.address == address && $0.network == network }) else {
            return
        }

        var user = users[index]
        user.emoji = emoji
        user.name = name ?? emoji.name
        users[index] = user

        storage[key] = users
        save()
    }

    // MARK: Private

    private var storage: [String: [WalletUser]]

    private var currentUserId: String {
        UserManager.shared.activatedUID ?? "empty"
    }

    private func findUser(address: String, network: Flow.ChainID, in key: String) -> WalletUser? {
        guard let users = storage[key] else { return nil }
        return users.last { $0.address == address && $0.network == network }
    }

    private func createUser(address: String, network: Flow.ChainID, in key: String) -> WalletUser {
        let emoji = selectEmoji(for: key, network: network)
        let user = WalletUser(emoji: emoji, address: address)

        var users = storage[key] ?? []
        users.append(user)
        storage[key] = users
        save()

        return user
    }

    private func selectEmoji(for key: String, network: Flow.ChainID) -> WalletEmoji {
        guard let users = storage[key] else {
            return WalletEmoji.random()
        }

        // Get emojis used on this network
        let usedEmojis = users
            .filter { $0.network == network }
            .map { $0.emoji }

        // Try to find unused emoji
        if let unusedEmoji = WalletEmoji.random(count: 1, excluding: usedEmojis)?.first {
            return unusedEmoji
        }

        // All emojis used, allow reusing
        return WalletEmoji.random()
    }

    private func save() {
        LocalUserDefaults.shared.walletAccount = storage
    }
}
