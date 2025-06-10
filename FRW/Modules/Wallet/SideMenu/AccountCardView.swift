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
    var action: AccountInfoView.Action

    var body: some View {
        VStack(spacing: 0) {
            ForEach(accounts, id: \.account.infoAddress) { account in
                AccountInfoView(account: account, isActivity: false, isSelected: isSelected(account), action: action) { _, _ in
                    Router.route(to: RouteMap.Profile.walletSetting(true, account.account))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Summer.cards)
        }
    }

    func isSelected(_ account: AccountModel) -> Bool {
        selectedAddress.lowercased() == account.account.infoAddress.lowercased()
    }
}

#Preview {
    AccountCardView(accounts: AccountModel.mockSamples(), selectedAddress: "0x1234567890abcdef", action: .arrow)
}
