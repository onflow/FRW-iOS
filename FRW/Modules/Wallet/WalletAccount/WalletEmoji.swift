//
//  WalletEmoji.swift
//  FRW
//
//  Created by cat on 11/20/25.
//

import Foundation
import SwiftUI

// MARK: - WalletEmoji

enum WalletEmoji: String, CaseIterable, Codable {
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
                .font(.system(size: size / 2 ))
        }
        .frame(width: size, height: size)
        .background(color)
        .cornerRadius(size / 2.0)
    }

    init(name: String?) {
      guard let name, let result = WalletEmoji(rawValue: name) else {
        self = WalletEmoji.random()
        return
      }
      self = result
    }

    // MARK: - Random Selection

    /// Get a single random emoji, optionally excluding specific ones
    /// - Parameter excluding: Array of emojis to exclude from selection
    /// - Returns: A random emoji, or nil if all emojis are excluded
    /// - Note: Returns nil when excluding contains all 12 available emojis
    static func random(excluding: [WalletEmoji] = []) -> WalletEmoji {
        return random(count: 1, excluding: excluding)?.first ?? .panda
    }

    /// Get multiple random emojis without duplicates
    /// - Parameters:
    ///   - count: Number of random emojis to return (must be positive)
    ///   - excluding: Array of emojis to exclude from selection
    /// - Returns: Array of random emojis, or nil if not enough valid options
    /// - Note: Returns nil when count > (12 - excluding.count)
    static func random(count: Int, excluding: [WalletEmoji] = []) -> [WalletEmoji]? {
        guard count > 0 else { return [] }
        return allCases.randomDifferentElements(limitCount: count, excluded: excluding)
    }
}

// MARK: - Array Extension

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
