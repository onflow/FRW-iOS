import Foundation
import UIKit

@objc(TurboModuleSwift)
class TurboModuleSwift: NSObject {

    @objc
    static func getVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    @objc
    static func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    @objc
    static func getJWT() async throws -> String {
        return try await Network.fetchIDToken()
    }

    @objc
    static func getCurrentAddress() -> String? {
        return WalletManager.shared.selectedAccountAddress
    }

    @objc
    static func getNetwork() -> String? {
        return WalletManager.shared.currentNetwork.name
    }

    @objc
    static func sign(hexData: String) async throws -> String {
        return try await WalletManager.shared.sign(signableData: Data(hexData.hexValue)).hexString
    }

    @objc
    static func getCurrentAllAccounts() async throws -> [String: Any] {
      var list: [RNBridge.WalletAccount] = []
      if let account = await WalletManager.shared.mainAccount {
        list.append(account.toWalletAccount())
      }
      if let account = await WalletManager.shared.coa {
        list.append(account.toWalletAccount())
      }
      if let childList = await WalletManager.shared.childs {
        let result = childList.map { $0.toWalletAccount() }
        list.append(contentsOf: result)
      }

      let response = RNBridge.WalletAccountsResponse(accounts: list)
      return try response.toDictionary()
    }

    @objc
    static func getCOAFlowBalance() -> String {
      return ""
    }

  @objc
  static func getRecentContacts() async throws -> [String: Any] {
    let result = RecentListCache.cache.list.map { $0.toRNContact() }
    let response = RNBridge.RecentContactsResponse(contacts: result)
    return try response.toDictionary()
  }

  @objc
  static func getSignKeyIndex() -> Int {
    return WalletManager.shared.keyIndex
  }

  @objc
  static func closeRN() {
    runOnMain {
      // Debug current state
      ReactNativeViewController.debugInstances()

      // Try container management first
      if ReactNativeViewController.instances.count > 0 {
        print("✅ DEBUG: Found \(ReactNativeViewController.instances.count) ReactNativeViewController instances")
        ReactNativeViewController.dismissLatest()
        return
      }

      // Fallback to view hierarchy search if instances is empty
      print("⚠️ DEBUG: No instances found, falling back to view hierarchy search")

      guard let topVC = UIApplication.shared.topMostViewController else {
        print("❌ DEBUG: No top view controller found")
        return
      }

      // Check if top view controller is ReactNativeViewController
      if let reactNativeVC = topVC as? ReactNativeViewController {
        print("✅ DEBUG: Found ReactNativeViewController at top level")
        reactNativeVC.dismiss(animated: true, completion: nil)
        return
      }

      // Check if top view controller is a navigation controller with ReactNativeViewController
      if let navController = topVC as? UINavigationController {
        if let reactNativeVC = navController.topViewController as? ReactNativeViewController {
          print("✅ DEBUG: Found ReactNativeViewController as top of navigation")
          navController.popViewController(animated: true)
          return
        }
      }

      // Check if top view controller has a navigation controller with ReactNativeViewController
      if let navController = topVC.navigationController {
        if let reactNativeVC = navController.topViewController as? ReactNativeViewController {
          print("✅ DEBUG: Found ReactNativeViewController in navigation")
          navController.popViewController(animated: true)
          return
        }
      }

      print("❌ DEBUG: ReactNativeViewController not found anywhere")
    }
  }
}
