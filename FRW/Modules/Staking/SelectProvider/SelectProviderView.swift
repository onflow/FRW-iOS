//
//  SelectProviderView.swift
//  Flow Wallet
//
//  Created by Selina on 14/11/2022.
//

import Kingfisher
import SwiftUI

struct SelectProviderView: RouteableView {
    // MARK: Internal

    @Environment(\.colorScheme)
    var colorScheme

    var title: String {
        "staking_select_provider".localized
    }

    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        .large
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Group {
                    createSectionTitleView("staking_recommend".localized)

                    VStack(spacing: 0) {
                        HStack {
                            Text("stake_on_lilico_only".localized)
                                .font(.inter(size: 12, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.72))

                            Spacer()

                            Image("icon-account-arrow-right")
                                .renderingMode(.template)
                                .foregroundColor(Color.white.opacity(0.72))
                        }
                        .frame(height: 32)

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 64)
                    .background(Color.Flow.accessory)
                    .cornerRadius(16)
                    .padding(.top, 12)

                    createProviderView(
                        provider: vm.lilicoProvider,
                        gradientStart: colorScheme == .light ? "#FFD7C6" : "#292929",
                        gradientEnd: colorScheme == .light ? "#FAFAFA" : "#292929"
                    )
                    .padding(.top, -40)
                }
                .visibility(.gone)

//                createSectionTitleView("staking_liquid_stake".localized)
//                ForEach(dataList2, id: \.self) { _ in
//                    createProviderView(gradientStart: "#F2EEFF", gradientEnd: "#FAFAFA")
//                }
//
                Group {
                    createSectionTitleView("staking_provider_section_title".localized)
                    ForEach(vm.otherProviders, id: \.id) { provider in
                        createProviderView(
                            provider: provider,
                            gradientStart: colorScheme == .light ? "#F0F0F0" : "#292929",
                            gradientEnd: colorScheme == .light ? "#FAFAFA" : "#292929"
                        )
                    }
                }
                .visibility(vm.otherProviders.isEmpty ? .gone : .visible)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .backgroundFill(.LL.deepBg)
        .applyRouteable(self)
        .tracedView(self)
    }

    func createSectionTitleView(_ title: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(Color.LL.Neutrals.text3)
                .font(.inter(size: 14, weight: .bold))

            Spacer()
        }
        .padding(.top, 14)
    }

    func createProviderView(
        provider: StakingProvider?,
        gradientStart: String,
        gradientEnd: String
    ) -> some View {
        Button {
            if let provider = provider {
                Router.route(to: RouteMap.Wallet.stakeAmount(provider))
            }
        } label: {
            HStack(spacing: 0) {
                KFImage.url(provider?.iconURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(provider?.name ?? "unknown")
                        .foregroundColor(Color.LL.Neutrals.text)
                        .font(.inter(size: 16, weight: .bold))
                        .lineLimit(1)

                    HStack(spacing: 0) {
//                        Text("staking_provider".localized)
//                            .foregroundColor(Color.LL.Neutrals.text2)
//                            .font(.inter(size: 12, weight: .semibold))
//
//                        KFImage.url(provider?.iconURL)
//                            .placeholder({
//                                Image("placeholder")
//                                    .resizable()
//                            })
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: 12, height: 12)
//                            .clipShape(Circle())
//                            .padding(.leading, 6)

                        Text(provider?.host ?? "")
                            .foregroundColor(Color.LL.Neutrals.text2)
                            .font(.inter(size: 12, weight: .semibold))
                            .padding(.leading, 4)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 12)
                .frame(alignment: .leading)

                Spacer()

                if let provider, provider.isLilico {
                    ZStack {
                        VStack(spacing: 5) {
                            Text(provider.apyYearPercentString)
                                .foregroundColor(Color.LL.Neutrals.text)
                                .font(.inter(size: 16, weight: .semibold))

                            Text("stake".localized)
                                .foregroundColor(Color.LL.Neutrals.text3)
                                .font(.inter(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: 92)
                    .frame(height: 48)
                    .background(Color.LL.deepBg)
                    .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .frame(height: 64)
            .background {
                Rectangle()
                    .fill(.radialGradient(
                        colors: [Color(hex: gradientStart, alpha: 1), Color(
                            hex: gradientEnd,
                            alpha: 1
                        )],
                        center: .init(x: 0.5, y: -1.9),
                        startRadius: 1,
                        endRadius: 200
                    ))
            }
            .cornerRadius(16)
            .padding(.top, 8)
        }
    }

    // MARK: Private

    @StateObject
    private var vm = SelectProviderViewModel()
}
