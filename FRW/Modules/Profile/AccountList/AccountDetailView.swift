//
//  AccountDetailView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import SwiftUI

struct AccountDetailView: RouteableView {
    var title: String {
        "account".localized.capitalized
    }

    @State var account: RNBridge.WalletAccount
    var profile: ProfileModel
    @State var parentAccount: RNBridge.WalletAccount?
    @State private var showAccountEditor = false

    var body: some View {
      VStack {
        if account.type == .main {
          CadenceAccountView(account: $account, profile: profile, showAccountEditor: $showAccountEditor)
        }
        if account.type == .child {
          LinkedAccountDetailView(account: $account, parentAccount: $parentAccount)
        }
        if account.type == .evm {
          COAAccountDetailView(account: $account, parentAccount: $parentAccount, showAccountEditor: $showAccountEditor)
        }
        if account.type == .eoa {
          EOAAccountDetailView(
            account: $account,
            profile: profile,
            parentAccount: $parentAccount,
            showAccountEditor: $showAccountEditor
          )
        }
      }
      .padding(.top, 12)
      .padding(.horizontal, 18)
      .applyRouteable(self)
      .popup(isPresented: $showAccountEditor) {
        WalletAccountEditor(address: account.address) {
          onReload()
          showAccountEditor = false
        }
      } customize: {
          $0
              .closeOnTap(false)
              .closeOnTapOutside(true)
              .backgroundColor(.black.opacity(0.4))
      }
    }


    func onReload() {
      ProfileManager.shared.updateAccount(at: account.address)
      account = account.updatedFromEmoji()
    }
}

#Preview {
//    AccountDetailView()
}
