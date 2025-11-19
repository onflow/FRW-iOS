//
//  CadenceAccountView.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import SwiftUI

// MARK: - CadenceAccountView

struct CadenceAccountView: View {

  @StateObject private var vm = WalletSettingViewModel()
  @State var isHidden = false
  // MARK: Internal
  @Binding var account: RNBridge.WalletAccount
  @Binding var showAccountEditor: Bool
  private let radius: CGFloat = 16


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
                    AccountHeaderView(account: $account, parentAccount: nil)
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
                  
                  AccountOptionView(title: "show_account_title".localized, style: .toggle, isOn: isHidden) { toggle in
                    log.info("---")
                  }
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
        }
        .tracedView(self)
    }

    func onReload() {
      ProfileManager.shared.updateAccount(at: account.address)
      account = account.updatedFromEmoji()
    }

    func onlyShowInfo() -> Bool {
//        let list = EVMAccountManager.shared.accounts
//            .filter { $0.showAddress.lowercased() == address.lowercased() }
//        return !list.isEmpty
      return false
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
