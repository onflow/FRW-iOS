//
//  LinkedAccountDetailView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import SwiftUI

struct LinkedAccountDetailView: View {
  @Binding var account: WalletAccount
  private let radius: CGFloat = 16

  init(account: Binding<WalletAccount>) {
    self._account = account
  }

    var body: some View {
      VStack {
        ScrollView {
            VStack(spacing: 16) {
              AccountHeaderView(account: $account)
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
