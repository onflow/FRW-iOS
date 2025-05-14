//
//  DAppsListView.swift
//  Flow Wallet
//
//  Created by Selina on 29/6/2023.
//

import Combine
import Kingfisher
import SwiftUI

struct DAppsListView: RouteableView {
    // MARK: Internal

    var title: String {
        "dApps".localized
    }

    var body: some View {
        VStack {
            headerView
                .visibility(vm.categoryList.isEmpty ? .gone : .visible)

            contentList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    var headerView: some View {
        WrappingHStack(models: vm.categoryList) { category in
            Button {
                vm.changeCategory(category)
            } label: {
                Text(category.uppercased())
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .roundedBg(
                        cornerRadius: 18,
                        fillColor: Color.LL.Other.bg2,
                        strokeColor: vm
                            .selectedCategory == category ? Color(hex: "#7678ED") :
                            Color(hex: "#F5F5F5"),
                        strokeLineWidth: 2
                    )
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 18)
    }

    var contentList: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(vm.filterdList, id: \.name) { dApp in
                    Button {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
                        feedbackGenerator.impactOccurred()

                        Router.dismiss {
                            if currentNetwork == .testnet,
                               let url = dApp.testnetURL
                            {
                                Router.route(to: RouteMap.Explore.browser(url))
                            } else {
                                Router.route(to: RouteMap.Explore.browser(dApp.url))
                            }
                        }
                    } label: {
                        HStack(alignment: .top) {
                            KFImage
                                .url(dApp.logo)
                                .placeholder {
                                    Image("placeholder")
                                        .resizable()
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44, alignment: .center)
                                .cornerRadius(22)
                                .clipped()
                                .padding(.leading, 8)
                                .padding(.trailing, 16)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(dApp.name)
                                        .bold()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.LL.text)

                                    Spacer()

                                    Text(dApp.category.uppercased())
                                        .font(.LL.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.LL.outline.opacity(0.2))
                                        .foregroundColor(Color.LL.Neutrals.neutrals9)
                                        .cornerRadius(20)
                                }

                                Text(dApp.description + "\n")
                                    .font(.LL.footnote)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.LL.Neutrals.neutrals7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.trailing, 12)
                            }
                        }
                        .padding(10)
                        .padding(.vertical, 5)
                        .background(Color.LL.bgForIcon)
                        .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func backButtonAction() {
        Router.dismiss()
    }

    // MARK: Private

    @StateObject
    private var vm = DAppsListViewModel()
}
