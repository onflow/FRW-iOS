//
//  ManageTokensView.swift
//  FRW
//
//  Created by cat on 5/6/25.
//

import SwiftUI

struct ManageTokensView: RouteableView {
    @StateObject var viewModel = ManageTokensViewModel()
    @ObservedObject var filterToken = WalletManager.shared.filterToken
    @State private var isSearchFocused: Bool = false
    @State private var showTooltip: Bool = false

    var title: String {
        return "manager_tokens".localized
    }

    var body: some View {
        VStack {
            filterView
                .padding(.bottom, 20)
            tokenView
        }
        .padding(16)
        .background(.Theme.Background.white)
        .navigationBarItems(trailing: HStack(spacing: 6) {
            Button {
                Router.route(to: RouteMap.Wallet.addToken)
            } label: {
                Image("btn-add")
                    .renderingMode(.template)
                    .foregroundColor(.Theme.Text.black)
            }
        })
        .onTapGesture {
            showTooltip = false
        }
        .applyRouteable(self)
        .tracedView(self)
    }

    var filterView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("Filters".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.text4)
                Spacer()
            }

            HStack {
                Toggle(isOn: $filterToken.hideDustToken) {
                    HStack {
                        Text("hide_dust_tokens".localized)
                            .font(.inter(size: 14))
                            .foregroundStyle(Color.Theme.Text.black)
                        Button {
                            showTooltip.toggle()
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .foregroundStyle(Color.Theme.Text.text4)
                                .frame(width: 16, height: 16)
                        }
                        .overlay {
                            TooltipView(
                                alignment: .bottom,
                                isVisible: $showTooltip
                            ) {
                                Text("hide_dust_tokens_tip".localized)
                                    .font(.inter(size: 10))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                                    .padding(.top, 12)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 8)

            HStack {
                Toggle(isOn: $filterToken.onlyShowVerified) {
                    HStack(spacing: 0) {
                        Text("only_show_tokens".localized)
                            .font(.inter(size: 14))
                            .foregroundStyle(Color.Theme.Text.black)
                        Image("icon-token-valid")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
            }
        }
        .padding(16)
        .background(.Theme.Text.black.opacity(0.1))
        .cornerRadius(16)
        .onChange(of: $filterToken.hideDustToken) { _ in
            filterToken.updateFilter()
        }
        .onChange(of: $filterToken.onlyShowVerified) { _ in
            filterToken.updateFilter()
        }
    }

    var tokenView: some View {
        VStack(spacing: 20) {
            HStack {
                Text("tokens".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.text4)
                Spacer()
            }
            SearchBar(placeholder: "Search_Token::message".localized, searchText: $viewModel.searchText, isFocused: $isSearchFocused)
            ScrollView {
                VStack {
                    ForEach(viewModel.list, id: \.token.contractId) { model in
                        ManagerTokensItemView(item: model, callback: { _, _ in
                            filterToken.switchToken(model.token)
                        })
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}

#Preview {
    ManageTokensView()
}
