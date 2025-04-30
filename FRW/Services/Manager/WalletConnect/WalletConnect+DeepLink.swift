//
//  WalletConnect+DeepLink.swift
//  FRW
//
//  Created by cat on 4/30/25.
//

import Foundation

// MARK: - DeepLink

extension WalletConnectManager {
    func parseWCUrl(_ url: URL) -> String? {
        guard let filtered = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .filter({ $0.name == "uri" && $0.value?.starts(with: "wc") ?? false }),
            let item = filtered.first,
            let uri = item.value
        else {
            return nil
        }
        return uri
    }

    func canHandleURL(_ url: URL) -> Bool {
        parseWCUrl(url) != nil
    }

    func handleURL(_ url: URL) {
        guard let uri = parseWCUrl(url) else {
            return
        }
        WalletConnectManager.shared.connect(link: uri)
    }
}
