//
//  RecoveryPhraseBackupView.swift
//  FRW
//
//  Created by cat on 11/26/25.
//

import SwiftUI

struct RecoveryPhraseBackupView: RouteableView {
  var title: String = "backup".localized
  let mnemonic = WalletManager.shared.getCurrentMnemonic()

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("backup_recovery_title".localized)
        .font(.inter(size: 16, weight: .w600))
        .foregroundStyle(Color.Brain.Text.primary)
        .padding(.top, 16)
      card
      Spacer()
    }
    .padding(.top, 20)
    .padding(.horizontal, 18)
    .background(Color.Brain.Core.background)
    .applyRouteable(self)
  }

  @ViewBuilder
  var card: some View {
    Button {
      if mnemonic != nil {
        Router.route(to: RouteMap.Profile.manualBackup(true))
      } else {
        HUD.error(WalletError.invalidMnemonic)
      }
    } label: {
      HStack(alignment: .top) {
        Image("icon.recovery.green")
          .resizable()
          .renderingMode(.template)
          .aspectRatio(contentMode: .fit)
          .foregroundColor(Color.Brain.Primary.main)
          .frame(width: 28, height: 28)
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("recovery_phrase".localized)
              .font(.inter(size: 16, weight: .w600))
              .foregroundColor(Color.Brain.Text.primary)
              .frame(height: 20)

            Text("backup_recovery_sub".localized)
              .font(.inter(size: 14))
              .lineLimit(2)
              .foregroundColor(Color.Brain.Text.secondary)
          }
          Spacer()
          Image("device_arrow_right")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundColor(Color.Brain.Core.icons)
            .frame(width: 12, height: 12)
        }
      }
      .padding(18)
      .background(.Brain.Core.cards)
      .cornerRadius(16)
    }
    .buttonStyle(ScaleButtonStyle())
  }
}

#Preview {
  RecoveryPhraseBackupView()
}
