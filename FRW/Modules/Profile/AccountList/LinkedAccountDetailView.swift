//
//  LinkedAccountDetailView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import SwiftUI

struct LinkedAccountDetailView: View {
  @Binding var account: WalletAccount
  @Binding var parentAccount: WalletAccount?
  private let radius: CGFloat = 16
  
  init(account: Binding<WalletAccount>, parentAccount: Binding<WalletAccount?>) {
    self._account = account
    self._parentAccount = parentAccount
  }

    var body: some View {
      VStack {
        ScrollView {
            VStack(spacing: 16) {
              AccountHeaderView(account: $account, parentAccount: parentAccount)
                .cornerRadius(radius)

              AccountAddressView(address: account.address)
                .cornerRadius(radius)


              Button {
                  Router.route(to: RouteMap.Profile.accountKeys)
              } label: {
                  AccountOptionView(title: "wallet_account_key".localized, style: .arrow)
                    .cornerRadius(radius)
              }

            }
        }
        .scrollIndicators(.never)
      }
    }
}

#Preview {
//    LinkedAccountDetail()
}
