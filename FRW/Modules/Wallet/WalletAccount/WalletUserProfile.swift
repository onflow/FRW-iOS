//
//  WalletUserProfile.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Flow
import Foundation
import SwiftUI

// MARK: - WalletAccount

class WalletUserProfile: ObservableObject {
    // MARK: Lifecycle

    init() {
        if let newData = LocalUserDefaults.shared.walletUserProfiles, !newData.isEmpty {
            info = newData
        } else if let oldData = LocalUserDefaults.shared.walletAccount, !oldData.isEmpty {
            var migrated: [String: [String: [WalletUserProfile.User]]] = [:]
            for (userId, userList) in oldData {
                for user in userList {
                    let mainAccountAddress = user.address
                    if migrated[userId] == nil {
                        migrated[userId] = [:]
                    }
                    if migrated[userId]![mainAccountAddress] == nil {
                        migrated[userId]![mainAccountAddress] = []
                    }
                    migrated[userId]![mainAccountAddress]?.append(user)
                }
            }
            info = migrated
            LocalUserDefaults.shared.walletUserProfiles = migrated
            LocalUserDefaults.shared.walletAccount = nil
        } else {
            info = [:]
        }
    }

    // MARK: Internal

    @Published var info: [String: [String: [WalletUserProfile.User]]]

    // MARK: Private

    private var key: String {
        guard let userId = UserManager.shared.activatedUID else {
            return "empty"
        }
        return "\(userId)"
    }

    private func saveCache() {
        LocalUserDefaults.shared.walletUserProfiles = info
    }
}

// MARK: Logical processing

extension WalletUserProfile {
    func readInfo(at address: String) -> WalletUserProfile.User {
        let mainAddress = mainAddress(by: address)
        if var addressDict = info[key] {
            if var list = addressDict[mainAddress] {
                let lastUser = list.last { $0.address == address }
                if let user = lastUser {
                    return user
                } else {
                    let existList = list.map { $0.emoji }
                    let nEmoji = generalInfo(excluded: existList)
                    let user = WalletUserProfile.User(emoji: nEmoji, address: address)
                    list.append(user)
                    addressDict[mainAddress] = list
                    info[key] = addressDict
                    saveCache()
                    return user
                }
            } else {
                let nEmoji = generalInfo(excluded: [])
                let model = WalletUserProfile.User(emoji: nEmoji, address: address)
                addressDict[mainAddress] = [model]
                info[key] = addressDict
                saveCache()
                return model
            }
        } else {
            let nEmoji = generalInfo(excluded: [])
            let model = WalletUserProfile.User(emoji: nEmoji, address: address)
            info[key] = [mainAddress: [model]]
            saveCache()
            return model
        }
    }

    private func mainAddress(by address: String) -> String {
        UserManager.shared.mainAccount(by: address)?.infoAddress ?? address
    }

    func update(at address: String, emoji: WalletUserProfile.Emoji, name: String? = nil) {
        let mainAccountAddress = address
        if var addressDict = info[key] {
            if var list = addressDict[mainAccountAddress] {
                if let index = list.lastIndex(where: { $0.address == address }) {
                    var user = list[index]
                    user.emoji = emoji
                    user.name = name ?? emoji.name
                    list[index] = user
                    addressDict[mainAccountAddress] = list
                    info[key] = addressDict
                    saveCache()
                }
            }
        }
    }

    private func generalInfo(excluded: [Emoji]) -> WalletUserProfile.Emoji {
        let list = Emoji.allCases
        return list.randomDifferentElements(excluded: excluded) ?? .avocado
    }
}

// MARK: data struct

extension WalletUserProfile {
    enum Emoji: String, CaseIterable, Codable, Equatable {
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
            switch self {
            case .lion:
                Color(hex: "#FFA600")
            case .panda:
                Color(hex: "#EEEEED")
            case .butterfly:
                Color(hex: "#36A5F8")
            case .loong:
                Color(hex: "#AEE676")
            case .peach:
                Color(hex: "#FBB06B")
            case .lemon:
                Color(hex: "#FDEF85")
            case .chestnut:
                Color(hex: "#EBCA84")
            case .avocado:
                Color(hex: "#B2C45C")
            case .koala:
                Color(hex: "#DFCFC8")
            case .penguin:
                Color(hex: "#FFCB6C")
            case .cherry:
                Color(hex: "#FED5DB")
            case .coconut:
                Color(hex: "#E3CAAA")
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
    }

    struct User: Codable {
        // MARK: Lifecycle

        init(emoji: WalletUserProfile.Emoji, address: String) {
            self.emoji = emoji
            name = emoji.name
            self.address = address
            network = currentNetwork
        }

        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<WalletUserProfile.User.CodingKeys> = try decoder
                .container(keyedBy: WalletUserProfile.User.CodingKeys.self)
            do {
                emoji = try container.decode(
                    WalletUserProfile.Emoji.self,
                    forKey: WalletUserProfile.User.CodingKeys.emoji
                )
            } catch {
                emoji = WalletUserProfile.Emoji.avocado
            }

            name = try container.decode(
                String.self,
                forKey: WalletUserProfile.User.CodingKeys.name
            )
            address = try container.decode(
                String.self,
                forKey: WalletUserProfile.User.CodingKeys.address
            )
            network = try container.decode(
                Flow.ChainID.self,
                forKey: WalletUserProfile.User.CodingKeys.network
            )
        }

        // MARK: Internal

        var emoji: WalletUserProfile.Emoji
        var name: String
        var address: String
        var network: Flow.ChainID
    }
}

extension Array where Element: Equatable {
    func randomDifferentElements(excluded: [Element]) -> Element? {
        guard !isEmpty else { return nil }
        let available = filter { !excluded.contains($0) }
        if !available.isEmpty {
            return available.randomElement()
        } else {
            return randomElement()
        }
    }
}
