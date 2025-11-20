//
//  AccountRow.swift
//  FRW
//
//  Created by cat on 7/11/25.
//

import SwiftUI

extension SideMenuView {
  struct AccountRow: View {
      let account: SideMenuItem
      var isActivity: Bool = false
      var onClick: ((SideMenuItem) -> Void)?

      private var isCOA: Bool {
        account.account.type == .coa
      }

      private var isEOA: Bool {
        account.account.type == .eoa
      }
      
    
      var body: some View {
        Button {
          onClick?(account)
        } label: {
          HStack(spacing: 8) {
            if account.account.type != .main && (account.account.parent?.address != nil) {
              Image("account_link_mark")
                .resizable()
                .frame(width: 20, height: 20)
            }
            WalletAvatarView(
              emoji: account.account.displayInfo.emoji,
              avatar: account.account.displayInfo.avatar,
              showBorder: isActivity
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                  Text(account.account.displayInfo.name)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.black8)
                        .frame(height: 22)
                  if isEOA {
                    EVMTagView()
                  }
                  if isCOA {
                    COATagView()
                  }

                }

              Text(account.account.address)
                    .font(.inter(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(Color.Theme.Text.black3)
                    .frame(height: 20)

              Text(account.account.displayBalance)
                  .font(.inter(size: 12))
                  .lineLimit(1)
                  .truncationMode(.middle)
                  .foregroundStyle(Color.Theme.Text.black8)
            }
            Spacer()

            Button {
                UIPasteboard.general.string = account.account.address
                HUD.success(title: "Address Copied".localized)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack {
                    Image("icon_copy")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.Theme.Text.black3)
                        .frame(width: 24, height: 24)
                        .offset(x: -10)
                }
                .padding(10)
            }
          }
          .frame(height: 56)
          .padding(.vertical, 10)
        }
        .buttonStyle(ScaleButtonStyle())
      }
  }
}


#Preview {
  SideMenuView.AccountRow(
        account: SideMenuItem(
          account: WalletAccount.mockMain()
        )
    )
}

