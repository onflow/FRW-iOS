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

    @State var account: WalletAccount
    var profile: ProfileModel
    @State var parentAccount: WalletAccount?
    @State private var showAccountEditor = false

    var body: some View {
      VStack {
        if account.type == .main {
          CadenceAccountView(account: $account, profile: profile, showAccountEditor: $showAccountEditor)
        }
        if account.type == .child {
          LinkedAccountDetailView(account: $account, parentAccount: $parentAccount)
        }
        if account.type == .coa {
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
      let updatedAccount = account.updatedFromEmoji()
      account = updatedAccount
      parentAccount = parentAccount?.updatedFromEmoji()
    }
}

#Preview {
//    AccountDetailView()
}
