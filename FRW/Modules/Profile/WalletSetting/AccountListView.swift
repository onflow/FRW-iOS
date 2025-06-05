//
//  AccountListView.swift
//  FRW
//
//  Created by cat on 2024/5/28.
//

import SwiftUI

struct AccountListView: RouteableView {
    var accounts: [[AccountModel]]
    var selectedAdress: String
    var hideAccounts: [String]

    init(accounts: [[AccountModel]], selectedAdress: String, hideAccounts: [String]) {
        self.accounts = accounts
        self.selectedAdress = selectedAdress
        self.hideAccounts = hideAccounts
    }

    var title: String {
        "wallet_list".localized
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0 ..< accounts.count, id: \.self) { index in
                    AccountCardView(accounts: accounts[index], selectedAddress: selectedAdress, hideAccounts: hideAccounts)
                }
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .backgroundFill(Color.Theme.Background.white)
        .applyRouteable(self)
        .tracedView(self)
//        .navigationBarItems(trailing: HStack(spacing: 6) {
//            Button {
//                viewModel.addAccount()
//            } label: {
//                Image("btn-add")
//                    .renderingMode(.template)
//                    .foregroundColor(.Theme.Text.black8)
//            }
//        })
    }
}

#Preview {
    AccountListView(accounts: [AccountModel.mockSamples(), AccountModel.mockSamples()], selectedAdress: "", hideAccounts: [])
}
