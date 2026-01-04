//
//  AccountNotFoundAlertView.swift
//  FRW
//
//  Created by cat on 10/28/25.
//

import SwiftUI

struct AccountNotFoundAlertView: View {
  let onCreateWallet: () -> Void
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      // Title
      Text("account_not_found".localized)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.black)
        .padding(.top, 24)
        .padding(.horizontal, 24)
      
      // Message with styled phrase
      Text(AttributedString(accountNotFoundDesc))
      
      // Create Wallet Button
      Button(action: onCreateWallet) {
        Text("create_wallet".localized)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(Color.Theme.Text.white9)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(Color.Theme.Text.black)
          .cornerRadius(12)
      }
      .padding(.top, 32)
      .padding(.horizontal, 24)
      
      // Cancel Button
      Button(action: onCancel) {
        Text("cancel".localized)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color.Brain.Text.primary)
          .frame(maxWidth: .infinity)
          .frame(height: 56)
          .background(Color.Theme.Background.grey)
          .cornerRadius(12)
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 24)
    }
    .padding(16)
    .background(Color.Theme.BG.bg1)
    .cornerRadius(16)
    .frame(width: 340)
    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 4)
  }
  
  private var accountNotFoundDesc: NSAttributedString  {
      let normalDict = [NSAttributedString.Key.foregroundColor: UIColor.LL.Neutrals.text]
      let highlightDict =
          [NSAttributedString.Key.foregroundColor: UIColor.LL.Primary.salmonPrimary]

      var str = NSMutableAttributedString(
          string: "account_not_found_prev".localized,
          attributes: normalDict
      )
      str.append(NSAttributedString(
          string: "account_not_found_highlight".localized,
          attributes: highlightDict
      ))
      str.append(NSAttributedString(
          string: "account_not_found_suff".localized,
          attributes: normalDict
      ))

      return str
  }
}

