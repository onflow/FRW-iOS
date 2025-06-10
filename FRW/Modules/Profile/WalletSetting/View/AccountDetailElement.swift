//
//  AccountDetailElement.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import SwiftUI

/// Used in account detail
struct AccountInfoCard: View {
    var account: AccountInfoProtocol
    var onEdit: EmptyClosure

    var body: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    account.avatar(isSelected: false, subAvatar: nil)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mainAccountName)
                            .font(.inter(size: 16, weight: .w600))
                            .foregroundStyle(Color.Theme.Text.black8)

                        if account.accountType != .main {
                            HStack(spacing: 4) {
                                if account.accountType != .main {
                                    Image("icon-link")
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                }

                                Text(account.infoName)
                                    .font(.inter(size: 14))
                                    .foregroundStyle(Color.Theme.Text.black8)

                                if account.accountType == .coa {
                                    TagView(size: 8, type: .evm)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 8)

                    if account.accountType != .child {
                        Button {
                            onEdit()
                        } label: {
                            Image("icon-edit-child-account")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .padding(.vertical, 6)
                                .padding(.leading, 6)
                        }
                    }
                }

                if account.accountType != .main {
                    LineView()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("description".localized)
                            .font(.inter(size: 12))
                            .foregroundStyle(Color.Summer.Text.secondary)

                        Text("linked_description".localized)
                            .font(.inter(size: 16))
                            .foregroundStyle(Color.Theme.Text.black8)
                    }
                }
            }
            .cardStyle()

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("address".localized)
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Summer.Text.secondary)

                    Text(account.infoAddress)
                        .font(.inter(size: 16))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(Color.Theme.Text.black8)
                }
                Spacer(minLength: 12)

                Button {
                    UIPasteboard.general.string = account.infoAddress
                    HUD.success(title: "Address Copied".localized)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image("icon_button_copy")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .cardStyle()
        }
    }

    var mainAccountName: String {
        guard let mainAccount = UserManager.shared.mainAccount(by: account.infoAddress) else {
            return ""
        }
        return mainAccount.infoName
    }
}

#Preview {
    VStack(spacing: 32) {
        AccountInfoCard(account: AccountModel.mockSamples()[0].account) {}
        AccountInfoCard(account: AccountModel.mockSamples()[1].account) {}
        AccountInfoCard(account: AccountModel.mockSamples()[2].account) {}
    }
    .background(Color.black)
}
