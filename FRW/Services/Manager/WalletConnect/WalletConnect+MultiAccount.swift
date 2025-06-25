//
//  WalletConnect+MultiAccount.swift
//  FRW
//
//  Created by cat on 6/23/25.
//

import Foundation
import WalletConnectPairing
import WalletConnectSign

// MARK: - for Account

extension WalletConnectManager {
    @discardableResult
    func connectURIForAccount() async throws -> WalletConnectURI {
        let methods: Set<String> = [
            FCLWalletConnectMethod.addMultiAccount.rawValue,
        ]
        let namespaces = Sign.FlowWallet.namespaces(methods)
        let uri = try await Sign.instance.connect(requiredNamespaces: namespaces)
        return uri
    }
}

// MARK: - For Profile

extension WalletConnectManager {
    @discardableResult
    func connectURIForProfile() async throws -> WalletConnectURI {
        let methods: Set<String> = [
            FCLWalletConnectMethod.addKeyToProfile.rawValue,
        ]
        let namespaces = Sign.FlowWallet.namespaces(methods)
        let uri = try await Sign.instance.connect(requiredNamespaces: namespaces)
        return uri
    }
}
