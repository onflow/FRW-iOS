//
//  TrustProvider.swift
//  FRW
//
//  Created by cat on 2024/3/4.
//

import Foundation
import TrustWeb3Provider
import WalletCore

extension TrustWeb3Provider {
    static func flowConfig() -> TrustWeb3Provider? {
        guard let address = EVMAccountManager.shared.accounts.first?.showAddress else {
            return nil
        }
        let url = currentNetwork.evmURL.absoluteString
        let chainId = currentNetwork.networkID
        let config = TrustWeb3Provider.Config.EthereumConfig(
            address: address,
            chainId: chainId,
            rpcUrl: url
        )
        var isDebug = false
        #if DEBUG
            isDebug = true
        #endif
        return TrustWeb3Provider(config: .init(ethereum: config, isDebug: isDebug))
    }
}
