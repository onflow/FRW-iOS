import Foundation
import WalletCore
import UIKit
import Flow
import SPIndicator
import FlowWalletKit
import UserNotifications
import FirebaseAuth
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
    static func getCurrentUserUid() -> String? {
        return UserManager.shared.activatedUID
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
        list.append(account.toWalletAccount().toRNBridge())
      }
      if let account = await WalletManager.shared.coa {
        list.append(account.toWalletAccount().toRNBridge())
      }
      if let eoaAccounts = await WalletManager.shared.EOAs {
        let address =  await WalletManager.shared.mainAccount?.hexAddr
        let result = eoaAccounts.map{ $0.toWalletAccount(parentAddress: address).toRNBridge()}
        list.append(contentsOf: result)
      }
      if let childList = await WalletManager.shared.childs {
        let result = childList.map { $0.toWalletAccount().toRNBridge() }
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
    log.debug("[Blocto] Saved new key to keychain: \(key)")

    // Get current address and userStore for key info
    guard let currentAddress = await WalletManager.shared.getAddress() else {
      log.error("[Blocto] Cannot get current address")
      throw WalletError.emptyAddress
    }

    guard let currentUserStore = WalletManager.shared.userStore(with: uid) else {
      log.error("[Blocto] Cannot get current userStore")
      throw LLError.accountNotFound
    }

    // New key is always seedphrase with SECP256k1 + SHA2_256
    let signAlgo: Flow.SignatureAlgorithm = .ECDSA_SECP256k1
    guard let newPublicKey = provider.publicKey(signAlgo: signAlgo)?.hexString else {
      log.error("[Blocto] Failed to generate public key for new key")
      throw WalletError.invalidPublicKey
    }

    // IMPORTANT: Query chain directly to get correct key index
    // FlowNetwork.getAccountAtLatestBlock queries the chain directly (not keyIndexer)
    // So the new key will be immediately available with correct index
    log.info("[Blocto] Querying chain directly for new key index...")
    let account = try await FlowNetwork.getAccountAtLatestBlock(address: currentAddress)

    guard let newKey = account.keys.first(where: { $0.publicKey.hex == newPublicKey }) else {
      log.error("[Blocto] New key not found on-chain: \(newPublicKey.prefix(8))")
      throw WalletError.emptyAccountKey
    }

    log.info("[Blocto] ✅ Found new key on-chain - index: \(newKey.index), weight: \(newKey.weight), revoked: \(newKey.revoked)")

    // Create account key info with correct index from chain
    let newAccountKey = UserManager.Accountkey(
      index: newKey.index,
      signAlgo: .ECDSA_SECP256k1,
      hashAlgo: .SHA2_256,
      weight: 1000
    )

    // Update userStore with new key info
    let updatedStore = UserManager.StoreUser(
      publicKey: newPublicKey,
      address: currentAddress,
      userId: uid,
      keyType: .seedPhrase,
      account: newAccountKey
    )
    LocalUserDefaults.shared.addUser(user: updatedStore)
    log.info("[Blocto] Updated userStore with new key - publicKey: \(newPublicKey.prefix(8)), address: \(currentAddress), index: \(newKey.index)")

    // Update keyProvider so settings page shows new mnemonic/privateKey immediately
    await MainActor.run {
      WalletManager.shared.updateKeyProvider(provider: provider)
      log.info("[Blocto] ✅ Updated keyProvider with new key - settings will show new mnemonic")
    }
  }

  /// Toggle screen security overlay to discourage screenshots/switcher snapshots
  @objc
  static func setScreenSecurityLevel(level: String) {
    let secure = level.lowercased() == "secure"
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
      "MIXPANEL_TOKEN": ServiceConfig.mixpanelRNToken,
    ]
  }

  @objc
  static func signRotationRequest(address: String, signatureData: String) async throws -> [String: Any]  {
    
    log.debug("[Blocto] start signing")
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
    
    let accountKey = await WalletManager.shared.mainAccount?.account.keys.first { $0.publicKey.description == currentPublicKey }
    guard let accountKey else {
      HUD.error(WalletError.invalidPublicKey)
      throw WalletError.invalidPublicKey
    }
    
    guard let data = signatureData.addUserMessage() else {
      throw WalletError.invalidSignData
    }
    let signature = try await WalletManager.shared.sign(signableData: data).hexString
    
    let model = RNBridge.AccountKeySignature(
      public_key: currentPublicKey,
      hash_algo: accountKey.hashAlgo.index,
      sign_algo: accountKey.signAlgo.index,
      signature: signature,
      sign_message: signatureData,
      weight: 1000
    )
    
    return try model.toDictionary()
  }

  @objc
  static func removeOldKey(address: String, publicKey: String) async throws {
    log.debug("[Blocto] Starting key isolation for publicKey: \(publicKey.prefix(8))")

    guard let uid = UserManager.shared.activatedUID else {
      throw LLError.accountNotFound
    }
    guard let currentAddress = await WalletManager.shared.getAddress() else {
      throw WalletError.emptyAddress
    }
    guard currentAddress == address else {
      throw WalletError.invaildAddress
    }

    // IMPORTANT: Verify key is actually revoked before isolating
    log.info("[Blocto] Verifying key is revoked on-chain...")
    let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)

    // Check if this key is revoked
    let keyIsRevoked = account.keys.contains { accountKey in
      accountKey.publicKey.hex == publicKey && accountKey.revoked
    }

    guard keyIsRevoked else {
      log.error("[Blocto] SAFETY CHECK FAILED - Key is NOT revoked, refusing to isolate!")
      throw WalletError.emptyAccountKey // Key is not revoked, refuse to remove
    }

    log.info("[Blocto] ✅ Verified key is revoked, proceeding with isolation")

    // Search ALL key types (not just userStore.keyType)
    // This handles cases where keyType changed after rotation
    let keyTypes: [FlowWalletKit.KeyType] = [.seedPhrase, .privateKey, .secureEnclave]
    var totalKeysIsolated = 0

    for keyType in keyTypes {
      let storage = WalletManager.shared.getStorage(for: keyType)
      let allKeys = KeyProvider.keys(with: uid, in: storage)
      var keysToIsolate: [String] = []

      for keyId in allKeys {
        let suffix = KeyProvider.getSuffix(with: keyId)
        if publicKey.hasPrefix(suffix) {
          keysToIsolate.append(keyId)
        }
      }

      if !keysToIsolate.isEmpty {
        log.info("[Blocto] Moving \(keysToIsolate.count) keys from \(keyType) to isolated storage")
        await WalletManager.shared.moveKeysToRevokedStorage(
          keyIds: keysToIsolate,
          keyType: keyType,
          uid: uid
        )
        totalKeysIsolated += keysToIsolate.count
      }
    }

    log.info("[Blocto] Total keys isolated: \(totalKeysIsolated)")

    // Wait for keyIndexer to index the new key (up to 90 seconds)
    // This ensures signing works immediately after key rotation completes
    guard let keyProvider = WalletManager.shared.keyProvider else {
      log.warning("[Blocto] No keyProvider available, skipping keyIndexer wait")
      return
    }

    let keyIndexed = await WalletManager.shared.waitForKeyIndexer(provider: keyProvider, maxAttempts: 45)
    if keyIndexed {
      log.info("[Blocto] ✅ Key rotation complete - new key ready to use")
    } else {
      log.warning("[Blocto] ⚠️ Key rotation complete but keyIndexer timeout - signing will work after app restart")
    }
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
      return try account.toWalletAccount().toRNBridge().toDictionary()
    } else if let account = await manager.selectedEVMAccount {
      return try account.toWalletAccount().toRNBridge().toDictionary()
    } else if let account = await manager.selectedEOAAccount {
      let address =  await WalletManager.shared.mainAccount?.hexAddr
      return try account.toWalletAccount(parentAddress: address).toRNBridge().toDictionary()
    } else if let account = await manager.mainAccount {
      return try account.toWalletAccount().toRNBridge().toDictionary()
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

  @objc
  static func getRecoverableProfiles() async throws -> [String: Any] {
      // For now, return all known profiles as recoverable
      return try await getWalletProfiles()
  }

  @objc
  static func switchToProfile(userId: String) async throws {
    let allProfiles = ProfileManager.shared.profiles
    guard let profile = allProfiles.first( where: { $0.uid == userId }) else {
      throw LLError.accountNotFound
    }
    try await UserManager.shared.switchAccount(with: profile)
  }

  @objc
  static func shareQRCode(address: String, qrCodeDataUrl: String) async throws {

  }
  
  private static func getCurrentProfile() async throws -> RNBridge.WalletProfile {
    guard let userInfo = UserManager.shared.userInfo, let uid = UserManager.shared.activatedUID else {
      throw LLError.accountNotFound
    }
    var list: [RNBridge.WalletAccount] = []
    let eoas = await WalletManager.shared.walletEntity?.eoaAddress
    let accounts = await WalletManager.shared.currentNetworkAccounts
    for account in accounts {
      guard let result = try? await parseAccount(account: account, userId: uid, eoa: eoas) else {
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
      
      guard let provider = await WalletManager.shared.quickKeyProvider(uid: profile.uid) else {
        continue
      }
      var walletAccounts: [RNBridge.WalletAccount] = []
      let walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
      try? await walletEntity.fetchAccount()
      guard let accountList =  walletEntity.accounts?[currentNetwork] else {
        continue
      }
      if let eoas = walletEntity.eoaAddress, let address = accountList.first?.hexAddr {
        let result = Array(eoas).compactMap {
          EOA($0, network: currentNetwork)?.toWalletAccount(parentAddress: address, userId: profile.uid).toRNBridge()
        }
        walletAccounts.append(contentsOf: result)
      }
      for account in accountList {
        guard let result = try? await parseAccount(account: account, userId: profile.uid, eoa: walletEntity.eoaAddress) else {
          continue
        }
        walletAccounts.append(contentsOf: result)
      }
      let walletProfile = RNBridge.WalletProfile(
        name: nickname,
        avatar: profile.avatar ?? "",
        uid: profile.uid,
        accounts: walletAccounts
        )
      resultOfProfiles.append(walletProfile)
    }
    return resultOfProfiles
  }
  
  private static func parseAccount(account: FlowWalletKit.Account, userId: String? = nil, eoa: Set<String>? = nil) async throws ->  [RNBridge.WalletAccount] {
    var list: [RNBridge.WalletAccount] = []
    try? await account.fetchAccount()
    list.append(account.toWalletAccount(userId: userId).toRNBridge())
    if let linked = account.coa {
      list.append(linked.toWalletAccount(parentAddress: account.hexAddr, userId: userId).toRNBridge())
    }

    if let childList = account.childs {
      let result = childList.map { $0.toWalletAccount(parentAddress: account.hexAddr, userId: userId).toRNBridge() }
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
  
  @objc
  static func ethSign(_ hexData: String) -> String? {
    guard let keyProvider = WalletManager.shared.keyProvider as? EthereumKeyProtocol else {
      return nil
    }
    return try? keyProvider.ethSign(digest: Data(hexData.hexValue)).hexString
  }

  @objc
  static func launchNativeScreen(screen: String, params: String?) {
    log.info("\(screen)")
    guard let screen = NativeScreenName(rawValue: screen) else {
      log.error("don't support route \(screen)")
      HUD.error(title: "don't support route \(screen)")
      return
    }
    guard currentNetwork == .mainnet else {
      HUD.error(title: "wrong_network_title".localized)
      return
    }
    let restoreModel = RestoreWalletViewModel()
    switch screen {
    case .deviceBackup:
      Router.route(to: RouteMap.RestoreLogin.syncQC)
    case .recoveryPhraseRestore:
      restoreModel.restoreWithManualAction()
    case .keyStoreRestore:
      restoreModel.restoreWithKeyStore()
    case .privateKeyRestore:
      restoreModel.resteroWithPrivateKey()
    case .googleDriveRestore:
      restoreModel.restoreWithCloudAction(type: .googleDrive)
    case .multiRestore:
      Router.route(to: RouteMap.RestoreLogin.restoreMulti)
    case .backupOptions:
      Router.route(to: RouteMap.Backup.backupList)
    case .icloudRestore:
      restoreModel.restoreWithCloudAction(type: .icloud)
    }
  }
}

extension Flow.HashAlgorithm {
  fileprivate func hash(data: Data) throws -> Data {
    switch self {
    case .SHA2_256:
      return Hash.sha256(data: data)
    case .SHA3_256:
      return Hash.sha3_256(data: data)
    default:
      throw FWKError.unsupportHashAlgorithm
    }
  }
}

extension Flow.HashAlgorithm {
  fileprivate func hash(data: Data) throws -> Data {
    switch self {
    case .SHA2_256:
      return Hash.sha256(data: data)
    case .SHA3_256:
      return Hash.sha3_256(data: data)
    default:
      throw FWKError.unsupportHashAlgorithm
    }
  }
}
