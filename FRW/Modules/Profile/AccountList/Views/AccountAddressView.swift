//
//  AccountAddressView.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import SwiftUI

struct AccountAddressView: View {
    var address: String
    var body: some View {
      HStack {
        VStack(alignment: .leading,spacing: 8) {
          Text("address".localized)
            .font(.inter(size: 14, weight: .medium))
            .foregroundStyle(Color.Brain.Text.primary)
          Text(address)
            .font(.inter(size: 16))
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(Color.Brain.Text.secondary)
        }
        Spacer()
        Button {
            UIPasteboard.general.string = address
            HUD.success(title: "Address Copied".localized)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Image("icon_copy")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.Theme.Text.black3)
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 4)
            .padding(.leading, 4)
        }
      }
      .accountStyle()
    }
}

#Preview {
  AccountAddressView(address: "0x11356")
}
