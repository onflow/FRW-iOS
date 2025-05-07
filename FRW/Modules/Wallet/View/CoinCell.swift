//
//  CoinCell.swift
//  FRW
//
//  Created by Hao Fu on 5/4/2025.
//

import Foundation
import Kingfisher
import SwiftUI

private let CoinIconHeight: CGFloat = 44
private let CoinCellHeight: CGFloat = 76

// MARK: WalletHomeView.CoinCell

extension WalletHomeView {
    struct CoinCell: View {
        let coin: WalletViewModel.WalletCoinItemModel
        @EnvironmentObject
        var vm: WalletViewModel
        @StateObject
        var stakingManager = StakingManager.shared

        var body: some View {
            VStack(spacing: 0) {
                TokenInfoCell(token: coin.token, isHidden: vm.isHidden)

                if EVMAccountManager.shared.selectedAccount == nil && ChildAccountManager.shared
                    .selectedChildAccount == nil
                {
                    HStack(spacing: 0) {
                        Divider()
                            .frame(width: 1, height: 10)
                            .foregroundColor(Color.LL.Neutrals.neutrals4)

                        Spacer()
                    }
                    .padding(.leading, 24)
                    .offset(y: -5)
                    .visibility(coin.token.isFlowCoin && stakingManager.isStaked ? .visible : .gone)

                    Button {
                        StakingManager.shared.goStakingAction()
                    } label: {
                        HStack(spacing: 0) {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(Color.LL.Neutrals.neutrals4)

                            Text("staked_flow".localized)
                                .foregroundColor(.LL.Neutrals.text)
                                .font(.inter(size: 14, weight: .semibold))
                                .padding(.leading, 31)

                            Spacer()

                            Text(
                                "\(vm.isHidden ? "****" : stakingManager.stakingCount.formatCurrencyString()) FLOW"
                            )
                            .foregroundColor(.LL.Neutrals.text)
                            .font(.inter(size: 14, weight: .medium))
                        }
                    }
                    .padding(.leading, 19)
                    .padding(.bottom, 12)
                    .visibility(coin.token.isFlowCoin && stakingManager.isStaked ? .visible : .gone)
                }
            }
            .background(.clear)
            .cornerRadius(16)
        }
    }
}

struct TokenInfoCell: View {
    let token: TokenModel
    var isHidden: Bool = false
    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            KFImage.url(token.iconURL)
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: CoinIconHeight, height: CoinIconHeight)
                .clipShape(Circle())

            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    Text(token.name)
                        .foregroundColor(Color.Theme.Text.text1)
                        .font(.inter(size: 14, weight: .bold))
                    Image("icon-token-valid")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .visibility(token.isVerifiedValue ? .visible : .gone)
                    Spacer()

                    Text(
                        "\(isHidden ? "****" : token.showBalanceStr) \(token.symbol?.uppercased() ?? "?")"
                    )
                    .foregroundColor(.LL.Neutrals.text)
                    .font(.inter(size: 14, weight: .medium))
                }

                HStack {
                    if WalletManager.shared.accessibleManager.isAccessible(token) {
                        if let priceValue = token.priceInCurrencyStr {
                            HStack {
                                Text(priceValue)
                                    .foregroundColor(.LL.Neutrals.neutrals7)
                                    .font(.inter(size: 14, weight: .regular))
                            }
                        }
                    } else {
                        Text("Inaccessible".localized)
                            .foregroundStyle(Color.Flow.Font.inaccessible)
                            .font(Font.inter(size: 10, weight: .semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 5)
                            .background(.Flow.Font.inaccessible.opacity(0.16))
                            .cornerRadius(4, style: .continuous)
                    }

                    Spacer()

                    if let balance = token.balanceInCurrencyStr {
                        Text(isHidden ? "****" : "\(balance)")
                            .foregroundColor(.LL.Neutrals.neutrals7)
                            .font(.inter(size: 14, weight: .regular))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: CoinCellHeight)
    }
}
