import BigInt
import Combine
import Flow
import Foundation
import SwiftUI
import Web3Core

// MARK: - DeeplinkPath

extension DeepLinkItem {
    enum Result {
        case done
        case waiting
        case ignore
        case failed
    }
}

enum DeepLinkItem {
    case send(DeepLinkMetadata)
    case dapp(DeepLinkMetadata)
    case buy(DeepLinkMetadata)

    init?(url: URL) {
        guard let item = DeepLinkMetadata(from: url) else {
            return nil
        }
        switch item.path {
        case "/send":
            self = .send(item)
        case "/dapp":
            self = .dapp(item)
        case "/buy":
            self = .buy(item)
        default:
            return nil
        }
    }

    var canHandle: Bool {
        let isLogin = UserManager.shared.isLoggedIn
        switch self {
        case .send, .buy:
            return isLogin
        case .dapp:
            return true
        }
    }

    var needWaitingData: Bool {
        switch self {
        case .send, .buy:
            return WalletManager.shared.activatedCoins.isEmpty
        default:
            return false
        }
    }

    func handle() -> DeepLinkItem.Result {
        guard canHandle else {
            return .failed
        }

        guard !needWaitingData else {
            return .waiting
        }

        switch self {
        case let .send(item):
            return handleSend(item)
        case let .dapp(item):
            return handleDapp(item)
        case let .buy(item):
            return handleBuy(item)
        }
    }
}

// MARK: - Check Network

extension DeepLinkItem {
    private func needSwitchNetwork(metadata: DeepLinkMetadata) -> Bool {
        guard currentNetwork == .mainnet else {
            return true
        }

        guard let str = metadata.parameters["network"], let network = Flow.ChainID(rawValue: str) else {
            return false
        }
        guard currentNetwork != network else {
            return false
        }
        return true
    }

    private func showNetworkSwitch() {
        AlertViewController.showSwitchNetworkAlert { _ in
        }
    }
}

extension DeepLinkItem {
    private func handleSend(_ item: DeepLinkMetadata) -> DeepLinkItem.Result {
        guard !WalletManager.shared.activatedCoins.isEmpty, let token = WalletManager.shared.flowToken else {
            return .waiting
        }
        guard !needSwitchNetwork(metadata: item) else {
            showNetworkSwitch()
            return .waiting
        }
        let toAddress = item.parameters["recipient"]
        var amount: Decimal?
        if let value = item.parameters["value"] {
            if value.hasHexPrefix() {
                let hexString = String(value.dropFirst(2))
                if let bigUInt = BigUInt(hexString, radix: 16) {
                    let balance = Utilities.formatToPrecision(bigUInt, units: .custom(18), formattingDecimals: 18)
                    amount = Decimal(string: balance)
                }
            } else if value.isNumber {
                amount = Decimal(string: value)
            }
        }

        let contract = Contact(
            address: toAddress,
            avatar: nil,
            contactName: "-",
            contactType: .none,
            domain: nil,
            id: -1,
            username: nil,
            user: nil
        )
        Router.route(to: RouteMap.Wallet.sendAmount(contract, token, isPush: false, amount: amount))
        return .done
    }

    private func handleDapp(_ item: DeepLinkMetadata) -> DeepLinkItem.Result {
        guard let dappUrlString = item.parameters["url"], let dappUrl = URL(string: dappUrlString) else {
            log.warning("[DeepLink] invalid dapp URL:\(item.url)")
            return .failed
        }
        Router.route(to: RouteMap.Explore.browser(dappUrl))
        return .done
    }

    private func handleBuy(_: DeepLinkMetadata) -> DeepLinkItem.Result {
        Router.route(to: RouteMap.Wallet.buyCrypto)
        return .done
    }
}

// MARK: - Metadata

struct DeepLinkMetadata {
    private static let whitelistedHosts = [
        "link.wallet.flow.com",
    ]
    let url: URL
    let host: String
    let path: String
    let parameters: [String: String]

    init?(from url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            log.warning("[DeepLink] Invalid URL: \(url)")
            return nil
        }

        guard let host = components.host else {
            log.warning("[DeepLink] empty host: \(url)")
            return nil
        }
        guard DeepLinkMetadata.whitelistedHosts.contains(host) else {
            log.warning("[DeepLink] unsupported host: \(url)")
            return nil
        }

        self.url = url
        self.host = host
        path = components.path

        if let queryItems = components.queryItems {
            parameters = queryItems.reduce(into: [String: String]()) { result, item in
                result[item.name] = item.value
            }
        } else {
            parameters = [:]
        }
    }
}
