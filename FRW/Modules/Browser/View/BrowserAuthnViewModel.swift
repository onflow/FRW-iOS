//
//  BrowserAuthnViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 6/9/2022.
//

import Flow
import SwiftUI

// MARK: - BrowserAuthnViewModel.Callback

extension BrowserAuthnViewModel {
    typealias Callback = (Bool) -> Void
}

// MARK: - BrowserAuthnViewModel

class BrowserAuthnViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        title: String,
        url: String,
        logo: String?,
        walletAddress: String?,
        network: Flow.ChainID? = nil,
        callback: @escaping BrowserAuthnViewModel.Callback
    ) {
        self.title = title
        urlString = url
        self.logo = logo
        self.network = network
        self.walletAddress = walletAddress
        self.callback = callback
    }

    deinit {
        callback?(false)
        WalletConnectManager.shared.reloadPendingRequests()
    }

    // MARK: Internal

    @Published
    var title: String
    @Published
    var urlString: String
    @Published
    var walletAddress: String?
    @Published
    var logo: String?
    @Published
    var network: Flow.ChainID?

    var inBlacklist: Bool {
        BlocklistHandler.shared.inBlacklist(url: urlString)
    }

    func didChooseAction(_ result: Bool) {
        Router.dismiss { [weak self] in
            guard let self else { return }
            callback?(result)
            callback = nil
        }
    }

    // MARK: Private

    private var callback: BrowserAuthnViewModel.Callback?
}
