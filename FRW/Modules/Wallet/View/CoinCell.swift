//
//  CoinCell.swift
//  FRW
//
//  Created by Hao Fu on 5/4/2025.
//

import Foundation
import SwiftUI
import Kingfisher

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
                HStack(alignment: .center, spacing: 18) {
                    KFImage.url(coin.token.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: CoinIconHeight, height: CoinIconHeight)
                        .clipShape(Circle())

                    VStack(spacing: 7) {
                        HStack {
                            Text(coin.token.name)
                                .foregroundColor(.LL.Neutrals.text)
                                .font(.inter(size: 14, weight: .bold))

                            Spacer()

                            Text(
                                "\(vm.isHidden ? "****" : coin.balance.formatCurrencyString()) \(coin.token.symbol?.uppercased() ?? "?")"
                            )
                            .foregroundColor(.LL.Neutrals.text)
                            .font(.inter(size: 14, weight: .medium))
                        }

                        HStack {
                            if WalletManager.shared.accessibleManager.isAccessible(coin.token) {
                                if let priceValue = coin.priceValue {
                                    HStack {
                                        Text(priceValue)
                                            .foregroundColor(.LL.Neutrals.neutrals7)
                                            .font(.inter(size: 14, weight: .regular))

                                        Text(coin.changeString)
                                            .foregroundColor(coin.changeColor)
                                            .font(.inter(size: 12, weight: .semibold))
                                            .frame(height: 22)
                                            .padding(.horizontal, 6)
                                            .background(coin.changeBG)
                                            .cornerRadius(11, style: .continuous)
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

                            if coin.priceValue != nil {
                                Text(
                                    vm
                                        .isHidden ? "****" :
                                        "\(CurrencyCache.cache.currencySymbol)\(coin.balanceAsCurrentCurrency)"
                                )
                                .foregroundColor(.LL.Neutrals.neutrals7)
                                .font(.inter(size: 14, weight: .regular))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(minHeight: CoinCellHeight)

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
