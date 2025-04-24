import BigInt
import Combine
import Foundation
import SwiftUI
import Web3Core

// MARK: - DeepLinkHandler

class DeepLinkHandler {
    static let shared = DeepLinkHandler()
    private var pendingItem: DeepLinkItem?
    private var cancellableSet = Set<AnyCancellable>()

    private init() {
        WalletManager.shared.$activatedCoins
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { _ in
                self.handlePaddingItem()
            }.store(in: &cancellableSet)
    }

    // MARK: - Public Methods

    func canHandleURL(_ url: URL) -> Bool {
        guard let item = DeepLinkItem(url: url) else {
            return false
        }
        let result = item.canHandle
        if !result {
            HUD.info(title: "Failed to open", message: "please create a wallet first")
        }
        return result
    }

    func handleURL(_ url: URL) {
        pendingItem = nil
        guard let item = DeepLinkItem(url: url) else {
            return
        }
        handleItem(item)
    }

    func handlePaddingItem() {
        if let item = pendingItem {
            pendingItem = nil
            handleItem(item)
        }
    }

    private func handleItem(_ item: DeepLinkItem) {
        let result = item.handle()
        if result == .waiting {
            pendingItem = item
        }
    }
}
