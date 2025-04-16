//
//  UrlProvider.swift
//  FRW
//
//  Created by Antonio Bello on 11/20/24.
//

import Foundation
import Flow

enum AccountType {
    case flow, evm

    init(isEvm: Bool) {
        self = isEvm ? .evm : .flow
    }

    var accountPath: String {
        switch self {
        case .flow:
            return "account"
        case .evm:
            return "address"
        }
    }

    static var current: Self {
        return EVMAccountManager.shared.selectedAccount == nil ? .flow : .evm
    }
}

extension Flow.ChainID {
    func getTransactionHistoryUrl(accountType: AccountType, transactionId: String) -> URL? {
        let baseUrl = getHistoryBaseUrl(accountType: accountType)
        return URL(string: "\(baseUrl)/tx/\(transactionId)")
    }
    
    func getAccountUrl(accountType: AccountType, address: String) -> URL? {
        let baseUrl = getHistoryBaseUrl(accountType: accountType)
        let path = accountType.accountPath
        return URL(string: "\(baseUrl)/\(path)/\(address)")
    }
    
    private func getHistoryBaseUrl(accountType: AccountType) -> String {
        return switch (accountType, self) {
        case (.evm, .testnet): "https://evm-testnet.flowscan.io"
        case (.evm, .mainnet): "https://evm.flowscan.io"
            
        case (.flow, .testnet): "https://testnet.flowscan.io"
        case (.flow, .mainnet): "https://www.flowscan.io"
        default:
            "https://www.flowscan.io"
        }
    }
}
