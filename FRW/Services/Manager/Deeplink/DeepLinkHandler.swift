import Combine
import Foundation
import SwiftUI

// MARK: - DeepLinkHandler

class DeepLinkHandler {
    static let shared = DeepLinkHandler()
    private var pendingURL: ParsedURL?
    private var cancellableSet = Set<AnyCancellable>()

    private init() {
        WalletManager.shared.$activatedCoins
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { _ in
                if let url = self.pendingURL {
                    self.handleItem(parsedURL: url)
                }
            }.store(in: &cancellableSet)
    }

    // MARK: - Public Methods

    func canHandleURL(_ url: URL) -> Bool {
        guard ParsedURL(from: url) != nil else {
            return false
        }
        return true
    }

    func handleURL(_ url: URL) {
        guard let parsedURL = ParsedURL(from: url) else {
            return
        }
        // handle netword mismatch
        guard !needHandleNetwork(parsedURL) else {
            return
        }

        handleItem(parsedURL: parsedURL)
    }

    // MARK: - Private Methods

    private func handleItem(parsedURL: ParsedURL) {
        switch parsedURL.path {
        case .send:
            handleSend(parsedURL: parsedURL)
        case .explore:
            handleExplore(parsedURL: parsedURL)
        case .dapp:
            handleDapp(parsedURL: parsedURL)
        case .buy:
            handleBuy(parsedURL: parsedURL)
        }
    }
}

// Handle Network
extension DeepLinkHandler {
    private func needHandleNetwork(_ parsedURL: ParsedURL) -> Bool {
        guard let str = parsedURL.parameters["network"], let network = FlowNetworkType(rawValue: str) else {
            return false
        }
        showNetworkSwitchConfirmation(network: network, parsedURL: parsedURL)
        return true
    }

    private func showNetworkSwitchConfirmation(network: FlowNetworkType, parsedURL: ParsedURL) {
        let alert = UIAlertController(
            title: "switch_network".localized,
            message: "switch_to_x".localized(network.rawValue),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "continue".localized, style: .default) { [weak self] _ in
            self?.switchNetwork(to: network)
            self?.handleItem(parsedURL: parsedURL)
        })

        // add cancel
        alert.addAction(UIAlertAction(title: "action_cancel".localized, style: .cancel) { [weak self] _ in

            self?.pendingURL = nil
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

extension DeepLinkHandler {
    private func handleSend(parsedURL: ParsedURL) {
        guard !WalletManager.shared.activatedCoins.isEmpty, let token = WalletManager.shared.flowToken else {
            pendingURL = parsedURL
            return
        }
        let toAddress = parsedURL.parameters["recipient"]
        var amount: Decimal?
        if let value = parsedURL.parameters["value"] {
            if value.hasHexPrefix() {
                // TODO: six why handle address?
            }
            if value.isNumber {
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

    private func handleExplore(parsedURL: ParsedURL) {
        guard let dappUrlString = parsedURL.parameters["url"], let dappUrl = URL(string: dappUrlString) else {
            log.warning("[DeepLink] invalid dapp URL:\(parsedURL.url)")
            return
        }
        Router.route(to: RouteMap.Explore.browser(dappUrl))
    }

    private func handleDapp(parsedURL: ParsedURL) {
        guard let dappUrlString = parsedURL.parameters["url"], let dappUrl = URL(string: dappUrlString) else {
            log.warning("[DeepLink] invalid dapp URL:\(parsedURL.url)")
            return
        }
        Router.route(to: RouteMap.Explore.browser(dappUrl))
    }

    private func handleBuy(parsedURL _: ParsedURL) {
        Router.route(to: RouteMap.Wallet.buyCrypto)
    }
}
