import Foundation
import UIKit
import Flow
import SPIndicator
import FlowWalletKit

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
    static func getDebugAddress() -> String? {
      return LocalUserDefaults.shared.customWatchAddress
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
  
  @objc
  static func getWalletProfiles() async throws -> [String: Any] {
    
    var result = try? await getAllProfiles()
    if result == nil {
      let current = try await getCurrentProfile()
      result = [current]
    }
    let response = RNBridge.WalletProfilesResponse(profiles: result ?? [])
    return try response.toDictionary()
  }
  
  private static func getCurrentProfile() async throws -> RNBridge.WalletProfile {
    guard let userInfo = UserManager.shared.userInfo, let uid = UserManager.shared.activatedUID else {
      throw LLError.accountNotFound
    }
    var list: [RNBridge.WalletAccount] = []
    
    let accounts = await WalletManager.shared.currentNetworkAccounts
    for account in accounts {
      guard let result = try? await parseAccount(account: account, userId: uid) else {
        continue
      }
      list.append(contentsOf: result)
    }
    
    let profile = RNBridge.WalletProfile(
      name: userInfo.nickname,
      avatar: userInfo.avatar,
      uid: uid,
      accounts: list
      )
    return profile
  }
  
  private static func getAllProfiles() async throws -> [RNBridge.WalletProfile] {
    
    var resultOfProfiles: [RNBridge.WalletProfile] = []
    let allProfiles = ProfileManager.shared.profiles
    let supportNetworks: Set<Flow.ChainID> = [currentNetwork]
    for profile in allProfiles {
      
      guard let provider = await WalletManager.shared.keyProvider(profile: profile) else {
        continue
      }
      var walletAccounts: [RNBridge.WalletAccount] = []
      let walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
      try? await walletEntity.fetchAccount()
      guard let accountList =  walletEntity.accounts?[currentNetwork] else {
        continue
      }
      for account in accountList {
        guard let result = try? await parseAccount(account: account, userId: profile.uid) else {
          continue
        }
        walletAccounts.append(contentsOf: result)
      }
      let walletProfile = RNBridge.WalletProfile(
        name: profile.username ?? "",
        avatar: profile.avatar ?? "",
        uid: profile.uid,
        accounts: walletAccounts
        )
      resultOfProfiles.append(walletProfile)
    }
    return resultOfProfiles
  }
  
  private static func parseAccount(account: FlowWalletKit.Account, userId: String? = nil) async throws ->  [RNBridge.WalletAccount] {
    var list: [RNBridge.WalletAccount] = []
    try? await account.fetchAccount()
    list.append(account.toWalletAccount(userId: userId))
    if let linked = account.coa {
      list.append(linked.toWalletAccount(parentAddress: account.hexAddr, userId: userId))
    }

    if let childList = account.childs {
      let result = childList.map { $0.toWalletAccount(parentAddress: account.hexAddr, userId: userId) }
      list.append(contentsOf: result)
    }
    return list
  }
  
  // MARK: Toast
  @objc
  static func clearAllToasts() {
    HUD.dismissLoading()
  }
  
  @objc
  static func hideToast(id: String) {
    HUD.dismissLoading()
  }
  
  @objc
  static func showToast(titile: String, message: String, type: String, duration: Int) {
    switch type {
    case "info", "warning":
      HUD.info(title: titile, message: message)
    case "error":
      HUD.error(title: titile, message: message)
    case "success":
      HUD.success(title: titile, message: message)
    default:
      HUD.info(title: titile, message: message)
    }
  }
  
  @objc
  static func getLanguage() -> String {
    // zh,en,ru,ja
    let languageCode = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
    return languageCode
  }
  
  @objc
  static func logToNative(level: String, message: String, args: [String]) {
    // 'debug' | 'info' | 'warn' | 'error
    switch level {
    case "debug":
      log.debug(message, context: args)
    case "warn":
      log.warning(message, context: args)
    case "error":
      log.error(message, context: args)
    default:
      log.info(message, context: args)
    }
  }
}
