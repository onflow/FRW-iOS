//
//  WalletManager.swift
//  Flow Wallet
//
//  Created by Hao Fu on 30/12/21.
//

import BigInt
import Combine
import Flow
import FlowWalletKit
import Foundation
import KeychainAccess
import Kingfisher
import SwiftUI
import UIKit
import WalletCore
import Web3Core
import web3swift

var currentNetwork: Flow.ChainID {
  WalletManager.shared.currentNetwork
}

// MARK: - Define

extension WalletManager {
  static let flowPath = "m/44'/539'/0'/0/0"
  static let mnemonicStrength: Int32 = 160
  static let defaultGas: UInt64 = 16_777_216

  static let minFlowBalance: Decimal = 0.001
  static let fixedMoveFee: Decimal = 0.001
  static var averageTransactionFee: Decimal {
    RemoteConfigManager.shared.freeGasEnabled ? 0 : 0.001
  }

  static let mininumStorageThreshold = 10000

  private static let defaultBundleID = "com.flowfoundation.wallet"
  private static let mnemonicStoreKeyPrefix = "lilico.mnemonic"
  private static let walletFetchInterval: TimeInterval = 5

  private enum CacheKeys: String {
    case walletInfo
    case supportedCoins
    case activatedCoins
    case coinBalancesV2
  }
}

// MARK: - WalletManager

class WalletManager: ObservableObject {
  // MARK: Lifecycle

  init() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(reset),
      name: .willResetWallet,
      object: nil
    )
    self.currentNetwork = LocalUserDefaults.shared.network
    flow.configure(chainID: currentNetwork)

    start()
  }

  // MARK: Internal

  static let shared = WalletManager()

  var supportNetworks: Set<Flow.ChainID> = [
    .mainnet,
    .testnet,
  ]

  @Published
  private(set) var activatedCoins: [TokenModel] = []

  @Published
  var accountInfo: Flow.AccountInfo?

  var accessibleManager: ChildAccountManager.AccessibleManager = .init()

  var mainKeychain =
    Keychain(service: (Bundle.main.bundleIdentifier ?? defaultBundleID) + ".local")
      .label("Lilico app backup")
      .synchronizable(false)
      .accessibility(.whenUnlocked)

  @Published
  var walletEntity: FlowWalletKit.Wallet?

  @Published
  var mainAccount: FlowWalletKit.Account?

  @Published
  private(set) var selectedAccount: FWAccount?

  @Published
  private(set) var currentNetwork: Flow.ChainID = .mainnet

  @ObservedObject
  var filterToken: TokenFilterModel = LocalUserDefaults.shared
    .filterTokens ?? TokenFilterModel()

  var keyProvider: (any KeyProtocol)?

  var customTokenManager: CustomTokenManager = .init()

  // Track currently initialized UID to avoid duplicate initialization
  private var currentInitializedUID: String?

  var currentNetworkAccounts: [FlowWalletKit.Account] {
    walletEntity?.accounts?[currentNetwork] ?? []
  }

  var walletMetadata: WalletUser {
    WalletUser.get(address: selectedAccount?.address.hexAddr ?? "")
  }

  var flowToken: TokenModel? {
    WalletManager.shared.activatedCoins.first(where: { $0.isFlowCoin })
  }

  var coa: COA? {
    mainAccount?.coa
  }
  
  var EOAs: [EOA]? = nil

  var childs: [FlowWalletKit.ChildAccount]? {
    mainAccount?.childs
  }

  func start() {
    UserManager.shared.$activatedUID
      .receive(on: DispatchQueue.main)
      .map { $0 }
      .removeDuplicates()  // Only trigger when UID actually changes
      .sink { uid in
        log.debug("[Login] activated uid changed to: \(uid ?? "nil")")
        self.clear()
        self.initWallet()
      }.store(in: &cancellableSet)

    $walletEntity
      .compactMap { $0 }
      .flatMap { entity in
        entity.securityDelegate = self
        return entity.$accounts.compactMap { $0 }
      }
      .receive(on: DispatchQueue.main)
//      .removeDuplicates()
      .sink { [weak self] accounts in
        print("Wallet Entity Accounts Updated \(accounts.count)")
        self?.loadRecentFlowAccount()
      }
      .store(in: &cancellableSet)

    CurrencyCache.cache.$currentCurrency
      .receive(on: DispatchQueue.main)
      .map { $0 }
      .sink { [weak self] _ in
        self?.reloadWhenCurrencyDidChanged()
      }
      .store(in: &cancellableSet)
  }

  // MARK: Private

  private var childAccountInited: Bool = false
  private var walletInfoRetryTimer: Timer?
  private var cancellableSet = Set<AnyCancellable>()
  private var accountsSubscription: AnyCancellable?
  private var retryCheckCount = 1
  private var isShow: Bool = false

  private func loadCacheData() {
//        guard let uid = UserManager.shared.activatedUID else { return }

    Task {
      let cacheActivatedCoins = try? await PageCache.cache.get(
        forKey: CacheKeys.activatedCoins.rawValue,
        type: [TokenModel].self
      )

      await MainActor.run {
        if let cacheActivatedCoins = cacheActivatedCoins {
          self.activatedCoins = cacheActivatedCoins
        }
      }
    }
  }
}

// MARK: Key Protocol

extension WalletManager {
  private func initWallet() {
    guard let uid = UserManager.shared.activatedUID else {
      // UID is nil - user logged out, all data cleared by observer
      log.info("[Wallet] UID is nil")
      return
    }

    // If UID is the same as currently initialized, skip re-initialization
    if currentInitializedUID == uid {
      log.info("[Wallet] UID unchanged (\(uid)), skipping re-initialization")
      return
    }

    log.info("[Wallet] UID changed to \(uid), initializing wallet")
    currentInitializedUID = uid

    Task {
      // Use findKeyProvider to get validated key with on-chain control
      // This ensures we always use the correct active key (not revoked)
      let result = await findKeyProvider(uid: uid)

      let provider: any KeyProtocol

      switch result {
      case .success(let data):
        // Found valid key with on-chain account
        log.info("[Wallet] ✅ Found valid key with mainnet account for uid: \(uid)")
        provider = data.provider
        // data.wallet already has mainnet accounts fetched

      case .providerWithoutAccount(let existingProvider):
        // Provider exists but no on-chain account yet (async creation in progress)
        // This is normal for newly created accounts - DO NOT show alert
        log.info("[Wallet] ⏳ Provider exists but account is still being created for uid: \(uid)")
        provider = existingProvider

      case .noValidProvider(let reason):
        // No valid provider found - show alert to user
        log.error("[Wallet] ❌ No valid provider found for uid: \(uid), reason: \(reason.alertReason)")
        await MainActor.run {
          showKeyInvalidAlert(uid: uid, reason: reason.alertReason)
        }
        return
      }

      await MainActor.run {
        updateKeyProvider(provider: provider)
        // Create wallet for all supported networks
        walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
        self.EOAs = walletEntity?.eoaAddress?.compactMap{ EOA($0,network: currentNetwork) }
      }

      // Fetch all network accounts (including testnet if needed)
      do {
        try await walletEntity?.fetchAllNetworkAccounts()
        await MainActor.run {
          loadRecentFlowAccount()
        }
      } catch {
        log.error("[Wallet] Failed to fetch all network accounts: \(error)")
        await MainActor.run {
          reloadWalletInfo()
        }
      }
    }
  }
  
  private func loadRecentFlowAccount() {
    guard let accounts = walletEntity?.accounts, !accounts.isEmpty else {
      reloadWalletInfo()
      return
    }
    guard let accounts = accounts[currentNetwork], let account = accounts.first else {
      // TODO: Handle newtork swicth, if no account
      mainAccount = nil
      HUD.error(WalletError.emptyMainAccount)
      return
    }

    // Default mainAccount is the first account
    mainAccount = account

    // If there is no selected, try to restore from saved address for current uid
    if selectedAccount == nil {
      if let uid = UserManager.shared.activatedUID,
          let savedValue = LocalUserDefaults.shared.getSelectedAddress(for: uid),
         let restoredAccount = FWAccount(savedValue) {
        // Find the parent account for child/coa types and verify validity
        if let parentAccount = findParentAccount(for: restoredAccount, in: accounts) {
          selectedAccount = restoredAccount
          mainAccount = parentAccount
        } else {
          // Saved address not found in current accounts, fallback to main
          selectedAccount = .main(account.address)
        }
      } else {
        selectedAccount = .main(account.address)
      }
      checkBloctoKeyAndPresentBackupTip(address: account.hexAddr)
    }
    updateUserAddress()
    loadLinkedAccounts()
    Task {
      do {
        try await fetchWalletDatas()
      } catch {
        log.error(error)
      }
    }
  }

  /// Find the parent account for the given account type
  /// Returns the account itself if it's a main account, or its parent for child/coa types
  private func findParentAccount(
    for account: FWAccount,
    in accounts: [FlowWalletKit.Account]
  ) -> FlowWalletKit.Account? {
    let targetAddress = account.hexAddr.lowercased()
    switch account.type {
    case .main:
      return accounts.first { $0.hexAddr.lowercased() == targetAddress }
    case .child:
      return accounts.first { flowAccount -> Bool in
        guard let childs = flowAccount.childs else { return false }
        return childs.contains { $0.address.hexAddr.lowercased() == targetAddress }
      }
    case .coa:
      return accounts.first { flowAccount -> Bool in
        guard let coaAddress = flowAccount.coa?.address.lowercased() else { return false }
        return coaAddress == targetAddress
      }
    case .eoa:
      // EOA addresses are managed separately, return first account as parent
      return accounts.first
    }
  }

  private func reloadWhenCurrencyDidChanged() {
    Task {
      do {
        try await fetchWalletDatas()
      } catch {
        log.error(error)
      }
    }
  }

  /// Temporary solution, solve the needs of multiple users
  private func updateUserAddress() {
    guard let address = selectedAccount?.address.hexAddr,
          let publicKey = getCurrentPublicKey(),
          let uid = UserManager.shared.activatedUID
    else {
      return
    }
    let hasUser = LocalUserDefaults.shared.userList
      .contains { $0.userId == uid && $0.publicKey == publicKey }
    if hasUser {
      LocalUserDefaults.shared.updateUser(by: uid, publicKey: publicKey, address: address)
      return
    }
    guard let keyType = keyProvider?.keyType else {
      log.warning("[Wallet] missing key type for user store at \(uid)")
      return
    }
    let accountKey = mainAccount?.fullWeightKey?.toStoreKey()
    let storeUser = UserManager.StoreUser(
      publicKey: publicKey,
      address: address,
      userId: uid,
      keyType: keyType,
      account: accountKey
    )
    LocalUserDefaults.shared.addUser(user: storeUser)
  }

  func loadLinkedAccounts() {
    guard let mainAccount else { return }
    Task {
      do {
        if mainAccount.hasLinkedAccounts {
          try await mainAccount.fetchAccount()
        }
      } catch {
        log.error(error)
        log.error(WalletError.fetchLinkedAccountsFailed)
      }
    }
  }

  func updateKeyProvider(provider: any KeyProtocol) {
    keyProvider = provider
  }

  /// Reinitialize wallet with current user's key provider (used after key rotation)
  /// Forces re-initialization even if UID hasn't changed
  func reinitializeWallet() {
    log.debug("[Wallet] Reinitializing wallet after key rotation")
    // Clear currentInitializedUID to force re-initialization
    // This is necessary when key changes but UID stays the same (key rotation)
    currentInitializedUID = nil
    initWallet()
  }

  func userStore(with uid: String) -> UserManager.StoreUser? {
    LocalUserDefaults.shared.userList.last { $0.userId == uid }
  }

  func userStore(with uid: String, and publicKey: String) -> UserManager.StoreUser? {
    LocalUserDefaults.shared.userList.last { $0.userId == uid && $0.publicKey == publicKey }
  }

  /// Quick key provider lookup without on-chain validation
  /// Used only for non-critical operations like displaying account lists
  /// For wallet initialization, use findKeyProvider() which validates on-chain
  func quickKeyProvider(uid: String) -> (any KeyProtocol)? {
    // Try to load from any keychain storage
    if let provider = try? SecureEnclaveKey.wallet(id: uid) {
      return provider
    }
    if let provider = try? SeedPhraseKey.wallet(id: uid) {
      return provider
    }
    if let provider = try? PrivateKey.wallet(id: uid) {
      return provider
    }
    return nil
  }
  

  // Find the corresponding user based on the uid and public
  private func user(uidAndPublicKey: String) -> [UserManager.StoreUser] {
    let uid = KeyProvider.getId(with: uidAndPublicKey)
    let suffix = KeyProvider.getSuffix(with: uidAndPublicKey)
    let list = LocalUserDefaults.shared.userList
      .filter { $0.userId == uid && $0.publicKey.contains(suffix) }
    return list
  }
}

// MARK: - Child Account

extension WalletManager {
  func changeSelectedAccount(address: String, type: FWAccount.AccountType) {
    UIFeedbackGenerator.impactOccurred(.selectionChanged)
    guard let fwAddress = FWAddressDector.create(address: address) else {
      HUD.error(WalletError.invaildAddress)
      return
    }

    selectedAccount = .init(type: type, addr: fwAddress)

    // Store selected account
    UserDefaults.standard.set(
      selectedAccount?.value,
      forKey: LocalUserDefaults.Keys.selectedAddress.rawValue
    )
    if type == .main {
      checkBloctoKeyAndPresentBackupTip(address: fwAddress.hexAddr)
    }

    // If it's main account, reload the linked account
    if type == .main,
       let account = walletEntity?.accounts?[currentNetwork]?.first(where: { account in
         account.hexAddr == address
       }) {
      mainAccount = account
      loadLinkedAccounts()
    }
  }
  
  func switchSelectedAccount(_ selectingAccount: WalletAccount) {
    UIFeedbackGenerator.impactOccurred(.selectionChanged)
    guard let fwAddress = FWAddressDector.create(address: selectingAccount.address) else {
      HUD.error(WalletError.invaildAddress)
      return
    }

    selectedAccount = .init(type: selectingAccount.FWAccountType, addr: fwAddress)
    // Store selected account per uid
    if let uid = UserManager.shared.activatedUID, let value = selectedAccount?.value {
      LocalUserDefaults.shared.setSelectedAddress(value, for: uid)
    }


    switch selectingAccount.FWAccountType {
      case .main:
        if let account = walletEntity?.accounts?[currentNetwork]?.first(where: { account in
          account.hexAddr == selectingAccount.address
        }) {
          mainAccount = account
          loadLinkedAccounts()
        }
      case .coa, .child:
        if let account = walletEntity?.accounts?[currentNetwork]?.first(where: { account in
          account.hexAddr == selectingAccount.parent?.address
        }) {
          mainAccount = account
          loadLinkedAccounts()
        }
      case .eoa:
        break

    }
  }

  func changeNetwork(_ network: Flow.ChainID) {
    if currentNetwork == network {
      return
    }

    currentNetwork = network
    LocalUserDefaults.shared.network = network
    flow.configure(chainID: network)

    NotificationCenter.default.post(name: .networkChange)

    if let firstAccount = currentNetworkAccounts.first {
      mainAccount = firstAccount
      selectedAccount = .main(firstAccount.address)
      loadLinkedAccounts()
    } else {
      // TODO: Handle no account
    }
  }
}

// MARK: - Account

extension WalletManager {
  /// Called by activatedUID observer when UID changes
  /// Clears all wallet state to prepare for re-initialization
  /// Note: Only called by observer, not manually from UserManager
  private func clear() {
    mainAccount = nil
    walletEntity = nil
    selectedAccount = nil
    activatedCoins = []
    currentInitializedUID = nil
    log.info("[Wallet] Cleared wallet state")
  }
}

// MARK: - Blocto Detector

extension WalletManager {
  private func checkBloctoKeyAndPresentBackupTip(address: String) {
    
    // Add feature flag check, if it's false, skip key rotation
    guard !address.isEmpty,
          let bloctoKeyRotation = RemoteConfigManager.shared.config?.features.bloctoKeyRotation,
          bloctoKeyRotation == true else {
      return
    }
    
    Task {
      do {
        let result = try await BloctoDetectorService.detectBloctoKey(address: address)
        guard result.isBlocto && result.needRevoke else { return }
        Router.route(to: RouteMap.ReactNative.backupTip)
      } catch {
        log.debug("[WalletManager] Blocto detection failed", context: error)
      }
    }
  }
}

// MARK: - account type

extension WalletManager {

  func isMain() -> Bool {
    guard let currentAddress = getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
          !currentAddress.isEmpty
    else {
      return false
    }
    guard let primaryAddress = getPrimaryWalletAddress() else {
      return false
    }
    return currentAddress.lowercased() == primaryAddress.lowercased()
  }
}

// MARK: - Reset

extension WalletManager {
  @objc
  private func reset() {
    debugPrint("WalletManager: reset start")
    do {
      guard let uid = UserManager.shared.activatedUID else {
        debugPrint("WalletManager: no uid")
        return
      }
      let keyId = "\(WalletManager.mnemonicStoreKeyPrefix).\(uid)"

      try mainKeychain.remove(keyId)

      debugPrint("WalletManager: mnemonic remove success")
    } catch {
      debugPrint("WalletManager: remove mnemonic failed")
    }

    debugPrint("WalletManager: reset finished")
  }
}

// MARK: - Server Wallet

extension WalletManager {
  /// Request server create wallet address, DO NOT call it multiple times.
  func asyncCreateWalletAddressFromServer() async -> String? {
      do {
        let result: UserAddressV2Response = try await Network
          .request(FRWAPI.User.userAddressV2)
        let txId = Flow.ID(hex: result.txId)
        _ = try await txId.onceExecuted()
        _ = try? await walletEntity?.fetchAccountsByCreationTxId(
          txId: txId,
          network: currentNetwork
        )
        log.debug("WalletManager -> asyncCreateWalletAddressFromServer success")
        return result.txId
      } catch {
        log.debug("WalletManager -> asyncCreateWalletAddressFromServer failed")
        log.error(error)
        return nil
      }
  }

  private func startWalletInfoRetryTimer() {
    stopWalletInfoRetryTimer()
    let timer = Timer(
      timeInterval: WalletManager.walletFetchInterval,
      target: self,
      selector: #selector(reloadWalletInfo),
      userInfo: nil,
      repeats: true
    )
    walletInfoRetryTimer = timer
    RunLoop.main.add(walletInfoRetryTimer!, forMode: .common)
  }

  private func stopWalletInfoRetryTimer() {
    if let timer = walletInfoRetryTimer {
      timer.invalidate()
      walletInfoRetryTimer = nil
    }
  }

  @objc
  func reloadWalletInfo() {
    Task {
      do {
        let result = try await walletEntity?.fetchAllNetworkAccounts()

        if currentNetworkAccounts.isEmpty {
          startWalletInfoRetryTimer()
          pollingWalletInfoIfNeeded()
        } else {
          stopWalletInfoRetryTimer()
          await MainActor.run {
            loadRecentFlowAccount()
          }
        }

      } catch {
        debugPrint("WalletManager -> Fetch error: \(error)")
        debugPrint(error)
        startWalletInfoRetryTimer()
      }
    }
  }

  /// polling wallet info, if wallet address is not exists

  private func pollingWalletInfoIfNeeded() {
    if currentNetworkAccounts.isEmpty {
      Task {
        do {
          if retryCheckCount % 4 == 0 {
            let _: Network.EmptyResponse = try await Network
              .requestWithRawModel(FRWAPI.User.manualCheck)
          }
          retryCheckCount += 1
        } catch {
          debugPrint("WalletManager -> Manual check error: \(error)")
        }
      }
    }
  }
}

// MARK: - Coins

extension WalletManager {
  func fetchWalletDatas() async throws {
    guard getPrimaryWalletAddress() != nil else {
      log.info("empty main address")
      throw WalletError.emptyMainAccount
    }

    try await fetchUserTokens()
    try await fetchAccessible()
    try? await fetchAccountInfo()
  }

  private func fetchUserTokens() async throws {
    guard let addr = selectedAccount?.address else {
      log.info("empty selected address")
      throw WalletError.emptyAddress
    }
    log.info("fetch user token \(addr)")
    let list = try await TokenBalanceHandler.shared.fetchUserTokens(address: addr)
    await MainActor.run {
      self.activatedCoins = list
    }
    preloadActivatedIcons()
  }

  func fetchAccountInfo() async throws {
    do {
      let accountInfo = try await FlowNetwork.checkAccountInfo()
      await MainActor.run {
        self.accountInfo = accountInfo
      }

      NotificationCenter.default.post(name: .accountDataDidUpdate, object: nil)
    } catch {
      log.error("[WALLET] fetch account info failed.\(error.localizedDescription)")
      throw error
    }
  }

  func fetchAccessible() async throws {
    try await accessibleManager.fetchFT()
  }

  private func preloadActivatedIcons() {
    // Create a snapshot to avoid concurrent modification issues
    let tokens = activatedCoins
    for token in tokens {
      // Safely access iconURL with error handling
      do {
        let iconURL = token.iconURL
        KingfisherManager.shared.retrieveImage(with: iconURL, completionHandler: nil)
      } catch {
        log.error("Failed to get iconURL for token: \(token.name), error: \(error)")
      }
    }
  }
}

// MARK: - Custom Token

extension WalletManager {
  func addCustomToken(token: CustomToken) {
    Task {
      await MainActor.run {
        let model = token.toToken()
        let index = self.activatedCoins.firstIndex { $0.contractId == model.contractId }
        if let index {
          self.activatedCoins[index] = model
        } else {
          self.activatedCoins.append(model)
        }
      }
    }
  }

  func deleteCustomToken(token: CustomToken) {
    DispatchQueue.main.async {
      self.activatedCoins.removeAll { model in
        model.getAddress() == token.address && model.name == token.name
      }
    }
  }
}
