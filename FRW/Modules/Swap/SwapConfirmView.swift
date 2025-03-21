//
//  SwapConfirmView.swift
//  Flow Wallet
//
//  Created by Selina on 27/9/2022.
//

import Kingfisher
import SwiftUI

// MARK: - SwapConfirmView

struct SwapConfirmView: View {
    @EnvironmentObject
    var vm: SwapViewModel

    var body: some View {
        VStack {
            SheetHeaderView(title: "confirmation".localized)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    fromToView
                    SwapConfirmView.SwapConfirmProgressView()
                        .padding(.bottom, 37)
                }
                .background(Color.LL.Other.bg3)
                .cornerRadius(16)
                .padding(.horizontal, 18)

                swapDetailView
                    .padding(.top, -20)
                    .padding(.horizontal, 28)
                    .zIndex(-1)

                sendButton
                    .padding(.bottom, 10)
                    .padding(.horizontal, 28)
            }
        }
    }

    private var fromToView: some View {
        HStack(spacing: 16) {
            if let fromToken = vm.fromToken {
                tokenView(token: fromToken, num: vm.inputFromText)
            }

            Spacer()

            if let toToken = vm.toToken {
                tokenView(token: toToken, num: vm.inputToText)
            }
        }
        .padding(.vertical, 20)
    }

    private var swapDetailView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("swap_best_price".localized)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text2)
                    .lineLimit(1)

                Spacer()

                Text(vm.rateText)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Success.success1)
                    .lineLimit(1)
            }

            HStack {
                Text("swap_provider".localized)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text2)
                    .lineLimit(1)

                Spacer()

                Image("icon-increment")

                Text("Increment.fi")
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .lineLimit(1)
            }

            HStack {
                Text("swap_price_impact".localized)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text2)
                    .lineLimit(1)

                Spacer()

                Text(
                    ((vm.estimateResponse?.priceImpact ?? 0.0) * -100)
                        .formatCurrencyStringForDisplay(digits: 4) + "%"
                )
                .font(.inter(size: 14, weight: .medium))
                .foregroundColor(Color.LL.Success.success1)
                .lineLimit(1)
            }

//            HStack {
//                Text("swap_estimated_fees".localized)
//                    .font(.inter(size: 14, weight: .medium))
//                    .foregroundColor(Color.LL.Neutrals.text2)
//                    .lineLimit(1)
//
//                Spacer()
//
//                Text(vm.estimateResponse?.priceImpact.formatCurrencyStringForDisplay(digits: 4) ?? "0")
//                    .font(.inter(size: 14, weight: .medium))
//                    .foregroundColor(Color.LL.Neutrals.text)
//                    .lineLimit(1)
//            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 44)
        .padding(.bottom, 24)
        .background(Color.LL.Neutrals.neutrals6)
        .cornerRadius(16)
    }

    private var sendButton: some View {
        VPrimaryButton(
            model: ButtonStyle.primary,
            state: vm.confirmButtonState,
            action: {
                vm.confirmSwapAction()
            },
            title: vm.confirmButtonState == .loading ? "working_on_it".localized : "swap_confirm"
                .localized
        )
    }

    private func tokenView(token: TokenModel, num: String) -> some View {
        VStack(spacing: 5) {
            KFImage.url(token.icon)
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            Text("\(token.symbol?.uppercased() ?? "")")
                .foregroundColor(.LL.Neutrals.text)
                .font(.inter(size: 14, weight: .semibold))
                .lineLimit(1)

            Text("\(num) \(token.symbol?.uppercased() ?? "")")
                .foregroundColor(.LL.Neutrals.note)
                .font(.inter(size: 12, weight: .regular))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: SwapConfirmView.SwapConfirmProgressView

extension SwapConfirmView {
    struct SwapConfirmProgressView: View {
        // MARK: Internal

        var body: some View {
            HStack(spacing: 12) {
                ForEach(0..<totalNum, id: \.self) { index in
                    if step == index {
                        Image("icon-right-arrow-1")
                            .renderingMode(.template)
                            .foregroundColor(.LL.Primary.salmonPrimary)
                    } else {
                        switch index {
                        case 0:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.25)
                        case 1:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.35)
                        case 2:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.50)
                        case 3:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.65)
                        case 4:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.80)
                        case 5:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.95)
                        default:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary)
                        }
                    }
                }
            }
            .onReceive(timer) { _ in
                DispatchQueue.main.async {
                    if step < totalNum - 1 {
                        step += 1
                    } else {
                        step = 0
                    }
                }
            }
        }

        // MARK: Private

        private let totalNum: Int = 7
        @State
        private var step: Int = 0
        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
}
