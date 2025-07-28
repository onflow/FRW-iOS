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
    guard let topVC = UIApplication.shared.topMostViewController else {
      print("❌ DEBUG: No top view controller found")
      return
    }

    // Recursive function to find and dismiss ReactNativeViewController
    func findAndDismissReactNative(_ viewController: UIViewController) -> Bool {
      // Check if current view controller is ReactNativeViewController
      if let reactNativeVC = viewController as? ReactNativeViewController {
        print("✅ DEBUG: Found ReactNativeViewController")
        reactNativeVC.dismiss(animated: true, completion: nil)
        return true
      }

      // Check in navigation controller
      if let navigationController = viewController as? UINavigationController {
        if let reactNativeVC = navigationController.viewControllers.first(where: { $0 is ReactNativeViewController }) as? ReactNativeViewController {
          print("✅ DEBUG: Found ReactNativeViewController in navigation")

          if navigationController.topViewController === reactNativeVC {
            navigationController.popViewController(animated: true)
          } else {
            // Pop to the previous view controller
            if let rnIndex = navigationController.viewControllers.firstIndex(of: reactNativeVC) {
              let targetIndex = max(0, rnIndex - 1)
              let targetViewController = navigationController.viewControllers[targetIndex]
              print("✅ DEBUG: Popping to view controller at index \(targetIndex)")
              navigationController.popToViewController(targetViewController, animated: true)
            }
          }
          return true
        }
      }

      // Check in navigation stack if current VC has a navigation controller
      if let navigationController = viewController.navigationController {
        if let reactNativeVC = navigationController.viewControllers.first(where: { $0 is ReactNativeViewController }) as? ReactNativeViewController {
          print("✅ DEBUG: Found ReactNativeViewController in navigation stack")

          if navigationController.topViewController === reactNativeVC {
            navigationController.popViewController(animated: true)
          } else {
            // Pop to the previous view controller
            if let rnIndex = navigationController.viewControllers.firstIndex(of: reactNativeVC) {
              let targetIndex = max(0, rnIndex - 1)
              let targetViewController = navigationController.viewControllers[targetIndex]
              print("✅ DEBUG: Popping to view controller at index \(targetIndex)")
              navigationController.popToViewController(targetViewController, animated: true)
            }
          }
          return true
        }
      }

      // Recursively search in presented view controllers
      if let presentedVC = viewController.presentedViewController {
        return findAndDismissReactNative(presentedVC)
      }

      return false
    }

    // Start search from top view controller
    if !findAndDismissReactNative(topVC) {
      print("❌ DEBUG: ReactNativeViewController not found in view hierarchy")
    }
  }
}
