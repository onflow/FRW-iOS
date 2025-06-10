// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let addressBook = try? newJSONDecoder().decode(Contact.self, from: jsonData)

import Foundation

extension Contact {
    enum ContactType: Int, Codable {
        case external = 0
        case user = 1
        case domain = 2
    }

    enum DomainType: Int, Codable, CaseIterable {
        case unknown = 0
        case find = 1
        case flowns = 2
        case meow = 3

        // MARK: Internal

        var domain: String {
            switch self {
            case .unknown:
                return ""
            case .find:
                return "find"
            case .flowns:
                return "fn"
            case .meow:
                return "meow"
            }
        }
    }

    struct Domain: Codable {
        let domainType: DomainType?
        let value: String?
    }
}

// MARK: - Contact

struct Contact: Codable, Identifiable {
    enum WalletType: String, Codable {
        case flow
        case evm
        case link

        // MARK: Internal

        var trackName: String {
            switch self {
            case .flow:
                "flow"
            case .evm:
                "coa"
            case .link:
                "child"
            }
        }
    }

    let address, avatar, contactName: String?
    let contactType: ContactType?
    let domain: Domain?
    let id: Int
    let username: String?
    var user: WalletUserProfile.User? = nil
    var walletType: WalletType? = .flow

    var needShowLocalAvatar: Bool {
        contactType == .domain
    }

    var localAvatar: String? {
        switch domain?.domainType {
        case .find:
            return "icon-find"
        case .flowns:
            return "icon-flowns"
        case .meow:
            return "logo"
        default:
            return nil
        }
    }

    var name: String {
        if let username = username, !username.isEmpty {
            return username
        }

        if let contactName = contactName, !contactName.isEmpty {
            return contactName
        }

        return ""
    }

    var displayName: String {
        if let emojiName = user?.name, !emojiName.isEmpty {
            return emojiName
        }
        if let username = username, !username.isEmpty {
            return username
        }

        if let contactName = contactName, !contactName.isEmpty {
            return contactName
        }
        return "no name"
    }

    var uniqueId: String {
        "\(address ?? "")-\(domain?.domainType?.rawValue ?? 0)-\(name)-\(contactType?.rawValue ?? 0)"
    }
}

// MARK: Equatable

extension Contact: Equatable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.address?.lowercased() == rhs.address?.lowercased()
    }
}
