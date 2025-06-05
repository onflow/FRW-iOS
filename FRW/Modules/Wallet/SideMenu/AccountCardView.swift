//
//  AccountCardView.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import FlowWalletKit
import SwiftUI

struct AccountCardView: View {
    var accounts: [AccountModel]
    var selectedAddress: String
    var hideAccounts: [String]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(accounts, id: \.account.infoAddress) { account in
                AccountInfoView(account: account, isActivity: false, isSelected: isSelected(account), action: actionType(account)) { _, _ in
                    Router.route(to: RouteMap.Profile.walletSetting(true, account.account))
                }
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Summer.cards)
        }
    }

    func isSelected(_ account: AccountModel) -> Bool {
        selectedAddress.lowercased() == account.account.infoAddress.lowercased()
    }

    func actionType(_ account: AccountModel) -> AccountInfoView.Action {
        (hideAccounts.first { $0.lowercased() == account.account.infoAddress.lowercased() } != nil) ? .hide : .arrow
    }
}

#Preview {
    AccountCardView(accounts: AccountModel.mockSamples(), selectedAddress: "0x1234567890abcdef", hideAccounts: ["0x1234567890abcdef"])
}
