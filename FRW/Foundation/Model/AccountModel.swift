//
//  AccountModel.swift
//  FRW
//
//  Created by cat on 6/3/25.
//

import Foundation

struct AccountModel: Equatable {
    static func == (lhs: AccountModel, rhs: AccountModel) -> Bool {
        lhs.account.infoAddress == rhs.account.infoAddress
    }

    var account: any AccountInfoProtocol
    /// not nil when account type is coa or child,other is nil
    var mainAccount: (any AccountInfoProtocol)?
    var flowCount: String
    var nftCount: UInt
    var linkedAccounts: [AccountModel]
}

// MARK: - UI

extension AccountModel {
    var hideFlow: Bool {
        account.accountType == .child
    }

    var showAmount: String {
        var amount = ""
        let flowCount = Double(flowCount) ?? 0
        if flowCount >= 0 {
            amount += "\(flowCount.formatCurrencyString()) Flow"
        }
        return amount
    }

    func isSelected(_ address: String) -> Bool {
        account.infoAddress == address
    }

    var isMain: Bool {
        account.accountType == .main
    }

    var isCoa: Bool {
        account.accountType == .coa
    }

    var isChild: Bool {
        account.accountType == .child
    }
}
