//
//  StakeAmountViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 2/12/2022.
//

import Flow
import SwiftUI

// MARK: - StakeAmountViewModel.ErrorType

extension StakeAmountViewModel {
    enum ErrorType {
        case none
        case insufficientBalance
        case belowMinimumBalance
        case belowMinimumAmount

        // MARK: Internal

        var desc: String {
            switch self {
            case .none:
                return ""
            case .insufficientBalance:
                return "insufficient_balance".localized
            case .belowMinimumBalance:
                // TODO: Use localized to replace
                return "The balance cannot be less than 0.001"
            case .belowMinimumAmount:
                return "50 FLOW minimum required"
            }
        }
    }
}

// MARK: - StakeAmountViewModel

class StakeAmountViewModel: ObservableObject {
    // MARK: Lifecycle

    init(provider: StakingProvider, isUnstake: Bool) {
        self.provider = provider
        self.isUnstake = isUnstake

        let token = WalletManager.shared.flowToken
        balance = isUnstake ? (provider.currentNode?.stakingCount ?? 0) : WalletManager.shared
            .getBalance(with: token).doubleValue
    }

    // MARK: Internal

    @Published
    var provider: StakingProvider
    @Published
    var isUnstake: Bool

    @Published
    var inputText: String = ""
    @Published
    var inputTextNum: Double = 0
    @Published
    var balance: Double = 0
    @Published
    var showConfirmView: Bool = false
    @Published
    var errorType: StakeAmountViewModel.ErrorType = .none

    @Published
    var isRequesting: Bool = false

    var buttonState: VPrimaryButtonState {
        if isRequesting {
            return .loading
        }
        return .enabled
    }

    var inputNumAsUSD: Double {
        let flowToken = WalletManager.shared.flowToken
        let rate = CoinRateCache.cache.getSummary(by: flowToken?.contractId ?? "")?
            .getLastRate() ?? 0
        return inputTextNum * rate
    }

    var inputNumAsCurrencyString: String {
        "\(CurrencyCache.cache.currencySymbol)\(inputNumAsUSD.formatCurrencyString(considerCustomCurrency: true)) \(CurrencyCache.cache.currentCurrency.rawValue)"
    }

    var inputNumAsCurrencyStringInConfirmSheet: String {
        "\(CurrencyCache.cache.currencySymbol)\(inputNumAsUSD.formatCurrencyString(considerCustomCurrency: true))"
    }

    var yearReward: Double {
        inputTextNum * provider.rate
    }

    var yearRewardFlowString: String {
        yearReward.formatCurrencyString()
    }

    var yearRewardWithCurrencyString: String {
        let numString = (inputNumAsUSD * provider.rate)
            .formatCurrencyString(considerCustomCurrency: true)
        return "\(CurrencyCache.cache.currencySymbol)\(numString) \(CurrencyCache.cache.currentCurrency.rawValue)"
    }

    var isReadyForStake: Bool {
        errorType == .none && inputTextNum > 0
    }

    // MARK: Private

    private func refreshState() {
        if inputTextNum > balance {
            errorType = .insufficientBalance
            return
        }

        if inputTextNum < 50, !isUnstake {
            errorType = .belowMinimumAmount
            return
        }

        errorType = .none
    }
}

extension StakeAmountViewModel {
    func inputTextDidChangeAction(text: String) {
        inputText = text
        inputTextNum = inputText.doubleValue
        refreshState()
    }

    func percentAction(percent: Double) {
        inputText = "\((balance * percent).formatCurrencyString())"
    }

    func confirmSetupAction() {
        Router.dismiss()

        Task {
            if await StakingManager.shared.stakingSetup() == false {
                debugPrint("StakeAmountViewModel: setup account staking failed.")
                DispatchQueue.main.async {
                    HUD.error(StakingError.stakingSetupFailed)
                }
            } else {
                debugPrint("StakeAmountViewModel: setup account staking success.")
                await MainActor.run {
                    self.confirmStakeAction()
                }
            }
        }
    }

    func stakeBtnAction() {
        UIApplication.shared.endEditing()

        if showConfirmView {
            showConfirmView = false
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            showConfirmView = true
        }
    }

    private func stakingSetup() {
        Router.route(to: RouteMap.Wallet.stakeSetupConfirm(self))
    }

    private func stake() async throws -> Flow.ID {
        // check account staking is setup
        if !StakingManager.shared.isSetup {
            debugPrint("StakeAmountViewModel: account staking not setup")
            throw StakingError.stakingNeedSetup
        }

        if provider.delegatorId == nil {
            debugPrint(
                "StakeAmountViewModel: provider.delegatorId is nil, will create delegator id"
            )
            // create delegator id to stake (only first time)
            let address = WalletManager.shared.getPrimaryWalletAddress() ?? ""
            EventTrack.General
                .delegationCreated(
                    address: address,
                    nodeId: provider.id,
                    amount: inputTextNum
                )
            return try await FlowNetwork.createDelegatorId(
                providerId: provider.id,
                amount: inputTextNum
            )
        }

        guard let delegatorId = provider.delegatorId else {
            // can not be nil, something went wrong.
            debugPrint(
                "StakeAmountViewModel: delegatorId is still nil after fetch delegatorIds, something went wrong"
            )
            throw StakingError.unknown
        }

        debugPrint("StakeAmountViewModel: provider.delegatorId now get, will stake flow")
        return try await FlowNetwork.stakeFlow(
            providerId: provider.id,
            delegatorId: delegatorId,
            amount: inputTextNum
        )
    }

    private func unstake() async throws -> Flow.ID {
        if provider.delegatorId == nil {
            debugPrint(
                "StakeAmountViewModel: provider.delegatorId is nil, will create delegator id"
            )
        }

        guard let delegatorId = provider.delegatorId else {
            // can not be nil, something went wrong.
            debugPrint(
                "StakeAmountViewModel: delegatorId is still nil after fetch delegatorIds, something went wrong"
            )
            throw StakingError.unknown
        }

        debugPrint("StakeAmountViewModel: provider.delegatorId now get, will unstake flow")

        let txId = try await FlowNetwork.unstakeFlow(
            providerId: provider.id,
            delegatorId: delegatorId,
            amount: inputTextNum
        )
        return txId
    }

    func confirmStakeAction() {
        if isRequesting {
            return
        }

        isRequesting = true

        let failureBlock: (String) -> Void = { errorMsg in
            DispatchQueue.main.async {
                self.isRequesting = false
                HUD.error(title: errorMsg)
            }
        }

        let successBlock: (Flow.ID) -> Void = { txId in
            DispatchQueue.main.async {
                self.isRequesting = false
                self.showConfirmView = false
                let holder = TransactionManager.TransactionHolder(
                    id: txId,
                    type: .stakeFlow,
                    data: Data()
                )
                TransactionManager.shared.newTransaction(holder: holder)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Router.route(to: RouteMap.Wallet.backToTokenDetail)
                }
            }
        }

        Task {
            do {
                // check staking is enabled
                if try await FlowNetwork.stakingIsEnabled() == false {
                    debugPrint("StakeAmountViewModel: staking is disabled")
                    throw StakingError.stakingDisabled
                }

                let txId = isUnstake ? try await unstake() : try await stake()
                successBlock(txId)
            } catch StakingError.stakingNeedSetup {
                // run staking setup logic
                await MainActor.run {
                    self.isRequesting = false
                    self.stakingSetup()
                }
            } catch let error as StakingError {
                debugPrint("StakeAmountViewModel: catch StakingError \(error)")
                failureBlock(error.errorMessage)
            } catch {
                debugPrint("StakeAmountViewModel: catch extra error \(error)")
                failureBlock("request_failed".localized)
            }
        }
    }
}
