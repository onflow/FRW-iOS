//
//  EOAAccountDetailView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import SwiftUI

struct EOAAccountDetailView: View {
  @Binding var account: WalletAccount
  var profile: ProfileModel
  @Binding var parentAccount: WalletAccount?
  @Binding var showAccountEditor: Bool
  @State var isShow = true

  private let radius: CGFloat = 16

  var isSecureEnclave: Bool {
      WalletManager.shared.keyProvider?.keyType == .secureEnclave
  }

  var isSeedPhrase: Bool {
      WalletManager.shared.keyProvider?.keyType == .seedPhrase
  }

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


              if !isSecureEnclave {
                VStack(spacing: 0) {
                    Button {
                        Task {
                            let result = await SecurityManager.shared.SecurityVerify()
                            if result {
                                Router.route(to: RouteMap.Profile.privateKey(true))
                            }
                        }
                    } label: {
                      AccountOptionView(title: "private_key".localized, style: .arrow)
                    }
                  if isSeedPhrase {
                    Divider().foregroundColor(.LL.Neutrals.background)

                    Button {
                        Task {
                            let result = await SecurityManager.shared.SecurityVerify()
                            if result {
                                Router.route(to: RouteMap.Profile.manualBackup(true))
                            }
                        }
                    } label: {
                      AccountOptionView(title: "recovery_phrase".localized, style: .arrow)
                        .contentShape(Rectangle())
                    }
                  }

                }
                .cornerRadius(radius)
              }

              if isSecureEnclave {
                Button {
                    Router.route(to: RouteMap.Profile.secureEnclavePrivateKey)
                } label: {
                    AccountOptionView(title: "private_key".localized, style: .arrow)
                      .cornerRadius(radius)
                }
              }

              AccountShowView(address: account.address, uid: profile.uid)
                .cornerRadius(radius)
            }
        }
        .scrollIndicators(.never)
      }
      .tracedView(self)
    }
}

#Preview {
//    EOAAccountDetailView()
}
