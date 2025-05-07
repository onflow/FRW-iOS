//
//  WalletManager+Filter.swift
//  FRW
//
//  Created by cat on 5/6/25.
//

import Foundation

final class TokenFilterModel: ObservableObject, Codable {
    @Published var hideDustToken: Bool = false

    @Published var onlyShowVerified: Bool = false

    @Published var hideTokens: Set<String> = []

    init() {}

    func isOpen(token: TokenModel) -> Bool {
        !hideTokens.contains(token.contractId)
    }

    func updateFilter() {
        var list = WalletManager.shared.activatedCoins
        let limitTokens = hideDustToken ? list.filter { ($0.balanceInUSD?.doubleValue ?? 0) < 1 }.map { $0.contractId } : []
        let unverifiedTokens = onlyShowVerified ? list.filter { !$0.isVerifiedValue }.map { $0.contractId } : []
        hideTokens = Set(limitTokens).union(Set(unverifiedTokens))
        LocalUserDefaults.shared.filterTokens = self
    }

    func switchToken(_ token: TokenModel) {
        if hideTokens.contains(token.contractId) {
            hideTokens.remove(token.contractId)
        } else {
            hideTokens.insert(token.contractId)
        }
        LocalUserDefaults.shared.filterTokens = self
        log.debug("[Token] switch \(hideTokens)")
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case hideDustToken
        case onlyShowVerified
        case hideTokens
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hideDustToken = try container.decode(Bool.self, forKey: .hideDustToken)
        onlyShowVerified = try container.decode(Bool.self, forKey: .onlyShowVerified)
        hideTokens = try container.decode(Set<String>.self, forKey: .hideTokens)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hideDustToken, forKey: .hideDustToken)
        try container.encode(onlyShowVerified, forKey: .onlyShowVerified)
        try container.encode(hideTokens, forKey: .hideTokens)
    }
}
