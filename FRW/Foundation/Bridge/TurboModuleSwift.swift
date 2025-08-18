import Foundation
import UIKit
import Flow

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
    static func getNetwork() -> String {
        return WalletManager.shared.currentNetwork.name
    }
  
    @objc
    static func isFreeGasEnabled() -> Bool {
        return RemoteConfigManager.shared.freeGasEnabled
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
  static func scanQRCode() async throws -> String {
    guard let lastVC = await ReactNativeViewController.getLatestInstance() else {
      throw RNBridgeError.scanInvalidProvider
    }
    
    return await withCheckedContinuation { continuation in
      var isResumed = false
      let handler: SPQRCodeCallback = { data, vc in
        switch data {
        case let .flowWallet(address), let .ethWallet(address):
          DispatchQueue.main.async {
            vc.stopRunning()
            vc.dismiss(animated: true, completion: {
              if !isResumed {
                isResumed = true
                continuation.resume(returning: address)
              }
            })
          }
        default:
            break
        }
      }
      DispatchQueue.main.async {
        SPQRCode.scanning(handled: handler, click: nil, on: lastVC)
      }
    }
  }
  
  @objc
  static func closeRN(id: String?) {
    runOnMain {
      if let id {
        ReactNativeCoordinator.shared.closeById(id)
      } else {
        // Use the new coordinator to manage ReactNative instances
        print("🔄 DEBUG: Attempting to close ReactNative via coordinator")
        ReactNativeCoordinator.shared.closeLatest()
      }
    }
  }
}

extension TurboModuleSwift {
  @objc
  static func listenTransaction(txid: String) {
    guard !txid.isEmpty else {
      return
    }
    let holder = TransactionManager.TransactionHolder(id: Flow.ID(hex: txid), type: .common)
    TransactionManager.shared.newTransaction(holder: holder)
  }
  
  @objc
  static func getEnv() -> [String: String] {
    return [
      "NODE_API_URL": Config.get(.lilicoWeb).removeSuffix("/api/"),
      "GO_API_URL": Config.get(.lilico),
      "INSTABUG_TOKEN": ServiceConfig.instabugRNToken,
    ]
  }
}

// MARK: - React Native Management
extension TurboModuleSwift {
  
  @objc
  static func closeRNById(_ instanceId: String) {
    runOnMain {
      print("🔄 DEBUG: Attempting to close ReactNative instance: \(instanceId)")
      ReactNativeCoordinator.shared.closeById(instanceId)
    }
  }
  
  @objc
  static func closeAllRN() {
    runOnMain {
      print("🔄 DEBUG: Attempting to close all ReactNative instances")
      ReactNativeCoordinator.shared.closeAll()
    }
  }
  
  @objc
  static func getRNInstanceCount() -> Int {
    return ReactNativeCoordinator.shared.getInstanceCount()
  }
  
  @objc
  static func debugRNInstances() {
    ReactNativeCoordinator.shared.debugAllInstances()
  }
}

// MARK: - Wallet
extension TurboModuleSwift {
  
  @objc
  static func getSelectedWalletAccount() async throws -> [String: Any] {
    let manager = await WalletManager.shared
    if let account = await manager.selectedChildAccount {
      return try account.toWalletAccount().toDictionary()
    } else if let account = await manager.selectedEVMAccount {
      return try account.toWalletAccount().toDictionary()
    } else if let account = await manager.mainAccount {
      return try account.toWalletAccount().toDictionary()
    }
    return [:]
  }
  
  @objc
  static func getCurrency() -> [String: Any] {
    let currency = CurrencyCache.cache.currentCurrency
    let rate = CurrencyCache.cache.currentCurrencyRate
    let model = RNBridge.Currency(name: currency.rawValue, symbol: currency.symbol, rate: String(rate))
    return (try? model.toDictionary()) ?? [:]
  }
  
  @objc
  static func getTokenRate(tokenId: String) -> Double {
    let response = CoinRateCache.cache.getSummary(by: tokenId)
    let result =  response?.getLastRate() ?? 0
    return result
  }
}
