//
//  EVMCopyAlertView.swift
//  FRW
//
//  Created by cat on 11/21/25.
//

import SwiftUI

struct EVMCopyAlertView: View {
  let address: String
  let onCopy: () -> Void
  let onCancel: () -> Void
    var body: some View {
      VStack(spacing: 16) {
        VStack(spacing: 0) {
          HStack {
            Color.clear
              .frame(width: 32, height: 32)
            Spacer()

            Text("EVM on Flow address")
              .font(.inter(size: 18, weight: .bold))
              .foregroundStyle(Color.Brain.Text.primary)
            Spacer()
            Button {
              onCancel()
            }label: {
              Image(systemName: "xmark")
                .font(.system(size: 12))
                .foregroundStyle(Color.Brain.Text.primary)
                .padding(10)
                .offset(y: -10)
            }
          }
          .frame(height: 32)
          COATagView()
        }

        Text("copy_evm_hint_des".localized)
          .font(.inter(size: 14, weight: .light))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.Brain.Text.primary)
        VStack {
          Text(address)
            .font(.inter(size: 14, weight: .semibold))
            .foregroundStyle(Color.Brain.Text.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .padding(.horizontal, 24)
        .background(Color.Brain.Light.lines10)
        .cornerRadius(8)

        WalletSendButtonView(
            allowEnable: .constant(true),
            buttonText: "copy_evm_button".localized,
            activeColor: Color.Brain.Light.lines
        ) {
          UIPasteboard.general.string = address
          HUD.success(title: "Address Copied".localized)
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
          DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onCopy()
          }
        }

      }
      .padding(16)
      .background(Color.Theme.BG.bg1)
      .cornerRadius(16)
      .frame(width: 340)
    }
}

#Preview {
  EVMCopyAlertView(address: "0x3333", onCopy: {}, onCancel: {})
}
