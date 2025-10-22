//
//  WalletAccount.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Foundation
import SwiftUI
import Flow

// MARK: - WalletAccount

struct WalletAccount {
    // MARK: Lifecycle

    init() {
        self.storedAccount = LocalUserDefaults.shared.walletAccount ?? [:]
    }

    // MARK: Internal

    var storedAccount: [String: [WalletAccount.User]]

    // MARK: Private

    private var key: String {
        guard let userId = UserManager.shared.activatedUID else {
            return "empty"
        }
        return "\(userId)"
    }

    private func saveCache() {
        LocalUserDefaults.shared.walletAccount = storedAccount
    }
}

// MARK: Logical processing

extension WalletAccount {
    /// Read or create wallet account info for a specific address
    /// - Parameters:
    ///   - address: Wallet address
    ///   - key: Optional storage key. If nil, uses current user's ID
    /// - Returns: User account info with emoji and name
    mutating func readInfo(at address: String, key: String? = nil) -> WalletAccount.User {
        let storageKey = key ?? self.key
        let currentNetwork = currentNetwork
        if var list = storedAccount[storageKey] {
            let lastUser = list.last { $0.network == currentNetwork && $0.address == address }
            if let user = lastUser {
                return user
            } else {
                let filterList = list.filter { $0.network == currentNetwork }
                let existList = filterList.map { $0.emoji }
                // Try to get an unused emoji first
                let nEmoji: WalletAccount.Emoji
                if let unusedEmoji = generalInfo(count: 1, excluded: existList)?.first {
                    // Found an unused emoji
                    nEmoji = unusedEmoji
                } else {
                    // All emojis are used (12+ accounts on this network)
                    // Allow reusing a random emoji
                    nEmoji = WalletAccount.Emoji.random()
                }
                let user = WalletAccount.User(emoji: nEmoji, address: address)
                list.append(user)
                storedAccount[storageKey] = list
                saveCache()
                return user
            }
        } else {
            // First account for this user, no exclusions needed
            let nEmoji = generalInfo(count: 1, excluded: [])?.first ?? WalletAccount.Emoji.random()
            let model = WalletAccount.User(emoji: nEmoji, address: address)
            storedAccount[storageKey] = [model]
            saveCache()
            return model
        }
    }

    /// Update wallet account emoji and name
    /// - Parameters:
    ///   - address: Wallet address to update
    ///   - emoji: New emoji to assign
    ///   - name: Optional new name. If nil, uses emoji's default name
    ///   - key: Optional storage key. If nil, uses current user's ID
    mutating func update(at address: String, emoji: WalletAccount.Emoji, name: String? = nil, key: String? = nil) {
        let storageKey = key ?? self.key
        let currentNetwork = currentNetwork
        if var list = storedAccount[storageKey] {
            if let index = list
                .lastIndex(where: { $0.network == currentNetwork && $0.address == address }) {
                var user = list[index]
                user.emoji = emoji
                user.name = name ?? emoji.name
                list[index] = user
                storedAccount[storageKey] = list
                saveCache()
            }
        }
    }

    /// Generate random emojis excluding specified ones
    /// - Parameters:
    ///   - count: Number of emojis to generate
    ///   - excluded: Emojis to exclude from selection
    /// - Returns: Array of random emojis, or nil if not enough available emojis
    /// - Note: Returns nil when excluded list exhausts all available emojis (12 total)
    private func generalInfo(count: Int, excluded: [Emoji]) -> [WalletAccount.Emoji]? {
        return Emoji.random(count: count, excluding: excluded)
    }
}

// MARK: data struct

extension WalletAccount {
    enum Emoji: String, CaseIterable, Codable {
        case koala = "🐨"
        case lion = "🦁"
        case panda = "🐼"
        case butterfly = "🦋"
        case loong = "🐲"
        case penguin = "🐧"

        case cherry = "🍒"
        case chestnut = "🌰"
        case peach = "🍑"
        case coconut = "🥥"
        case lemon = "🍋"
        case avocado = "🥑"

        // MARK: Internal

        var name: String {
            switch self {
            case .koala: return "Koala"
            case .lion: return "Lion"
            case .panda: return "Panda"
            case .butterfly: return "Butterfly"
            case .penguin: return "Penguin"
            case .cherry: return "Cherry"
            case .chestnut: return "Chestnut"
            case .peach: return "Peach"
            case .coconut: return "Coconut"
            case .lemon: return "Lemon"
            case .avocado: return "Avocado"
            case .loong: return "Loong"
            }
        }

        var color: Color {
            Color(hex: colorHex)
        }
      
        var colorHex: String {
          switch self {
          case .lion:
              "#FFA600"
          case .panda:
              "#EEEEED"
          case .butterfly:
              "#36A5F8"
          case .loong:
              "#AEE676"
          case .peach:
              "#FBB06B"
          case .lemon:
              "#FDEF85"
          case .chestnut:
              "#EBCA84"
          case .avocado:
              "#B2C45C"
          case .koala:
              "#DFCFC8"
          case .penguin:
              "#FFCB6C"
          case .cherry:
              "#FED5DB"
          case .coconut:
              "#E3CAAA"
          }
        }

        func icon(size: CGFloat = 24) -> some View {
            VStack {
                Text(self.rawValue)
                    .font(.system(size: size / 2 + 2))
            }
            .frame(width: size, height: size)
            .background(color)
            .cornerRadius(size / 2.0)
        }

        // MARK: - Random Selection

        /// Get a single random emoji, optionally excluding specific ones
        /// - Parameter excluding: Array of emojis to exclude from selection
        /// - Returns: A random emoji, or nil if all emojis are excluded
        /// - Note: Returns nil when excluding contains all 12 available emojis
        static func random(excluding: [Emoji] = []) -> Emoji {
            return random(count: 1, excluding: excluding)?.first ?? .panda
        }

        /// Get multiple random emojis without duplicates
        /// - Parameters:
        ///   - count: Number of random emojis to return (must be positive)
        ///   - excluding: Array of emojis to exclude from selection
        /// - Returns: Array of random emojis, or nil if not enough valid options
        /// - Note: Returns nil when count > (12 - excluding.count)
        static func random(count: Int, excluding: [Emoji] = []) -> [Emoji]? {
            guard count > 0 else { return [] }
            return allCases.randomDifferentElements(limitCount: count, excluded: excluding)
        }
    }

    struct User: Codable {
        // MARK: Lifecycle

        init(emoji: WalletAccount.Emoji, address: String) {
            self.emoji = emoji
            self.name = emoji.name
            self.address = address
            self.network = currentNetwork
        }

        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<WalletAccount.User.CodingKeys> = try decoder
                .container(keyedBy: WalletAccount.User.CodingKeys.self)
            do {
                self.emoji = try container.decode(
                    WalletAccount.Emoji.self,
                    forKey: WalletAccount.User.CodingKeys.emoji
                )
            } catch {
                self.emoji = WalletAccount.Emoji.avocado
            }

            self.name = try container.decode(
                String.self,
                forKey: WalletAccount.User.CodingKeys.name
            )
            self.address = try container.decode(
                String.self,
                forKey: WalletAccount.User.CodingKeys.address
            )
            self.network = try container.decode(
                Flow.ChainID.self,
                forKey: WalletAccount.User.CodingKeys.network
            )
        }

        // MARK: Internal

        var emoji: WalletAccount.Emoji
        var name: String
        var address: String
        var network: Flow.ChainID
    }
}

extension Array where Element: Equatable {
    func randomDifferentElements(limitCount: Int, excluded: [Element]) -> [Element]? {
        // Filter out excluded elements
        let availableElements = filter { !excluded.contains($0) }

        // Ensure we have enough elements after exclusion
        guard availableElements.count >= limitCount else {
            return nil
        }

        // Shuffle and take the required count
        return Array(availableElements.shuffled().prefix(limitCount))
    }
}
