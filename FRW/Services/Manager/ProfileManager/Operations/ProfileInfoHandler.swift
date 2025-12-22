//
//  ProfileInfoHandler.swift
//  FRW
//
//  Created by cat on 11/29/25.
//

import Foundation

// MARK: - ProfileManager+Info

extension ProfileManager {
    /// Update a specific account by address for the current profile
    /// - Parameter address: The account address to update
    func updateAccount(at address: String) {
        guard let profile = currentProfile else {
            log.error("[ProfileInfo] No current profile found")
            return
        }

        // Update accounts while preserving group structure
        let updatedGroups = profile.accounts.map { group in
            group.map { account in
                if account.address.lowercased() == address.lowercased() {
                    return account.updatedFromEmoji()
                }
                return account
            }
        }

        let updatedProfile = profile.updatingAccounts(to: updatedGroups)
        saveProfile(updatedProfile)
        log.debug("[ProfileInfo] Updated account: \(address)")
    }

    /// Update account emoji/display info for a specific address
    /// - Parameters:
    ///   - address: The account address
    ///   - emoji: New emoji identifier
    func updateAccountEmoji(at address: String, emoji: String) {
        guard let profile = currentProfile else {
            log.error("[ProfileInfo] No current profile found")
            return
        }

        let updatedGroups = profile.accounts.map { group in
            group.map { account in
                if account.address.lowercased() == address.lowercased() {
//                    return account.copyWith(emoji: emoji)
                }
                return account
            }
        }

        let updatedProfile = profile.updatingAccounts(to: updatedGroups)
        saveProfile(updatedProfile)
        log.debug("[ProfileInfo] Updated account emoji: \(address)")
    }

    /// Get account by address from current profile
    /// - Parameter address: The account address to find
    /// - Returns: The matching WalletAccount if found
    func getAccount(by address: String) -> WalletAccount? {
        currentProfile?.accounts
            .flatMap { $0 }
            .first { $0.address.lowercased() == address.lowercased() }
    }

    /// Get all accounts from current profile
    func getAllAccounts() -> [WalletAccount] {
        currentProfile?.accounts.flatMap { $0 } ?? []
    }

    /// Get accounts grouped by parent
    func getGroupedAccounts() -> [[WalletAccount]] {
        currentProfile?.accounts ?? []
    }
}
