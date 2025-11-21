//
//  CopyAddressView.swift
//  FRW
//
//  Created by cat on 11/21/25.
//

import SwiftUI

struct CopyAddressView: View {
  let account: WalletAccount

    var body: some View {
      Button {
        if account.type == .coa {
          Task {
            await AlertCenter.shared.presentCOACopy(address: account.address)
          }
        } else {
          UIPasteboard.general.string = account.address
          HUD.success(title: "Address Copied".localized)
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
      } label: {
        Image("icon_copy")
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Color.Theme.Text.black3)
            .frame(width: 24, height: 24)
            .padding(8)
      }
    }
}

#Preview {
  CopyAddressView(account: .mockMain())
}
