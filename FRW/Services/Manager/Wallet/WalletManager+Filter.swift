//
//  WalletManager+Filter.swift
//  FRW
//
//  Created by cat on 5/6/25.
//

import Foundation

class TokenFilterModel: ObservableObject {
    @Published var hideDustToken: Bool = false {
        didSet {
            updateFilter()
        }
    }

    @Published var onlyShowVerified: Bool = false {
        didSet {
            updateFilter()
        }
    }

    @Published var hideTokens: Set<String> = []

    func isOpen(token: TokenModel) -> Bool {
        !hideTokens.contains(token.contractId)
    }

    func updateFilter() {
        var list = WalletManager.shared.activatedCoins
        let limitTokens = hideDustToken ? list.filter { ($0.balanceInUSD?.doubleValue ?? 0) < 1 }.map { $0.contractId } : []
        let unverifiedTokens = onlyShowVerified ? list.filter { !$0.isVerifiedValue }.map { $0.contractId } : []
        hideTokens = Set(limitTokens).union(Set(unverifiedTokens))
    }

    func switchToken(_ token: TokenModel) {
        if hideTokens.contains(token.contractId) {
            hideTokens.remove(token.contractId)
        } else {
            hideTokens.insert(token.contractId)
        }
        log.debug("[Token] switch \(hideTokens)")
    }
}
