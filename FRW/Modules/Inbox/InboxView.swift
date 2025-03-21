//
//  InboxView.swift
//  Flow Wallet
//
//  Created by Selina on 19/9/2022.
//

import Kingfisher
import SwiftUI
import SwiftUIPager

// MARK: - InboxView

struct InboxView: RouteableView {
    @StateObject
    var vm = InboxViewModel()

    var title: String {
        "inbox".localized
    }

    var body: some View {
        VStack(spacing: 0) {
            switchBar
            contentView
        }
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
    }

    var switchBar: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        vm.changeTabTypeAction(type: .token)
                    } label: {
                        Text("inbox_token_x".localized(vm.tokenList.count))
                            .foregroundColor(
                                vm.tabType == .token ? Color.LL.Primary
                                    .salmonPrimary : Color.LL.Neutrals.text
                            )
                            .font(.inter(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    Button {
                        vm.changeTabTypeAction(type: .nft)
                    } label: {
                        Text("inbox_nft_x".localized(vm.nftList.count))
                            .foregroundColor(
                                vm.tabType == .nft ? Color.LL.Primary
                                    .salmonPrimary : Color.LL.Neutrals.text
                            )
                            .font(.inter(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                // indicator
                let widthPerTab = geo.size.width / 2.0
                Color.LL.Primary.salmonPrimary
                    .frame(width: widthPerTab, height: 4)
                    .padding(.leading, widthPerTab * CGFloat(vm.tabType.rawValue))
            }
        }
        .frame(height: 50)
    }

    var contentView: some View {
        ZStack {
            Pager(page: vm.page, data: InboxViewModel.TabType.allCases, id: \.self) { type in
                switch type {
                case .token:
                    tokenContainerView
                case .nft:
                    nftContainerView
                }
            }
            .onPageChanged { newIndex in
                vm.changeTabTypeAction(type: InboxViewModel.TabType(rawValue: newIndex) ?? .token)
            }
        }
    }

    var emptyView: some View {
        VStack {
            Image("icon-inbox-empty")
            Text("inbox_no_items".localized)
                .font(.inter(size: 18, weight: .semibold))
                .foregroundColor(Color.LL.Neutrals.text4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Token

extension InboxView {
    var tokenContainerView: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    ForEach(vm.tokenList, id: \.key) { model in
                        InboxTokenItemView(item: model)
                    }
                }
                .padding(.all, 18)
            }

            emptyView.visibility(!vm.isRequesting && vm.tokenList.isEmpty ? .visible : .gone)
        }
        .frame(maxHeight: .infinity)
        .environmentObject(vm)
    }

    struct InboxTokenItemView: View {
        // MARK: Internal

        let item: InboxToken

        var body: some View {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    KFImage.url(item.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())

                    Text(item.amountText)
                        .font(.inter(size: 16, weight: .medium))
                        .foregroundColor(Color.LL.Neutrals.text)

                    Spacer()

                    Text(
                        "\(CurrencyCache.cache.currencySymbol)\(item.marketPrice.formatCurrencyStringForDisplay(considerCustomCurrency: true))"
                    )
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)
                }

                // btn
                HStack {
                    Spacer()

                    Button {
                        vm.claimTokenAction(item)
                    } label: {
                        Text("domain_claim".localized)
                            .font(.inter(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 24)
                            .padding(.horizontal, 14)
                            .background(Color.LL.Primary.salmonPrimary)
                            .cornerRadius(12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.all, 16)
            .background(Color.LL.Other.bg2)
            .cornerRadius(12)
        }

        // MARK: Private

        @EnvironmentObject
        private var vm: InboxViewModel
    }
}

// MARK: - NFT

extension InboxView {
    var nftContainerView: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    ForEach(vm.nftList, id: \.key) { model in
                        InboxNFTItemView(item: model)
                    }
                }
                .padding(.all, 18)
            }

            emptyView.visibility(!vm.isRequesting && vm.nftList.isEmpty ? .visible : .gone)
        }
        .frame(maxHeight: .infinity)
        .environmentObject(vm)
    }

    struct InboxNFTItemView: View {
        // MARK: Internal

        let item: InboxNFT

        var body: some View {
            HStack(spacing: 16) {
                // large cover
                KFImage.url(nil)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 110, height: 110)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 0) {
                    // title line
                    Button {
                        vm.openNFTCollectionAction(item)
                    } label: {
                        HStack(spacing: 8) {
                            KFImage.url(item.localCollection?.logoURL)
                                .placeholder {
                                    Image("placeholder")
                                        .resizable()
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())

                            Text(item.localCollection?.name ?? "Unknown")
                                .font(.inter(size: 16, weight: .semibold))
                                .foregroundColor(Color.LL.Neutrals.text)

                            Image("arrow_right_grey")
                                .renderingMode(.template)
                                .foregroundColor(Color.LL.Other.text1)

                            Spacer()
                        }
                    }

                    Divider()
                        .foregroundColor(.LL.Neutrals.neutrals6)
                        .padding(.vertical, 16)

                    Text("ID: \(item.tokenId)")
                        .font(.inter(size: 12))
                        .foregroundColor(Color.LL.Other.text1)

                    Spacer()

                    // btn
                    HStack {
                        Spacer()

                        Button {
                            vm.claimNFTAction(item)
                        } label: {
                            Text("domain_claim".localized)
                                .font(.inter(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(height: 24)
                                .padding(.horizontal, 14)
                                .background(Color.LL.Primary.salmonPrimary)
                                .cornerRadius(12)
                        }
                    }
                }
                .frame(height: 110)
            }
            .frame(maxWidth: .infinity)
            .padding(.all, 16)
            .background(Color.LL.Other.bg2)
            .cornerRadius(12)
        }

        // MARK: Private

        @EnvironmentObject
        private var vm: InboxViewModel
    }
}
