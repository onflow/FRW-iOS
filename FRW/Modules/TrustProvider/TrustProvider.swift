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
        
        var allAddresses: [String] = []
      if let eoa = WalletManager.shared.EOAs?.first {
        allAddresses.append(eoa.address)
      }
        if let coa = WalletManager.shared.coa {
        allAddresses.append(coa.address)
      }
      
      
        let url = currentNetwork.evmURL.absoluteString
        let chainId = currentNetwork.networkID
        let config = TrustWeb3Provider.Config.EthereumConfig(addresses: allAddresses, chainId: chainId, rpcUrl: url)
        
        var isDebug = false
        #if DEBUG
            isDebug = true
        #endif
        return TrustWeb3Provider(config: .init(ethereum: config, isDebug: isDebug))
    }
}
