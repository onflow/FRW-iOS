//
//  AddAccountSheet.swift
//  FRW
//
//  Created by cat on 6/11/25.
//

import SwiftUI

struct AddAccountSheet: PresentActionView {
    var changeHeight: (() -> Void)?

    var title: String {
        ""
    }

    var detents: [UISheetPresentationController.Detent] {
        [.custom(resolver: { _ in
            154
        })]
    }

    @State var showAlert: Bool = false
    var onClick: StringClosure

    var body: some View {
        VStack(spacing: 2) {
            Button {
                if currentNetwork != .mainnet {
                    showAlert = true
                } else {
                    Router.dismiss {
                        createAccount()
                    }
                }

            } label: {
                HStack(spacing: 8) {
                    Image("wallet-create-icon")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.Summer.icons)
                        .frame(width: 24, height: 24)

                    Text("multi_create_account".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black8)

                    Spacer()
                }
                .padding(.vertical, 16)
            }

            Divider()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.Summer.line)

            Button {
                if currentNetwork != .mainnet {
                    showAlert = true
                } else {
                    Router.dismiss {
                        recoverAccount()
                    }
                }

            } label: {
                HStack(spacing: 8) {
                    Image("icon_download_arrow")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("multi_recover_account".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black8)

                    Spacer()
                }
                .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.Summer.sheetCard)
        .cornerRadius(16)
        .padding(18)
        .alert("wrong_network_title".localized, isPresented: $showAlert) {
            Button("switch_to_mainnet".localized) {
                WalletManager.shared.changeNetwork(.mainnet)
                Router.dismiss {
                    createAccount()
                }
            }
            Button("action_cancel".localized, role: .cancel) {}
        } message: {
            Text("wrong_network_des".localized)
        }
    }

    func createAccount() {
        onClick(AddAccountSheet.Action.create.rawValue)
    }

    func recoverAccount() {
        onClick(AddAccountSheet.Action.recover.rawValue)
    }
}

extension AddAccountSheet {
    enum Action: String {
        case create
        case recover
    }
}

#Preview {
    AddAccountSheet { _ in }
}
