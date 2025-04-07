//
//  StakingInfo.swift
//  Flow Wallet
//
//  Created by Selina on 1/12/2022.
//

import Foundation

// MARK: - StakingNode

struct StakingNode: Codable {
    // MARK: Internal

    let id: Int
    let nodeID: String
    let tokensCommitted: Double
    let tokensStaked: Double
    let tokensUnstaking: Double
    let tokensRewarded: Double
    let tokensUnstaked: Double
    let tokensRequestedToUnstake: Double

    var stakingCount: Double {
        tokensCommitted + tokensStaked
    }

    var allStatusCount: Double {
        tokensStaked + tokensUnstaking + tokensRewarded + tokensUnstaked + tokensRequestedToUnstake
    }

    var isLilico: Bool {
        StakingProviderCache.cache.providers.first { $0.isLilico }?.id == nodeID
    }

    var tokenStakedASUSD: Double {
        let token = WalletManager.shared.flowToken
        let rate = CoinRateCache.cache.getSummary(by: token?.contractId ?? "")?.getLastRate() ?? 0.0
        return tokensStaked * coinRate
    }

    var dayRewards: Double {
        let apy = isLilico ? StakingManager.shared.apy : StakingDefaultNormalApy
        return stakingCount * apy / 365.0
    }

    var monthRewards: Double {
        dayRewards * 30
    }

    var dayRewardsASUSD: Double {
        dayRewards * coinRate
    }

    var monthRewardsASUSD: Double {
        monthRewards * coinRate
    }

    // MARK: Private

    private var coinRate: Double {
        let token = WalletManager.shared.flowToken
        return CoinRateCache.cache.getSummary(by: token?.contractId ?? "")?.getLastRate() ?? 0.0
    }
}

// MARK: - StakingDelegatorInner

struct StakingDelegatorInner: Codable {
    let type: String?
    let value: StakingDelegatorInner.Value1?
}

// MARK: StakingDelegatorInner.Value1

extension StakingDelegatorInner {
    struct Value1: Codable {
        let type: String?
        let value: [StakingDelegatorInner.Value1.Value2?]?
    }
}

// MARK: - StakingDelegatorInner.Value1.Value2

extension StakingDelegatorInner.Value1 {
    struct Value2: Codable {
        let key: StakingDelegatorInner.Value1.Value2.Key?
        let value: StakingDelegatorInner.Value1.Value2.Value?
    }
}

extension StakingDelegatorInner.Value1.Value2 {
    struct Key: Codable {
        let type: String?
        let value: String?
    }

    struct Value: Codable {
        let type: String?
        let value: [StakingDelegatorInner.Value1.Value2.Value.Value3?]?
    }
}

// MARK: - StakingDelegatorInner.Value1.Value2.Value.Value3

extension StakingDelegatorInner.Value1.Value2.Value {
    struct Value3: Codable {
        let key: StakingDelegatorInner.Value1.Value2.Value.Value3.Key?
    }
}

// MARK: - StakingDelegatorInner.Value1.Value2.Value.Value3.Key

extension StakingDelegatorInner.Value1.Value2.Value.Value3 {
    struct Key: Codable {
        let type: String?
        let value: String?
    }
}
