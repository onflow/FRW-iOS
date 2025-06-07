//
//  AccountListView.swift
//  FRW
//
//  Created by cat on 2024/5/28.
//

import FlowWalletKit
import SwiftUI

struct AccountListView: RouteableView {
    var accounts: [[AccountModel]]
    var selectedAdress: String

    init(accounts: [[AccountModel]], selectedAdress: String) {
        self.accounts = accounts
        self.selectedAdress = selectedAdress
    }

    var title: String {
        "wallet_list".localized
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0 ..< accounts.count, id: \.self) { index in
                    AccountCardView(accounts: accounts[index], selectedAddress: selectedAdress, action: action(with: accounts[index]))
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

    func action(with accounts: [AccountModel]) -> AccountInfoView.Action {
        guard let mainAccount = accounts.first?.account as? FlowWalletKit.Account else {
            return .arrow
        }
        return UserManager.shared.filterAccounts.inFilter(with: mainAccount) ? .card : .arrow
    }
}

#Preview {
    AccountListView(accounts: [AccountModel.mockSamples(), AccountModel.mockSamples()], selectedAdress: "")
}
