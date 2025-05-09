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

    var title: String {
        return "manager_tokens".localized
    }

    var body: some View {
        VStack {
            filterView
                .padding(.bottom, 20)
            tokenView
        }
        .navigationBarItems(trailing: HStack(spacing: 6) {
            Button {
                Router.route(to: RouteMap.Wallet.addToken)
            } label: {
                Image("btn-add")
                    .renderingMode(.template)
                    .foregroundColor(.Theme.Text.black)
            }
        })
        .searchable(text: $viewModel.searchText)
        .padding(16)
        .background(.Theme.Background.white)
        .applyRouteable(self)
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
                    Text("hide_dust_tokens".localized)
                        .font(.inter(size: 14))
                        .foregroundStyle(Color.Theme.Text.black)
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
        VStack {
            HStack(spacing: 0) {
                Text("tokens".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.text4)
                Spacer()
            }

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
