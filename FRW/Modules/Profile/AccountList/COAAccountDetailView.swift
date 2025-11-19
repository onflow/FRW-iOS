//
//  COAAccountDetailView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import SwiftUI

struct COAAccountDetailView: View {
  @Binding var account: RNBridge.WalletAccount
  @Binding var parentAccount: RNBridge.WalletAccount?
  @Binding var showAccountEditor: Bool
  private let radius: CGFloat = 16

    var body: some View {
      VStack {
        ScrollView {
            VStack(spacing: 16) {
              Button {
                showAccountEditor.toggle()
              } label: {
                AccountHeaderView(account: $account, parentAccount: parentAccount)
                  .cornerRadius(radius)
              }

              AccountAddressView(address: account.address)
                .cornerRadius(radius)

            }
        }
        .scrollIndicators(.never)
      }
    }
}

#Preview {
//    COAAccountDetailView()
}
