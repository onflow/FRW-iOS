//
//  StakingListView.swift
//  Flow Wallet
//
//  Created by Selina on 10/11/2022.
//

import Combine
import Kingfisher
import SwiftUI
import UIKit

// MARK: - StakingListItemModel

struct StakingListItemModel {
    let provider: StakingProvider
    let nodeInfo: StakingNode
}

// MARK: - StakingListViewModel

class StakingListViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        StakingManager.shared.$nodeInfos.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.refresh()
            }
        }.store(in: &cancelSet)
        StakingManager.shared.refresh()
    }

    // MARK: Internal

    @Published
    var items: [StakingListItemModel] = []

    func claimReward(node: StakingNode) {
        guard let delegatorId = StakingManager.shared.providerForNodeId(node.nodeID)?.delegatorId
        else {
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

    // MARK: Private

    private var cancelSet = Set<AnyCancellable>()

    private func refresh() {
        var items = [StakingListItemModel]()
        for node in StakingManager.shared.nodeInfos {
            if let provider = StakingManager.shared.providerForNodeId(node.nodeID) {
                items.append(StakingListItemModel(provider: provider, nodeInfo: node))
            }
        }
        self.items = items
    }
}

// MARK: - StakingListView

struct StakingListView: RouteableView {
    // MARK: Internal

    var title: String {
        "staking_list_title".localized
    }

    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        .large
    }

    var body: some View {
        VStack {
            if vm.items.isEmpty {
                emptyListView
            } else {
                listView
            }
            newNodeBtn
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .buttonStyle(.plain)
        .backgroundFill(.LL.deepBg)
        .applyRouteable(self)
    }

    var newNodeBtn: some View {
        VPrimaryButton(
            model: ButtonStyle.primary,
            state: .enabled,
            action: {
                Router.route(to: RouteMap.Wallet.stakingSelectProvider)
            },
            title: "stake_new_node".localized
        )
    }

    var emptyListView: some View {
        VStack {
            Spacer()
            Text("staking_empty_list".localized)
                .font(.inter(size: 20, weight: .bold))
                .foregroundColor(Color.LL.Neutrals.neutrals7)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.items, id: \.nodeInfo.id) { item in
                    Button {
                        Router.route(to: RouteMap.Wallet.stakeDetail(item.provider, item.nodeInfo))
                    } label: {
                        createListCell(item)
                    }
                }
            }
        }
    }

    func createListCell(_ item: StakingListItemModel) -> some View {
        VStack(spacing: 0) {
            // header
            HStack(spacing: 0) {
                KFImage.url(item.provider.iconURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .cornerRadius(12)

                Text(item.provider.name)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .padding(.leading, 8)

                Text(item.provider.apyYearPercentString)
                    .font(.inter(size: 12, weight: .semibold))
                    .foregroundColor(Color.Flow.Font.ascend)
                    .padding(.horizontal, 5)
                    .frame(height: 18)
                    .background(Color.Flow.Font.ascend.opacity(0.16))
                    .cornerRadius(4)
                    .padding(.leading, 8)

                Spacer()

                Button {
                    vm.claimReward(node: item.nodeInfo)
                } label: {
                    Text("staking_claim".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 26)
                        .background(Color.Flow.accessory)
                        .cornerRadius(16)
                }
            }
            .frame(height: 56)

            // detail
            HStack(spacing: 12) {
                // amount
                VStack(alignment: .leading, spacing: 13) {
                    Text("staking_amount".localized)
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(Color.LL.Neutrals.text4)

                    Text(AttributedString(numAttributedString(num: item.nodeInfo.stakingCount)))
                }
                .padding(.all, 13)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color.LL.deepBg)
                .cornerRadius(16)

                // rewards
                VStack(alignment: .leading, spacing: 13) {
                    Text("staking_rewards".localized)
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(Color.LL.Neutrals.text4)

                    Text(AttributedString(numAttributedString(num: item.nodeInfo.tokensRewarded)))
                }
                .padding(.all, 13)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .background(Color.LL.deepBg)
                .cornerRadius(16)
            }
            .frame(height: 76)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .background {
            Color.LL.Neutrals.background.cornerRadius(16)
        }
    }

    func numAttributedString(num: Double) -> NSAttributedString {
        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.interBold(size: 18),
            .foregroundColor: UIColor.LL.Neutrals.text,
        ]
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.interMedium(size: 12),
            .foregroundColor: UIColor.LL.Neutrals.text,
        ]

        let numStr = NSMutableAttributedString(
            string: "\(num.formatCurrencyStringForDisplay(digits: 3)) ",
            attributes: boldAttrs
        )
        let normalStr = NSAttributedString(string: "Flow", attributes: normalAttrs)

        numStr.append(normalStr)

        return numStr
    }

    // MARK: Private

    @StateObject
    private var vm = StakingListViewModel()
}
