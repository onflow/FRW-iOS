//
//  StakingDetailView.swift
//  Flow Wallet
//
//  Created by Selina on 18/11/2022.
//

import SwiftUI

struct StakingDetailView: RouteableView {
    // MARK: Lifecycle

    init(provider: StakingProvider, node: StakingNode) {
        _vm = StateObject(wrappedValue: StakingDetailViewModel(provider: provider, node: node))
    }

    // MARK: Internal

    @State
    var progressMax: Int = 7

    var title: String {
        "staking_detail".localized
    }

    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        .large
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 12) {
                    summaryCardView
                    unstakedCardView
                    progressCardView
                    if vm.node.tokensCommitted > 0 {
                        stakeCommitedCardView
                    }

                    if vm.node.tokensUnstaking > 0 {
                        unstakeInProgressCardView
                    }

                    if vm.node.tokensRequestedToUnstake > 0 {
                        requetUnstakeInProgressCardView
                    }

                    rewardCardView
                    stakingListView
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 20 + 64 + 20)
            }

            controlContainerView
                .padding(.bottom, 20)
        }
        .backgroundFill(.LL.deepBg)
        .applyRouteable(self)
        .tracedView(self)
    }

    var controlContainerView: some View {
        HStack(spacing: 13) {
            Button {
                vm.unstakeAction()
            } label: {
                Text("stake_unstake".localized)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .background(Color.LL.Neutrals.neutrals6)
                    .cornerRadius(12)
            }

            Button {
                vm.stakeAction()
            } label: {
                Text("stake".localized)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(Color.white)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .background(Color.LL.stakeMain)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color.LL.deepBg)
                .shadow(color: Color(hex: "#333333", alpha: 0.08), x: 0, y: 12, blur: 24)
        }
        .padding(.horizontal, 18)
    }

    var summaryCardView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("staked_flow".localized)
                .font(.inter(size: 14, weight: .bold))
                .foregroundColor(Color.LL.Neutrals.text)
                .padding(.top, 18)
                .padding(.horizontal, 18)

            Spacer()

            HStack(alignment: .bottom, spacing: 0) {
                Text(
                    "\(CurrencyCache.cache.currencySymbol)\(vm.node.tokenStakedASUSD.formatCurrencyString(digits: 3, considerCustomCurrency: true))"
                )
                .font(.inter(size: 32, weight: .semibold))
                .foregroundColor(Color.LL.Neutrals.text)

                Text(CurrencyCache.cache.currentCurrency.rawValue)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .padding(.leading, 4)
                    .padding(.bottom, 5)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 15)

            HStack(spacing: 4) {
                Image("flow")
                    .resizable()
                    .frame(width: 16, height: 16)

                Text(vm.node.tokensStaked.formatCurrencyString(digits: 3))
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Text("Flow")
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)

                Divider()
                    .frame(width: 1, height: 12)
                    .background(Color.LL.Neutrals.note)

                Text("\(vm.availableAmount.formatCurrencyString(digits: 3))")
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Text("stake_flow_available".localized)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 15)
            .padding(.horizontal, 18)

            VStack(alignment: .leading, spacing: 0) {
                Text("staking_rewards".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .padding(.bottom, 4)

                HStack(spacing: 0) {
                    Text("\(vm.node.tokensRewarded.formatCurrencyString(digits: 3))")
                        .font(.inter(size: 24, weight: .semibold))
                        .foregroundColor(Color.LL.Neutrals.text)

                    Text("Flow")
                        .font(.inter(size: 14, weight: .medium))
                        .foregroundColor(Color.LL.Neutrals.text4)
                        .padding(.leading, 6)

                    Spacer()

                    HStack {
                        Button {
                            vm.restake()
                        } label: {
                            Text("staking_reStake".localized)
                                .font(.inter(size: 14, weight: .bold))
                                .foregroundColor(Color.LL.Neutrals.text)
                                .frame(width: 80, height: 32)
                                .background(Color.LL.deepBg)
                                .cornerRadius(12)
                        }

                        Button {
                            vm.claimStake()
                        } label: {
                            Text("staking_claim".localized)
                                .font(.inter(size: 14, weight: .bold))
                                .foregroundColor(Color.LL.Neutrals.text)
                                .frame(width: 80, height: 32)
                                .background(Color.LL.deepBg)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .frame(height: 90)
            .padding(.horizontal, 18)
            .background {
                Rectangle()
                    .fill(.linearGradient(
                        colors: [Color.LL.Neutrals.background.opacity(0.4), Color(hex: "#FAFAFA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
        }
        .frame(height: 236)
        .background {
            Image("bg-stake-detail-card")
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        .cornerRadius(12)
    }

    var progressCardView: some View {
        VStack(spacing: 10) {
            // progress bar
            HStack(spacing: 2) {
                ForEach(0 ..< progressMax, id: \.self) { index in
                    Rectangle()
                        .foregroundColor(
                            index < vm.currentProgress ? Color.LL.stakeMain : Color
                                .clear
                        )
                        .cornerRadius(
                            index == vm.currentProgress - 1 ? 12 : 0,
                            corners: [.topRight, .bottomRight]
                        )
                }
            }
            .frame(height: 8)
            .background(Color.LL.deepBg)
            .cornerRadius(12)

            // time section title
            HStack {
                Text("stake_epoch_starts")
                    .font(.inter(size: 12, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text4)

                Spacer()

                Text("stake_epoch_ends")
                    .font(.inter(size: 12, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text4)
            }

            // time values
            HStack {
                Text(StakingManager.shared.stakingEpochStartTime.ymdString)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Spacer()

                Text(StakingManager.shared.stakingEpochEndTime.ymdString)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)
            }
        }
        .padding(.all, 18)
        .background(Color.LL.Neutrals.background)
        .cornerRadius(16)
    }

    var unstakedCardView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("stake_unstaked_amount".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Spacer()
            }

            HStack(spacing: 0) {
                Text("\(vm.node.tokensUnstaked.formatCurrencyString(digits: 3))")
                    .font(.inter(size: 24, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Text("Flow")
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text4)
                    .padding(.leading, 6)

                Spacer()

                HStack {
                    Button {
                        vm.restakeUnstakeAction()
                    } label: {
                        Text("staking_reStake".localized)
                            .font(.inter(size: 14, weight: .bold))
                            .foregroundColor(Color.LL.Neutrals.text)
                            .frame(width: 80, height: 32)
                            .background(Color.LL.deepBg)
                            .cornerRadius(12)
                    }

                    Button {
                        vm.claimUnstakeAction()
                    } label: {
                        Text("staking_claim".localized)
                            .font(.inter(size: 14, weight: .bold))
                            .foregroundColor(Color.LL.Neutrals.text)
                            .frame(width: 80, height: 32)
                            .background(Color.LL.deepBg)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.all, 18)
        .background(Color.LL.Neutrals.background)
        .cornerRadius(16)
    }

    var stakeCommitedCardView: some View {
        VStack(spacing: 6) {
            HStack {
                Text("stake_commited".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Spacer()

                Text("+\(vm.node.tokensCommitted.formatCurrencyString(digits: 3))")
                    .font(.inter(size: 20, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)

                Text("Flow")
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text4)
            }

            HStack(spacing: 5) {
                Image("icon-clock-countdown")
                    .renderingMode(.template)
                    .foregroundColor(Color.LL.Success.success1)
                Text("stake_committed".localized)
                    .font(.inter(size: 12, weight: .medium))
                    .foregroundColor(Color.LL.Success.success1)

                Spacer()

                Text("stake_progress_desc".localized)
                    .font(.inter(size: 12))
                    .foregroundColor(Color.LL.Neutrals.text4)
            }
        }
        .padding(.all, 18)
        .background(Color.LL.Neutrals.background)
        .cornerRadius(16)
    }

    var requetUnstakeInProgressCardView: some View {
        VStack(spacing: 6) {
            HStack {
                Text("stake_request_unstake_in_progress".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .lineLimit(1)

                Spacer()

                Text("-\(vm.node.tokensRequestedToUnstake.formatCurrencyString(digits: 3))")
                    .font(.inter(size: 20, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)

                Text("Flow")
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text4)
            }

            HStack(spacing: 5) {
                Image("icon-clock-countdown")
                    .renderingMode(.template)
                    .foregroundColor(Color(hex: "#F1BF0C"))
                Text("stake_in_progress".localized)
                    .font(.inter(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#F1BF0C"))

                Spacer()

                Text("stake_progress_desc".localized)
                    .font(.inter(size: 12))
                    .foregroundColor(Color.LL.Neutrals.text4)
            }
        }
        .padding(.all, 18)
        .background(Color.LL.Neutrals.background)
        .cornerRadius(16)
    }

    var unstakeInProgressCardView: some View {
        VStack(spacing: 6) {
            HStack {
                Text("stake_unstake_in_progress".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Spacer()

                Text("-\(vm.node.tokensUnstaking.formatCurrencyString(digits: 3))")
                    .font(.inter(size: 20, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)

                Text("Flow")
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text4)
            }

            HStack(spacing: 5) {
                Image("icon-clock-countdown")
                    .renderingMode(.template)
                    .foregroundColor(Color(hex: "#F1BF0C"))
                Text("stake_in_progress".localized)
                    .font(.inter(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#F1BF0C"))

                Spacer()

                Text("stake_progress_desc".localized)
                    .font(.inter(size: 12))
                    .foregroundColor(Color.LL.Neutrals.text4)
            }
        }
        .padding(.all, 18)
        .background(Color.LL.Neutrals.background)
        .cornerRadius(16)
    }

    var rewardCardView: some View {
        HStack(spacing: 13) {
            // daily
            VStack(alignment: .leading, spacing: 13) {
                Text("stake_daily_reward".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                HStack(alignment: .bottom, spacing: 5) {
                    Text(
                        "\(CurrencyCache.cache.currentCurrency.symbol)\(vm.node.dayRewardsASUSD.formatCurrencyString(digits: 3, considerCustomCurrency: true))"
                    )
                    .font(.inter(size: 24, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                    Text(CurrencyCache.cache.currentCurrency.rawValue)
                        .font(.inter(size: 14, weight: .medium))
                        .foregroundColor(Color.LL.Neutrals.text3)
                        .padding(.bottom, 5)
                }

                Text("\(vm.node.dayRewards.formatCurrencyString(digits: 3)) Flow")
                    .font(.inter(size: 12, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text3)
            }
            .padding(.all, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.LL.Neutrals.background)
            .cornerRadius(16)

            // monthly
            VStack(alignment: .leading, spacing: 13) {
                Text("stake_mothly_reward".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                HStack(alignment: .bottom, spacing: 5) {
                    Text(
                        "\(CurrencyCache.cache.currentCurrency.symbol)\(vm.node.monthRewardsASUSD.formatCurrencyString(digits: 3, considerCustomCurrency: true))"
                    )
                    .font(.inter(size: 24, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)

                    Text(CurrencyCache.cache.currentCurrency.rawValue)
                        .font(.inter(size: 14, weight: .medium))
                        .foregroundColor(Color.LL.Neutrals.text3)
                        .padding(.bottom, 5)
                }

                Text("\(vm.node.monthRewards.formatCurrencyString(digits: 3)) Flow")
                    .font(.inter(size: 12, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text3)
            }
            .padding(.all, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.LL.Neutrals.background)
            .cornerRadius(16)
        }
    }

    var stakingListView: some View {
        VStack(spacing: 0) {
            createListCell(
                key: "stake_unstaked_amount".localized,
                value: "\(vm.node.tokensUnstaked.formatCurrencyString(digits: 3)) Flow"
            )
            Divider().foregroundColor(Color.LL.Neutrals.text2)
            createListCell(
                key: "stake_unstaking_amount".localized,
                value: "\(vm.node.tokensUnstaking.formatCurrencyString(digits: 3)) Flow"
            )
            Divider().foregroundColor(Color.LL.Neutrals.text2)
            createListCell(
                key: "stake_committed_amount".localized,
                value: "\(vm.node.tokensCommitted.formatCurrencyString(digits: 3)) Flow"
            )
            Divider().foregroundColor(Color.LL.Neutrals.text2)
            createListCell(
                key: "stake_requested_to_unstake_amount".localized,
                value: "\(vm.node.tokensRequestedToUnstake.formatCurrencyString(digits: 3)) Flow"
            )
            Divider().foregroundColor(Color.LL.Neutrals.text2)
            createListCell(
                key: "stake_apr".localized,
                value: "\((vm.provider.rate * 100).formatCurrencyString()) %"
            )
        }
        .padding(.horizontal, 18)
        .background(Color.LL.Neutrals.background)
        .cornerRadius(16)
    }

    func createListCell(key: String, value: String) -> some View {
        HStack {
            Text(key)
                .font(.inter(size: 14, weight: .semibold))
                .foregroundColor(Color.LL.Neutrals.text)

            Spacer()

            Text(value)
                .font(.inter(size: 14, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text)
        }
        .frame(height: 38)
    }

    // MARK: Private

    @StateObject
    private var vm: StakingDetailViewModel
}
