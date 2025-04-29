//
//  WalletManager+Insufficient.swift
//  FRW
//
//  Created by cat on 4/29/25.
//

import Foundation

extension WalletManager {
    var minimumStorageBalance: Decimal {
        guard let accountInfo else { return Self.fixedMoveFee }
        return accountInfo.storageFlow + Self.fixedMoveFee
    }

    var isStorageInsufficient: Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        guard accountInfo.storageCapacity >= accountInfo.storageUsed else { return true }
        return accountInfo.storageCapacity - accountInfo.storageUsed < Self.mininumStorageThreshold
    }

    var isBalanceInsufficient: Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        return accountInfo.balance < Self.minFlowBalance
    }

    func isBalanceInsufficient(for amount: Decimal) -> Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        return accountInfo.availableBalance - amount < Self.averageTransactionFee
    }

    func isFlowInsufficient(for amount: Decimal) -> Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        return accountInfo.balance - amount < Self.minFlowBalance
    }
}
