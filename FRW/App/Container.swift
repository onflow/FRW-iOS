//
//  Container.swift
//  FRW
//
//  Created by Hao Fu on 7/4/2025.
//

import Foundation
import Factory

extension Container {
    var wallet: Factory<WalletManager> {
        self {
            WalletManager.shared
        }
    }
    
    var token: Factory<TokenBalanceHandler> {
        self {
            TokenBalanceHandler()
        }
    }
    
    var txManager: Factory<TransactionManager> {
        self {
            TransactionManager()
        }
    }
}
