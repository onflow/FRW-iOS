//
//  WalletConnect+Tools.swift
//  FRW
//
//  Created by cat on 2023/11/30.
//

import Foundation
import WalletConnectSign

extension Sign {
    enum FlowWallet {
        static var blockchain: Blockchain {
            Blockchain("flow:\(currentNetwork.name)")!
        }

        static func namespaces(
            _ methods: Set<String>,
            event: Set<String> = []
        ) -> [String: ProposalNamespace] {
            let blockchains: [Blockchain] = [FlowWallet.blockchain]
            let namespaces: [String: ProposalNamespace] = [blockchain.namespace: ProposalNamespace(
                chains: blockchains,
                methods: methods,
                events: event
            )]
            return namespaces
        }
    }
}
