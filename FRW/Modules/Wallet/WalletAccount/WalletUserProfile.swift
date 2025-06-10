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
        info = LocalUserDefaults.shared.walletAccount ?? [:]
    }

    // MARK: Internal

    @Published var info: [String: [WalletUserProfile.User]]

    // MARK: Private

    private var key: String {
        guard let userId = UserManager.shared.activatedUID else {
            return "empty"
        }
        return "\(userId)"
    }

    private func saveCache() {
        LocalUserDefaults.shared.walletAccount = info
    }
}

// MARK: Logical processing

extension WalletUserProfile {
    func readInfo(at address: String) -> WalletUserProfile.User {
        let currentNetwork = currentNetwork
        if var list = info[key] {
            let lastUser = list.last { $0.network == currentNetwork && $0.address == address }
            if let user = lastUser {
                return user
            } else {
                let filterList = list.filter { $0.network == currentNetwork }
                let existList = filterList.map { $0.emoji }
                let nEmoji = generalInfo(count: 1, excluded: existList)?.first ?? .koala
                let user = WalletUserProfile.User(emoji: nEmoji, address: address)
                list.append(user)
                info[key] = list
                saveCache()
                return user
            }
        } else {
            let nEmoji = generalInfo(count: 1, excluded: [])?.first ?? .koala
            let model = WalletUserProfile.User(emoji: nEmoji, address: address)
            info[key] = [model]
            saveCache()
            return model
        }
    }

    func update(at address: String, emoji: WalletUserProfile.Emoji, name: String? = nil) {
        let currentNetwork = currentNetwork
        if var list = info[key] {
            if let index = list
                .lastIndex(where: { $0.network == currentNetwork && $0.address == address })
            {
                var user = list[index]
                user.emoji = emoji
                user.name = name ?? emoji.name
                list[index] = user
                info[key] = list
                saveCache()
            }
        }
    }

    private func generalInfo(count: Int, excluded: [Emoji]) -> [WalletUserProfile.Emoji]? {
        let list = Emoji.allCases
        return list.randomDifferentElements(limitCount: count, excluded: excluded)
    }
}

// MARK: data struct

extension WalletUserProfile {
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
    func randomDifferentElements(limitCount: Int, excluded: [Element]) -> [Element]? {
        guard count >= limitCount else {
            return nil // 确保数组中至少有指定数量的元素
        }

        var selectedElements: [Element] = []

        var num = count * 36
        for i in 0 ..< num {
            let element = randomElement()!
            if !selectedElements.contains(element), !excluded.contains(element) {
                selectedElements.append(element)
            }
            if selectedElements.count == limitCount {
                break
            }
        }

        return selectedElements
    }
}
