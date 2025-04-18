//
//  AppExternalLinks.swift
//  FRW
//
//  Created by Hao Fu on 11/11/2024.
//

import Foundation

enum AppExternalLinks: String, CaseIterable {
    case frw = "frw://"
    case fcw = "fcw://"
    case lilico = "lilico://"
    case frwUL = "https://frw-link.lilico.app"
    case fcwUL = "https://fcw-link.lilico.app"
    case wallet = "https://link.wallet.flow.com"

    // MARK: Internal

    static var allLinks: [String] {
        AppExternalLinks.allCases.map(\.rawValue)
    }

    var isUniversalLink: Bool {
        switch self {
        case .frwUL, .fcwUL, .wallet:
            return true
        default:
            return false
        }
    }

    static func exactWCLink(link: String) -> String {
        let newLink = link
            .replacingOccurrences(of: "wc%2Fwc", with: "wc")
            .replacingOccurrences(of: "wc/wc", with: "wc")

        return newLink
            .deletingPrefixes(allLinks.map { link in "\(link)/wc?uri=" })
            .deletingPrefixes(allLinks.map { link in "\(link)wc?uri=" })
            .deletingPrefixes(allLinks)
    }
}
