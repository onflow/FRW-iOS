import Foundation
import UIKit
import Flow
import SPIndicator
import FlowWalletKit
import KeychainAccess
import WalletCore

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
  // MARK: - Key Rotation (Seed Phrase)

  /// Create a new seed phrase and derive a default Flow account public key (P256/SHA2_256)
  /// - Parameter strength: BIP39 strength in bits (unused for now; library uses default)
  /// - Returns: Dictionary matching RN NewKeyInfo shape
  @objc
  static func createSeedKey(strength: Double) async throws -> [String: Any] {
    let mnemonicStrength = Int32(strength)
    guard let hdWallet = HDWallet(strength: mnemonicStrength, passphrase: "") else {
      HUD.error(title: "invalid_data".localized)
      //TODO:
      throw RNBridgeError.invalidParameters
    }
    
    let key = FlowWalletKit.SeedPhraseKey(hdWallet: hdWallet, storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage)
    
    guard let publicKey = key.publicKey(signAlgo: .ECDSA_SECP256k1) else {
      throw RNBridgeError.invalidParameters
    }
    let publicKeyHex = publicKey.hexString
    
    
    let flowKey: [String: Any] = [
      "publicKey": publicKeyHex,
      "signAlgo": Flow.SignatureAlgorithm.ECDSA_SECP256k1.index,
      "hashAlgo": Flow.HashAlgorithm.SHA2_256.index,
      "weight": 1000,
      "hashAlgoString": Flow.HashAlgorithm.SHA2_256.id,
      "signAlgoString": Flow.SignatureAlgorithm.ECDSA_SECP256k1.id,
    ]

    return [
      "seedphrase": hdWallet.mnemonic,
      "flowKey": flowKey,
    ]
  }

  /// Persist newly created seed phrase securely for current user
  /// The mnemonic is encrypted with the active uid and stored in the app keychain
  @objc
  static func saveNewKey(seedphrase: String) async throws {
    guard let uid = UserManager.shared.activatedUID, !uid.isEmpty else {
      HUD.error(LLError.accountNotFound)
      log.error(LLError.accountNotFound.localizedDescription)
      throw LLError.accountNotFound
    }

    guard !seedphrase.isEmpty else {
      HUD.error(WalletError.invalidMnemonic)
      log.error("[Blocto] seed phrase is empty")
      throw WalletError.invalidMnemonic
    }
    guard let hdWallet = HDWallet(mnemonic: seedphrase, passphrase: "") else {
      HUD.error(WalletError.invalidMnemonic)
      log.error("[Blocto] failed to create hd wallet from seed phrase")
      throw WalletError.invalidMnemonic
    }
    
    let provider = FlowWalletKit.SeedPhraseKey(
      hdWallet: hdWallet,
      storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage
    )
    let key = provider.createKey(uid: uid)
    try provider.store(
      id: key,
      password: KeyProvider.password(with: uid)
    )
    log.debug("[Blocto] save seedphrase successfully.\(key)")
  }

  /// Toggle screen security overlay to discourage screenshots/switcher snapshots
  @objc
  static func setScreenSecurityLevel(level: String) {
    let secure = level.lowercased() == "secure"
    runOnMain {
      if secure {
        showSecurityOverlay()
      } else {
        hideSecurityOverlay()
      }
    }
  }

  private static var securityOverlayWindow: UIWindow?

  private static func showSecurityOverlay() {
    if securityOverlayWindow != nil { return }

    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }) else { return }

    let overlay = UIWindow(windowScene: scene)
    overlay.frame = UIScreen.main.bounds
    overlay.windowLevel = .alert + 1

    let vc = UIViewController()
    vc.view.backgroundColor = UIColor.black
    vc.view.isUserInteractionEnabled = false
    overlay.rootViewController = vc
    overlay.isHidden = false

    securityOverlayWindow = overlay
  }

  private static func hideSecurityOverlay() {
    guard let overlay = securityOverlayWindow else { return }
    overlay.isHidden = true
    overlay.rootViewController = nil
    securityOverlayWindow = nil
  }

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

  @objc
  static func signRotationRequest(publicKey: String, address: String, hash: String) async throws -> [String: Any]  {
    
    log.debug("[Blocto] start signing")
    guard UserManager.shared.activatedUID != nil, let jwt = try? await getJWT() else {
      HUD.error(LLError.accountNotFound)
      throw LLError.accountNotFound
    }
    guard let currentAddress = await WalletManager.shared.getAddress(), let currentPublicKey = await WalletManager.shared.getCurrentPublicKey() else {
      log.error("[Blocto]  Cannot get current address. Skipping. ")
      HUD.error(WalletError.emptyAddress)
      throw WalletError.emptyAddress
    }
    guard currentAddress == address else {
      log.error("[Blocto]  Provided address does not match the selected one. Skipping.")
      HUD.error(WalletError.invaildAddress)
      throw WalletError.invaildAddress
    }
    
    guard let data = jwt.addUserMessage() else {
      HUD.error(WalletError.invalidSignData)
      throw WalletError.invalidSignData
    }
    
    let accountKey = await WalletManager.shared.mainAccount?.account.keys.first { $0.publicKey.description == currentPublicKey }
    guard let accountKey else {
      HUD.error(WalletError.invalidPublicKey)
      throw WalletError.invalidPublicKey
    }
    let signature = try await WalletManager.shared.sign(signableData: data).hexString
    
    return [
      "public_key": currentPublicKey,
      "hash_algo": accountKey.hashAlgo.index,
      "sign_algo": accountKey.signAlgo.index,
      "signature": signature,
      "sign_message": jwt,
      "weight": 1000
    ]
  }

  @objc
  static func removeOldKey(address: String, publicKey: String) async throws {
    log.debug("[Blocto] start removing key")
    guard let uid = UserManager.shared.activatedUID else {
      throw LLError.accountNotFound
    }
    guard let currentAddress = await WalletManager.shared.getAddress() else {
      log.debug("[Blocto]  Cannot get current address. Skipping. ")
      throw WalletError.emptyAddress
    }
    guard currentAddress == address else {
      log.debug("[Blocto]  Provided address does not match the selected one. Skipping.")
      throw WalletError.invaildAddress
    }
    let key = KeyProvider.createKey(userId: uid, publicKey: publicKey)
    let keyProvider = await WalletManager.shared.keyProvider(with: key)
    try keyProvider?.remove(id: key)
    log.debug("[Blocto] remove key successfully")
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
  static func showToast(title: String, message: String? = nil, type: String, duration: Int) {
    switch type {
    case "info", "warning":
      HUD.info(title: title, message: message)
    case "error":
      HUD.error(title: title, message: message)
    case "success":
      HUD.success(title: title, message: message)
    default:
      HUD.info(title: title, message: message)
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
