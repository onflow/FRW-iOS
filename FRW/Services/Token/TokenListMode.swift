//
//  TokenListMode.swift
//  FRW
//
//  Created by Hao Fu on 7/4/2025.
//

import Foundation

/// Types allowed for Token's display list
struct TokenListMode: OptionSet {
    let rawValue: Int

    // Define individual token list modes with bitwise values
    static let whitelist = TokenListMode(rawValue: 1 << 0) // 0001
    static let unverified = TokenListMode(rawValue: 1 << 1) // 0010
    static let custom = TokenListMode(rawValue: 1 << 2) // 0100

    // Define combined modes for easier use
    static let whitelistAndUnverified: TokenListMode = [.whitelist, .unverified] // 0011
    static let whitelistAndCustom: TokenListMode = [.whitelist, .custom] // 0101
    static let all: TokenListMode = [.whitelist, .unverified, .custom] // 0111

    // Helper function to check if mode contains another
    func contains(_ mode: TokenListMode) -> Bool {
        return intersection(mode) == mode
    }
}
