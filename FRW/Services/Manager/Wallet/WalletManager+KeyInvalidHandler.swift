//
//  WalletManager+KeyInvalidHandler.swift
//  FRW
//
//  Created by Claude on 2026/01/19.
//

import Foundation
import UIKit
import FlowWalletKit

// MARK: - Wallet Key Invalid Handler

extension WalletManager {

  /// Setup notification observer for wallet key invalid events
  func setupKeyInvalidObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWalletKeyInvalid(_:)),
      name: .walletKeyInvalid,
      object: nil
    )
  }

  /// Handle wallet key invalid notification
  @objc private func handleWalletKeyInvalid(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
          let uid = userInfo["uid"] as? String else {
      return
    }

    let reason = userInfo["reason"] as? String ?? "No active key found"
    log.error("[KeyInvalid] Wallet key invalid for uid: \(uid), reason: \(reason)")

    // Show alert on main thread
    DispatchQueue.main.async { [weak self] in
      self?.showKeyInvalidAlert(uid: uid, reason: reason)
    }
  }

  /// Show alert to user about invalid key
  private func showKeyInvalidAlert(uid: String, reason: String) {
    guard let topVC = UIApplication.shared.topViewController() else {
      log.error("[KeyInvalid] Cannot find top view controller")
      return
    }

    let alert = UIAlertController(
      title: "Wallet Access Issue",
      message: "We couldn't find a valid key for your wallet. This may happen after a key rotation. Please restore your wallet to continue.",
      preferredStyle: .alert
    )

    // Restore Wallet action
    alert.addAction(UIAlertAction(
      title: "Restore Wallet",
      style: .default,
      handler: { [weak self] _ in
        self?.navigateToRestoreWallet()
      }
    ))

    // Cancel action
    alert.addAction(UIAlertAction(
      title: "Cancel",
      style: .cancel,
      handler: nil
    ))

    topVC.present(alert, animated: true)
  }

  /// Navigate to restore wallet page
  private func navigateToRestoreWallet() {
    log.info("[KeyInvalid] Navigating to restore wallet page")

    // Use Router to navigate directly to restore page
    Router.route(to: RouteMap.RestoreLogin.root)
  }
}

// MARK: - UIApplication Extension

extension UIApplication {
  func topViewController(controller: UIViewController? = nil) -> UIViewController? {
    let controller = controller ?? keyWindow?.rootViewController

    if let navigationController = controller as? UINavigationController {
      return topViewController(controller: navigationController.visibleViewController)
    }
    if let tabController = controller as? UITabBarController {
      if let selected = tabController.selectedViewController {
        return topViewController(controller: selected)
      }
    }
    if let presented = controller?.presentedViewController {
      return topViewController(controller: presented)
    }
    return controller
  }

  var keyWindow: UIWindow? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }
}
