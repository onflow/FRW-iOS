//
//  CadenceAccountView.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import SwiftUI

// MARK: - CadenceAccountView

struct CadenceAccountView: View {


  // MARK: Internal
  @Binding var account: WalletAccount
  var profile: ProfileModel
  @Binding var showAccountEditor: Bool
  @State var isShow = true
  
  private let radius: CGFloat = 16
  @StateObject private var vm = WalletSettingViewModel()


    var isSecureEnclave: Bool {
        WalletManager.shared.keyProvider?.keyType == .secureEnclave
    }

    var isSeedPhrase: Bool {
        WalletManager.shared.keyProvider?.keyType == .seedPhrase
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                  Button {
                    showAccountEditor.toggle()
                  } label: {
                    AccountHeaderView(account: $account)
                      .cornerRadius(radius)
                  }
                  .buttonStyle(ScaleButtonStyle())

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


                  Button {
                      Router.route(to: RouteMap.Profile.accountKeys)
                  } label: {
                      AccountOptionView(title: "wallet_account_key".localized, style: .arrow)
                        .cornerRadius(radius)
                  }
                  
                  AccountShowView(address: account.address, uid: profile.uid)
                    .cornerRadius(radius)


                  StorageUsageView(
                      title: "storage".localized,
                      usage: $vm.storageUsedDesc,
                      usageRatio: $vm.storageUsedRatio
                  )
                  .titleFont(.inter(size: 16, weight: .medium))
                  .accountStyle()
                  .cornerRadius(radius)
                }
            }
            .scrollIndicators(.never)
        }
        .tracedView(self)
    }
}

// MARK: - WalletSettingView_Previews

struct CadenceAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
//          CadenceAccountView(address: "0x")
        }
    }
}
