//
//  AccountModel.swift
//  FRW
//
//  Created by cat on 6/3/25.
//

import Foundation

struct AccountModel {
    var account: AccountInfoProtocol
    /// not nil when account type is coa or child,other is nil
    var mainAccount: AccountInfoProtocol?
    var flowCount: String
    var nftCount: UInt
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
            amount += "\(flowCount.formatCurrencyString()) Flow" + " | "
        }
        if nftCount >= 0 {
            amount += "\(nftCount) NFT's"
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
