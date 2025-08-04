//
//  BridgeModels.swift
//  FRW
//
//  Auto-generated from TypeScript bridge types
//  Do not edit manually
//

import Foundation

enum RNBridge {
    enum AccountType: String, Codable {
        case main = "main"
        case child = "child"
        case evm = "evm"
    }

    struct EmojiInfo: Codable {
        let emoji: String
        let name: String
        let color: String
    }

    struct Contact: Codable {
        let id: String
        let name: String
        let address: String
        let avatar: String?
        let username: String?
        let contactName: String?
    }

    struct AddressBookContact: Codable {
        let id: String
        let name: String
        let address: String
        let avatar: String?
        let username: String?
        let contactName: String?
    }

    struct WalletAccount: Codable {
        let id: String
        let name: String
        let address: String
        let emojiInfo: EmojiInfo?
        let parentEmoji: EmojiInfo?
        let avatar: String?
        let isActive: Bool
        let type: AccountType?
    }

    struct RecentContactsResponse: Codable {
        let contacts: [Contact]
    }

    struct WalletAccountsResponse: Codable {
        let accounts: [WalletAccount]
    }

    struct AddressBookResponse: Codable {
        let contacts: [AddressBookContact]
    }

}
