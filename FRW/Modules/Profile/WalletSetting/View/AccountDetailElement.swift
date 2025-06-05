//
//  AccountDetailElement.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import SwiftUI

struct AccountInfoWithEditView: View {
    var account: AccountInfoProtocol
    var onEdit: EmptyClosure

    var body: some View {
        HStack(spacing: 14) {
            account.avatar(isSelected: false, subAvatar: nil)
            HStack(spacing: 4) {
                if account.accountType != .main {
                    Image("icon-link")
                        .resizable()
                        .frame(width: 12, height: 12)
                }

                Text(account.infoName)
                    .font(.inter(size: 14, weight: .w600))
                    .foregroundStyle(Color.Theme.Text.black8)

                if account.accountType == .coa {
                    TagView(size: 8, type: .evm)
                }
            }

            Spacer(minLength: 8)

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
}

#Preview {
    AccountInfoWithEditView(account: AccountModel.mockSamples()[2].account) {}
}
