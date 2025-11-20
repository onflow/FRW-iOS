//
//  LinkedAccountDetailView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import SwiftUI

struct LinkedAccountDetailView: View {
  @Binding var account: RNBridge.WalletAccount
  @Binding var parentAccount: RNBridge.WalletAccount?
  private let radius: CGFloat = 16
  var desc: String? = nil
  
  init(account: Binding<RNBridge.WalletAccount>, parentAccount: Binding<RNBridge.WalletAccount?>, desc: String? = nil) {
    self._account = account
    self._parentAccount = parentAccount
    self.desc = desc
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
