import BigInt
import Combine
import Foundation
import SwiftUI
import Web3Core

// MARK: - DeeplinkPath

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
        case let .send(item):
            return isLogin && !WalletManager.shared.activatedCoins.isEmpty && WalletManager.shared.flowToken != nil
        case .buy:
            return isLogin
        case .dapp:
            return true
        }
    }

    func handle() {
        guard canHandle else {
            return
        }
        switch self {
        case let .send(item):
            handleSend(item)
        case let .dapp(item):
            handleDapp(item)
        case let .buy(item):
            handleBuy(item)
        }
    }
}

// MARK: - Check Network

extension DeepLinkItem {
    private func checkNetworkIfNeed(metadata: DeepLinkMetadata) -> Bool {
        guard let str = metadata.parameters["network"], let network = FlowNetworkType(rawValue: str) else {
            if currentNetwork != .mainnet {
                showNetworkSwitchConfirmation(network: .mainnet, metadata: metadata)
            }
            return false
        }
        guard currentNetwork != network else {
            return false
        }
        showNetworkSwitchConfirmation(network: network, metadata: metadata)
        return true
    }

    private func showNetworkSwitchConfirmation(network: FlowNetworkType, metadata _: DeepLinkMetadata) {
        let alert = UIAlertController(
            title: "switch_network".localized,
            message: "switch_to_x".localized(network.rawValue),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "continue".localized, style: .default) { _ in
            self.switchNetwork(to: network)
            self.handle()
        })

        // add cancel
        alert.addAction(UIAlertAction(title: "action_cancel".localized, style: .cancel) { _ in

        })

        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    private func switchNetwork(to network: FlowNetworkType) {
        log.info("[Deeplink] switch to: \(network)")
        WalletManager.shared.changeNetwork(network)
    }
}

extension DeepLinkItem {
    private func handleSend(_ item: DeepLinkMetadata) {
        guard !WalletManager.shared.activatedCoins.isEmpty, let token = WalletManager.shared.flowToken else {
            return
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
    }

    private func handleDapp(_ item: DeepLinkMetadata) {
        guard let dappUrlString = item.parameters["url"], let dappUrl = URL(string: dappUrlString) else {
            log.warning("[DeepLink] invalid dapp URL:\(item.url)")
            return
        }
        Router.route(to: RouteMap.Explore.browser(dappUrl))
    }

    private func handleBuy(_: DeepLinkMetadata) {
        Router.route(to: RouteMap.Wallet.buyCrypto)
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
