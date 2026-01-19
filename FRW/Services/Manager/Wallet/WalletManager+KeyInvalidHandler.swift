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

    #if DEBUG
    // Check Wallet Health action (for debugging)
      alert.addAction(UIAlertAction(
        title: "Check Health",
        style: .default,
        handler: { [weak self] _ in
          self?.showWalletHealthCheck()
        }
      ))
    #endif

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

  /// Show wallet health check dialog (for debugging)
  private func showWalletHealthCheck() {
    Task {
      do {
        let (isHealthy, diagnostic) = try await checkWalletHealth()

        await MainActor.run {
          guard let topVC = UIApplication.shared.topViewController() else { return }

          let alert = UIAlertController(
            title: isHealthy ? "✅ Wallet Healthy" : "❌ Wallet Unhealthy",
            message: diagnostic,
            preferredStyle: .alert
          )

          if !isHealthy {
            alert.addAction(UIAlertAction(
              title: "Repair Wallet",
              style: .default,
              handler: { [weak self] _ in
                self?.performWalletRepair()
              }
            ))
          }

          alert.addAction(UIAlertAction(
            title: "OK",
            style: .cancel,
            handler: nil
          ))

          topVC.present(alert, animated: true)
        }
      } catch {
        log.error("[KeyInvalid] Health check failed: \(error)")
      }
    }
  }

  /// Perform wallet repair
  private func performWalletRepair() {
    Task {
      do {
        let result = try await repairWallet()

        await MainActor.run {
          guard let topVC = UIApplication.shared.topViewController() else { return }

          let alert = UIAlertController(
            title: "Repair Complete",
            message: result,
            preferredStyle: .alert
          )

          alert.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: { [weak self] _ in
              // Reinitialize wallet
              self?.reinitializeWallet()
            }
          ))

          topVC.present(alert, animated: true)
        }
      } catch {
        await MainActor.run {
          guard let topVC = UIApplication.shared.topViewController() else { return }

          let alert = UIAlertController(
            title: "Repair Failed",
            message: "Failed to repair wallet: \(error.localizedDescription)",
            preferredStyle: .alert
          )

          alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

          topVC.present(alert, animated: true)
        }
      }
    }
  }
}

// MARK: - Wallet Health & Repair

extension WalletManager {

  /// Check if wallet key is healthy (active on-chain)
  func checkWalletHealth() async throws -> (Bool, String) {
    guard let _ = UserManager.shared.activatedUID else {
      return (false, "No activated UID")
    }
    guard let provider = keyProvider else {
      return (false, "No key provider found")
    }
    guard let mainAcc = mainAccount else {
      return (false, "No main account loaded")
    }

    let account = mainAcc.account

    if let matchedKey = KeyProvider.findMatchingActiveKey(for: provider, in: account) {
      let diagnostic = """
      ✅ Wallet Health: GOOD
      - Key Index: \(matchedKey.index)
      - Weight: \(matchedKey.weight)
      - Revoked: \(matchedKey.revoked)
      """
      return (true, diagnostic)
    } else {
      let activeKeys = account.keys.filter { !$0.revoked && $0.weight >= 1000 }
      let diagnostic = """
      ❌ Wallet Health: UNHEALTHY
      - Current key NOT active on-chain
      - Active keys: \(activeKeys.count)
      - Action: Run wallet repair
      """
      return (false, diagnostic)
    }
  }

  /// Repair wallet by cleaning revoked keys and reinitializing
  func repairWallet() async throws -> String {
    log.info("[Repair] Starting wallet repair")

    guard let uid = UserManager.shared.activatedUID else {
      throw LLError.accountNotFound
    }
    guard let address = mainAccount?.address.hexAddr else {
      throw WalletError.emptyAddress
    }

    // Fetch account from chain
    let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)
    let activeKeys = account.keys.filter { !$0.revoked && $0.weight >= 1000 }
    let revokedKeys = account.keys.filter { $0.revoked }

    guard !activeKeys.isEmpty else {
      throw WalletError.noActiveKeys
    }

    // Remove revoked keys from storage
    guard let userStore = userStore(with: uid) else {
      throw LLError.accountNotFound
    }

    let storage: FlowWalletKit.KeychainStorage
    switch userStore.keyType {
    case .seedPhrase:
      storage = SeedPhraseKey.seedPhraseStorage
    case .privateKey, .keyStore:
      storage = FlowWalletKit.PrivateKey.PKStorage
    case .secureEnclave:
      storage = SecureEnclaveKey.KeychainStorage
    }

    let revokedPublicKeys = Set(revokedKeys.map { $0.publicKey.hex })
    let allStoredKeys = KeyProvider.keys(with: uid, in: storage)
    let pw = KeyProvider.password(with: uid)
    var removedCount = 0

    for keyId in allStoredKeys {
      // Check if this key is revoked by comparing public keys
      var shouldRemove = false

      switch userStore.keyType {
      case .seedPhrase:
        if let spKey = try? SeedPhraseKey.get(id: keyId, password: pw, storage: storage) {
          let p256 = spKey.publicKey(signAlgo: .ECDSA_P256)?.hexString
          let secp = spKey.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString
          shouldRemove = (p256 != nil && revokedPublicKeys.contains(p256!)) ||
                        (secp != nil && revokedPublicKeys.contains(secp!))
        }
      case .privateKey, .keyStore:
        if let pkKey = try? FlowWalletKit.PrivateKey.get(id: keyId, password: pw, storage: storage) {
          let p256 = pkKey.publicKey(signAlgo: .ECDSA_P256)?.hexString
          let secp = pkKey.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString
          shouldRemove = (p256 != nil && revokedPublicKeys.contains(p256!)) ||
                        (secp != nil && revokedPublicKeys.contains(secp!))
        }
      case .secureEnclave:
        if let seKey = try? SecureEnclaveKey.get(id: keyId, password: pw, storage: storage) {
          let p256 = seKey.publicKey(signAlgo: .ECDSA_P256)?.hexString
          shouldRemove = p256 != nil && revokedPublicKeys.contains(p256!)
        }
      }

      if shouldRemove {
        do {
          try storage.remove(keyId)
          removedCount += 1
          log.info("[Repair] Removed revoked key: \(keyId)")
        } catch {
          log.error("[Repair] Failed to remove key: \(keyId), error: \(error)")
        }
      }
    }

    // Update UserStore with first active key
    if let firstActiveKey = activeKeys.first {
      let updatedStore = UserManager.StoreUser(
        publicKey: firstActiveKey.publicKey.hex,
        address: address,
        userId: uid,
        keyType: userStore.keyType,
        account: firstActiveKey.toStoreKey()
      )
      LocalUserDefaults.shared.addUser(user: updatedStore)
    }

    // Reinitialize wallet
    await MainActor.run {
      reinitializeWallet()
    }

    return "Wallet repair completed - removed \(removedCount) revoked keys"
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
