//
//  StakingDetailViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 13/12/2022.
//

import Combine
import SwiftUI

class StakingDetailViewModel: ObservableObject {
    // MARK: Lifecycle

    init(provider: StakingProvider, node: StakingNode) {
        self.provider = provider
        self.node = node

        StakingManager.shared.$nodeInfos.sink { [weak self] nodes in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                if let newNode = nodes
                    .first(where: { $0.id == self.node.id && $0.nodeID == self.node.nodeID })
                {
                    self.node = newNode
                }
            }
        }.store(in: &cancelSets)
    }

    // MARK: Internal

    @Published
    var provider: StakingProvider
    @Published
    var node: StakingNode

    var availableAmount: Double {
        guard let token = WalletManager.shared.flowToken else {
            return 0
        }
        let balance = WalletManager.shared.getBalance(with: token)
        return balance.doubleValue
    }

    var currentProgress: Int {
        let startDate = StakingManager.shared.stakingEpochStartTime
        let now = Date()
        if startDate > now {
            return 0
        }

        let daySeconds = Double(24 * 60 * 60)
        let progressIndex =
            Int((now.timeIntervalSince1970 - startDate.timeIntervalSince1970) / daySeconds) + 1
        return min(progressIndex, 7)
    }

    func stakeAction() {
        Router.route(to: RouteMap.Wallet.stakeAmount(provider, isUnstake: false))
    }

    func claimStake() {
        guard let delegatorId = provider.delegatorId else {
            return
        }

        if node.tokensRewarded.decimalValue <= 0 {
            HUD.error(title: "stake_insufficient_balance".localized)
            return
        }

        Task {
            do {
                HUD.loading("staking_claim_rewards".localized)
                _ = try await StakingManager.shared.claimReward(
                    nodeID: node.nodeID,
                    delegatorId: delegatorId,
                    amount: node.tokensRewarded.decimalValue
                )
                HUD.dismissLoading()
            } catch {
                debugPrint(error)
                HUD.dismissLoading()
                HUD.error(title: "Error", message: error.localizedDescription)
            }
        }
    }

    func restake() {
        // TODO: FIX ME
        guard let delegatorId = provider.delegatorId else {
            return
        }

        if node.tokensRewarded.decimalValue <= 0 {
            HUD.error(title: "stake_insufficient_balance".localized)
            return
        }

        Task {
            do {
                HUD.loading("staking_reStake_rewards".localized)
                _ = try await StakingManager.shared.reStakeReward(
                    nodeID: node.nodeID,
                    delegatorId: delegatorId,
                    amount: node.tokensRewarded.decimalValue
                )
                HUD.dismissLoading()
            } catch {
                debugPrint(error)
                HUD.dismissLoading()
                HUD.error(title: "Error", message: error.localizedDescription)
            }
        }
    }

    func claimUnstakeAction() {
        guard let delegatorId = provider.delegatorId else {
            return
        }

        if node.tokensUnstaked.decimalValue <= 0 {
            HUD.error(title: "stake_insufficient_balance".localized)
            return
        }

        Task {
            do {
                HUD.loading()
                _ = try await StakingManager.shared.claimUnstake(
                    nodeID: node.nodeID,
                    delegatorId: delegatorId,
                    amount: node.tokensUnstaked.decimalValue
                )
                HUD.dismissLoading()
            } catch {
                debugPrint(error)
                HUD.dismissLoading()
                HUD.error(title: "Error", message: error.localizedDescription)
            }
        }
    }

    func restakeUnstakeAction() {
        guard let delegatorId = provider.delegatorId else {
            return
        }

        if node.tokensUnstaked.decimalValue <= 0 {
            HUD.error(title: "stake_insufficient_balance".localized)
            return
        }

        Task {
            do {
                HUD.loading()
                _ = try await StakingManager.shared.reStakeUnstake(
                    nodeID: node.nodeID,
                    delegatorId: delegatorId,
                    amount: node.tokensUnstaked.decimalValue
                )
                HUD.dismissLoading()
            } catch {
                debugPrint(error)
                HUD.dismissLoading()
                HUD.error(title: "Error", message: error.localizedDescription)
            }
        }
    }

    func unstakeAction() {
        Router.route(to: RouteMap.Wallet.stakeAmount(provider, isUnstake: true))
    }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()
}
