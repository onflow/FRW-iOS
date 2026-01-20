//
//  WalletManager+KeyInvalidHandler.swift
//  FRW
//
//  Created by Claude on 2026/01/19.
//

import Foundation
import FlowWalletKit

// MARK: - Wallet Key Invalid Handler

extension WalletManager {

  /// Show alert to user about invalid key
  /// MUST be called on MainActor/main thread
  @MainActor
  func showKeyInvalidAlert(uid: String, reason: String) {
    log.error("[KeyInvalid] Wallet key invalid for uid: \(uid), reason: \(reason)")

    Task {
      let actions = [
        AlertAction(id: "cancel", title: "not_now".localized, style: .secondary),
        AlertAction(id: "restore", title: "wallet_key_invalid_restore".localized, style: .primary)
      ]

      let model = AlertModel(
        title: "wallet_key_invalid_title".localized,
        message: "wallet_key_invalid_message".localized,
        actions: actions,
        customContent: nil,
        wrapsInDefaultContainer: true
      )

      let selection = await AlertCenter.shared.present(model: model)

      if selection == "restore" {
        navigateToRestoreWallet()
      }
    }
  }

  /// Navigate to restore wallet page
  private func navigateToRestoreWallet() {
    log.info("[KeyInvalid] Navigating to restore wallet page")

    // Use Router to navigate directly to restore page
    Router.route(to: RouteMap.RestoreLogin.root)
  }
}
