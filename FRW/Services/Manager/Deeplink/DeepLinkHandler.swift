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
                if let item = self.pendingItem {
                    item.handle()
                }
            }.store(in: &cancellableSet)
    }

    // MARK: - Public Methods

    func canHandleURL(_ url: URL) -> Bool {
        guard let item = DeepLinkItem(url: url) else {
            return false
        }
        return item.canHandle
    }

    func handleURL(_ url: URL) {
        guard let item = DeepLinkItem(url: url) else {
            return
        }
        item.handle()
    }
}
