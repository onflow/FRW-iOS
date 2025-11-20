//
//  AccountHeaderView.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import SwiftUI
import Kingfisher

struct AccountHeaderView: View {
  @Binding var account: WalletAccount
  var parentAccount: WalletAccount?
  var desc: String? = nil //TODO: Child Account Desc


  var body: some View {
    VStack {
      HStack(spacing: 12) {
        if let emoji = account.displayInfo.emoji {
            emoji.icon(size: 36)
          } else {
            KFImage.url(URL(string: account.displayInfo.avatar ?? ""))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .cornerRadius(18)
          }
          VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
              Text(account.displayInfo.name)
                .font(.inter(size: 16, weight: .w600))
                .foregroundStyle(Color.Theme.Text.black8)
              if account.type == .coa {
                COATagView()
              }
              if account.type == .eoa {
                EVMTagView()
              }
            }
            if let parentAccount {
              HStack(spacing: 3) {
                Image("account_link_mark")
                  .resizable()
                  .frame(width: 14, height: 14)
                Text(parentAccount.displayInfo.name)
                  .font(.inter(size: 12))
                  .foregroundStyle(Color.Theme.Text.black8)
              }
            }
          }

            Spacer()
        if account.type != .child {
          HStack {
              Image("icon-edit-child-account")
                  .resizable()
                  .renderingMode(.template)
                  .frame(width: 24, height: 24)
                  .foregroundStyle(Color.Theme.Text.black3)
          }
          .padding(.vertical, 4)
          .padding(.leading, 4)
        }
        }
        .accountStyle()
      if let descStr = desc {
        Divider()
          .foregroundStyle(Color.Brain.Core.dividers)
        VStack(alignment: .leading,spacing: 8) {
          Text("description".localized)
            .font(.inter(size: 14, weight: .medium))
            .foregroundStyle(Color.Brain.Text.primary)
          Text(descStr)
            .font(.inter(size: 16))
            .lineLimit(3)
            .truncationMode(.middle)
            .foregroundStyle(Color.Brain.Text.secondary)
        }
          .accountStyle()
      }
    }
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var account = WalletAccount.mockMain()

    let parentAccount = WalletAccount.mockMain()

    var body: some View {
      AccountHeaderView(account: $account, parentAccount: parentAccount)
    }
  }

  return PreviewWrapper()
}
