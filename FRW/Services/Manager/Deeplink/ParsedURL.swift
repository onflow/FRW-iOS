import Foundation

// MARK: - DeeplinkPath

enum DeeplinkPath: String {
    case send = "/send"
    case explore = "/explore"
    case dapp = "/dapp"
    case buy = "/buy"

    init?(path: String) {
        self.init(rawValue: path)
    }

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        self.init(path: components.path)
    }
}

struct ParsedURL {
    private static let whitelistedHosts = [
        "link.wallet.flow.com",
    ]
    let url: URL
    let host: String
    let path: DeeplinkPath
    let parameters: [String: String]
}

extension ParsedURL {
    init?(from url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            log.warning("[DeepLink] Invalid URL: \(url)")
            return nil
        }
        guard let path = DeeplinkPath(url: url) else {
            log.warning("[DeepLink] unsupported path: \(url)")
            return nil
        }
        guard let host = components.host else {
            log.warning("[DeepLink] empty host: \(url)")
            return nil
        }
        guard ParsedURL.whitelistedHosts.contains(host) else {
            log.warning("[DeepLink] unsupported host: \(url)")
            return nil
        }

        self.url = url
        self.host = host
        self.path = path

        if let queryItems = components.queryItems {
            parameters = queryItems.reduce(into: [String: String]()) { result, item in
                result[item.name] = item.value
            }
        } else {
            parameters = [:]
        }
    }
}
