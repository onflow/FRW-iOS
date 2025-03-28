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
import UIKit
import WalletCore
import Web3Core
import web3swift

// MARK: - Define

extension WalletManager {
    static let flowPath = "m/44'/539'/0'/0/0"
    static let mnemonicStrength: Int32 = 160
    static let defaultGas: UInt64 = 30_000_000

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

        if UserManager.shared.activatedUID != nil {
            restoreMnemonicForCurrentUser()
            loadCacheData()
        }

        UserManager.shared.$activatedUID
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { _ in
                self.reloadWallet()
                self.clearFlowAccount()
                self.reloadWalletInfo()
            }.store(in: &cancellableSet)
    }

    // MARK: Internal

    static let shared = WalletManager()

    @Published
    var supportedCoins: [TokenModel]?
    @Published
    var activatedCoins: [TokenModel] = []

    @Published
    var childAccount: ChildAccount? = nil
    @Published
    var evmAccount: EVMAccountManager.Account? = nil
    @Published
    var accountInfo: Flow.AccountInfo?

    var accessibleManager: ChildAccountManager.AccessibleManager = .init()

    var flowAccountKey: Flow.AccountKey?
    // TODO: remove after update Flow Wallet SDK
    var phraseAccountkey: Flow.AccountKey?

    var mainKeychain =
        Keychain(service: (Bundle.main.bundleIdentifier ?? defaultBundleID) + ".local")
            .label("Lilico app backup")
            .synchronizable(false)
            .accessibility(.whenUnlocked)

    var walletAccount: WalletAccount = .init()
    @Published
    var balanceProvider = BalanceProvider()

    var walletEntity: FlowWalletKit.Wallet?
    var accountKey: UserManager.Accountkey?
    var keyProvider: (any KeyProtocol)?
    // rename to currentAccount

//    @Published var account: FlowWalletKit.Account? = nil

    var customTokenManager: CustomTokenManager = .init()

    @Published
    var walletInfo: UserWalletResponse? {
        didSet {
            // TODO: remove after update new Flow Wallet SDK
            updateFlowAccount()
        }
    }

    var currentAccount: WalletAccount.User {
        WalletManager.shared.walletAccount
            .readInfo(at: getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? "")
    }

    var defaultSigners: [FlowSigner] {
        if RemoteConfigManager.shared.freeGasEnabled {
            return [WalletManager.shared, RemoteConfigManager.shared]
        }
        return [WalletManager.shared]
    }

    var flowToken: TokenModel? {
        WalletManager.shared.activatedCoins.first(where: { $0.isFlowCoin })
    }

    func bindChildAccountManager() {
        ChildAccountManager.shared.$selectedChildAccount
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink(receiveValue: { newChildAccount in
                log.info("change account did changed")
                self.childAccount = newChildAccount

                if self.childAccountInited {
                    Task {
                        try? await self.fetchWalletDatas()
                    }
                }

                self.childAccountInited = true
                NotificationCenter.default.post(name: .childAccountChanged)
            }).store(in: &cancellableSet)

        EVMAccountManager.shared.$selectedAccount
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { account in
                log.info("[EVM] account did changed to \(account?.address ?? "")")
                self.evmAccount = account
                if account != nil {
                    Task {
                        try? await self.fetchWalletDatas()
                    }
                }

                // TODO: #six send changed?
            }
            .store(in: &cancellableSet)
    }

    // MARK: Private

    private var childAccountInited: Bool = false

    private var hdWallet: HDWallet?
    private var walletInfoRetryTimer: Timer?
    private var cancellableSet = Set<AnyCancellable>()

    private var retryCheckCount = 1

    private var isShow: Bool = false

    private func loadCacheData() {
        guard let uid = UserManager.shared.activatedUID else { return }
        let cacheWalletInfo = MultiAccountStorage.shared.getWalletInfo(uid)

        Task {
            let cacheSupportedCoins = try? await PageCache.cache.get(
                forKey: CacheKeys.supportedCoins.rawValue,
                type: [TokenModel].self
            )
            let cacheActivatedCoins = try? await PageCache.cache.get(
                forKey: CacheKeys.activatedCoins.rawValue,
                type: [TokenModel].self
            )

            await MainActor.run {
                self.walletInfo = cacheWalletInfo

                if let cacheSupportedCoins = cacheSupportedCoins,
                   let cacheActivatedCoins = cacheActivatedCoins
                {
                    self.supportedCoins = cacheSupportedCoins
                    self.activatedCoins = cacheActivatedCoins
                }
            }
        }
    }
}

// MARK: Key Protocol

extension WalletManager {
    private func reloadWallet() {
        if let uid = UserManager.shared.activatedUID {
            keyProvider = keyProvider(with: uid)
            if let provider = keyProvider, let user = userStore(with: uid) {
                updateKeyProvider(provider: provider, storeUser: user)
            } else {
                log.error("[Wallet] not found provider or user at \(uid)")
            }
        }
    }

    func updateKeyProvider(provider: any KeyProtocol, storeUser: UserManager.StoreUser) {
        keyProvider = provider
        accountKey = storeUser.account
        log.debug("[user] \(String(describing: accountKey))")
        guard accountKey == nil else {
            return
        }
        Task {
            if let address = storeUser.address {
                do {
                    let accountKey = try await findKey(address: address, with: storeUser.publicKey)
                    self.accountKey = accountKey?.toStoreKey()
                    LocalUserDefaults.shared.updateUser(
                        by: storeUser.userId,
                        publicKey: storeUser.publicKey,
                        account: self.accountKey
                    )
                } catch {
                    log
                        .error(
                            "[Wallet] not find account key by \(address) with \(storeUser.publicKey)"
                        )
                }
            }
            if self.accountKey == nil {
                do {
                    let result = try await findKey(provider: provider, with: storeUser.publicKey)
                    self.accountKey = result.1?.toStoreKey()
                    let address = result.0?.address.description
                    LocalUserDefaults.shared.updateUser(
                        by: storeUser.userId,
                        publicKey: storeUser.publicKey,
                        address: address,
                        account: accountKey
                    )
                } catch {
                    log
                        .error(
                            "[Wallet] not find account key by \(provider.keyType) with \(storeUser.publicKey)"
                        )
                }
            }
        }
    }

    func accountKey(with uid: String) async -> UserManager.Accountkey? {
        guard let user = userStore(with: uid) else {
            return nil
        }
        var accountKey = user.account
        log.debug("[user] \(String(describing: self.accountKey))")
        if accountKey == nil, let address = user.address {
            accountKey = try? await findKey(address: address, with: user.publicKey)?.toStoreKey()
        }
        if accountKey == nil, let keyProvider = keyProvider(with: uid) {
            accountKey = try? await findKey(provider: keyProvider, with: user.publicKey).1?
                .toStoreKey()
        }

        return accountKey
    }

    private func findKey(address: String, with publicKey: String) async throws -> Flow.AccountKey? {
        let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)
        let sortedAccount = account.keys.filter { $0.weight >= 1000 }
        let accountKey = sortedAccount.filter { $0.publicKey.description == publicKey }.first
        log.debug("[user] \(String(describing: accountKey))")
        return accountKey
    }

    private func findKey(
        provider: any KeyProtocol,
        with publicKey: String
    ) async throws -> (Flow.Account?, Flow.AccountKey?) {
        let chainId = LocalUserDefaults.shared.flowNetwork.toFlowType()
        let walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: [chainId])
        _ = try? await walletEntity.fetchAllNetworkAccounts()
        let list = walletEntity.flowAccounts?[chainId]
        var flowAccount: Flow.Account?
        var accountKey: Flow.AccountKey?
        list?.forEach { account in
            for key in account.keys {
                if key.publicKey.description == publicKey {
                    flowAccount = account
                    accountKey = key
                    break
                }
            }
        }
        log.debug("[user] \(String(describing: accountKey))")
        return (flowAccount, accountKey)
    }

    func userStore(with uid: String) -> UserManager.StoreUser? {
        LocalUserDefaults.shared.userList.last { $0.userId == uid }
    }

    func keyProvider(with uid: String) -> (any KeyProtocol)? {
        guard let userStore = userStore(with: uid) else {
            return nil
        }
        log.debug("[user] \(userStore)")
        var provider: (any KeyProtocol)?
        switch userStore.keyType {
        case .secureEnclave:
            provider = try? SecureEnclaveKey.wallet(id: uid)
        case .seedPhrase:
            provider = try? SeedPhraseKey.wallet(id: uid)
        case .privateKey:
            provider = try? PrivateKey.wallet(id: uid)
        case .keyStore:
            provider = try? PrivateKey.wallet(id: uid)
        }
        return provider
    }
}

// MARK: - Child Account

extension WalletManager {
    var isSelectedChildAccount: Bool {
        childAccount != nil
    }

    var isSelectedEVMAccount: Bool {
        evmAccount != nil
    }

    var isSelectedFlowAccount: Bool {
        ChildAccountManager.shared.selectedChildAccount == nil && EVMAccountManager.shared
            .selectedAccount == nil
    }

    var selectedAccountIcon: String {
        if let childAccount = childAccount {
            return childAccount.icon
        }

        if let evmAccount = evmAccount {
            return evmAccount.showIcon
        }

        return UserManager.shared.userInfo?.avatar.convertedAvatarString() ?? ""
    }

    var selectedAccountNickName: String {
        if let childAccount = childAccount {
            return childAccount.aName
        }

        if let evmAccount = evmAccount {
            return evmAccount.showName
        }

        return UserManager.shared.userInfo?.nickname ?? "lilico".localized
    }

    var selectedAccountWalletName: String {
        if let childAccount = childAccount {
            return "\(childAccount.aName) Wallet"
        }

        if let evmAccount = evmAccount {
            return evmAccount.showName
        }

        if let walletInfo = walletInfo?.currentNetworkWalletModel {
            return walletInfo.getName ?? "wallet".localized
        }

        return "wallet".localized
    }

    var selectedAccountAddress: String {
        if let childAccount = childAccount {
            return childAccount.addr ?? ""
        }

        if let evmAccount = evmAccount {
            return evmAccount.showAddress
        }

        if let walletInfo = walletInfo?.currentNetworkWalletModel {
            return walletInfo.getAddress ?? "0x"
        }

        return "0x"
    }

    func changeNetwork(_ type: FlowNetworkType) {
        if LocalUserDefaults.shared.flowNetwork == type {
            if isSelectedChildAccount {
                ChildAccountManager.shared.select(nil)
            }
            if !isSelectedEVMAccount {
                return
            }
        }

        if isSelectedEVMAccount {
            EVMAccountManager.shared.select(nil)
        }

        LocalUserDefaults.shared.flowNetwork = type
        FlowNetwork.setup()
        clearFlowAccount()
        if getPrimaryWalletAddress() == nil {
            WalletManager.shared.reloadWalletInfo()
        } else {
            walletInfo = walletInfo
        }
        Task {
            do {
                try await findFlowAccount()
            } catch {
                log.error("[wallet] fetch flow account failed.")
            }
        }

        NotificationCenter.default.post(name: .networkChange)
    }
}

// MARK: - account type

extension WalletManager {
    func isCoa(_ address: String?) -> Bool {
        guard let address = address, !address.isEmpty else {
            return false
        }
        return !EVMAccountManager.shared.accounts
            .filter {
                $0.showAddress.lowercased().contains(address.lowercased())
            }.isEmpty
    }

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
    private func resetProperties() {
        hdWallet = nil
        walletInfo = nil
        supportedCoins = nil
        activatedCoins = []
    }

    func clearFlowAccount() {
        flowAccountKey = nil
    }

    @objc
    private func reset() {
        debugPrint("WalletManager: reset start")

        resetProperties()

        debugPrint("WalletManager: wallet info clear success")

        do {
            try removeCurrentMnemonicDataFromKeyChain()
            debugPrint("WalletManager: mnemonic remove success")
        } catch {
            debugPrint("WalletManager: remove mnemonic failed")
        }

        debugPrint("WalletManager: reset finished")
    }

    private func removeCurrentMnemonicDataFromKeyChain() throws {
        guard let uid = UserManager.shared.activatedUID else {
            return
        }

        try mainKeychain.remove(getMnemonicStoreKey(uid: uid))
    }
}

// MARK: - Getter

extension WalletManager {
    func getCurrentMnemonic() -> String? {
        guard let provider = keyProvider as? SeedPhraseKey else {
            return nil
        }
        return provider.hdWallet.mnemonic
    }

    func getCurrentPublicKey() -> String? {
        if let provider = keyProvider, let key = accountKey {
            let publicKey = provider.publicKey(signAlgo: key.signAlgo)
            return publicKey?.hexString
        }
        if let accountkey = flowAccountKey {
            return accountkey.publicKey.description
        }
        return hdWallet?.getPublicKey()
    }

    func getCurrentPrivateKey() -> String? {
        guard let signAlgo = accountKey?.signAlgo else {
            return nil
        }
        return keyProvider?.privateKey(signAlgo: signAlgo)?.hexValue
    }

    func getCurrentFlowAccountKey() -> Flow.AccountKey? {
        hdWallet?.flowAccountKey
    }

    func getPrimaryWalletAddress() -> String? {
        if let uid = UserManager.shared.activatedUID, let user = userStore(with: uid) {
            if user.address != nil {
                return user.address
            }
        }
        return walletInfo?.currentNetworkWalletModel?.getAddress
    }

    func getFlowNetworkTypeAddress(network: FlowNetworkType) -> String? {
        walletInfo?.getNetworkWalletModel(network: network)?.getAddress
    }

    /// get custom watch address first, then primary address, this method is only used for tab2.
    func getPrimaryWalletAddressOrCustomWatchAddress() -> String? {
        LocalUserDefaults.shared.customWatchAddress ?? getPrimaryWalletAddress()
    }

    /// watch address -> child account address -> primary address
    func getWatchAddressOrChildAccountAddressOrPrimaryAddress() -> String? {
        if let customAddress = LocalUserDefaults.shared.customWatchAddress, !customAddress.isEmpty {
            return customAddress
        }

        if let childAccount = childAccount {
            return childAccount.addr
        }

        if let evmAccount = evmAccount {
            return evmAccount.showAddress
        }

        if let walletInfo = walletInfo?.currentNetworkWalletModel {
            return walletInfo.getAddress
        }

        return nil
    }

    func isTokenActivated(model: TokenModel) -> Bool {
        for token in activatedCoins {
            if token.vaultIdentifier?.uppercased() == model.vaultIdentifier?.uppercased() {
                return true
            }
        }

        return false
    }

    func getToken(by vaultIdentifier: String?) -> TokenModel? {
        guard let identifier = vaultIdentifier else {
            return flowToken
        }
        for token in activatedCoins {
            if token.vaultIdentifier?.lowercased() == identifier.lowercased() {
                return token
            }
        }
        return nil
    }

    func getBalance(with token: TokenModel?) -> Decimal {
        guard let token else {
            return Decimal(0.0)
        }
        return token.showBalance ?? Decimal(0.0)
    }

    func currentContact() -> Contact {
        let address = getWatchAddressOrChildAccountAddressOrPrimaryAddress()
        var user: WalletAccount.User?
        if let addr = address {
            user = WalletManager.shared.walletAccount.readInfo(at: addr)
        }

        let contact = Contact(
            address: address,
            avatar: nil,
            contactName: nil,
            contactType: .user,
            domain: nil,
            id: UUID().hashValue,
            username: nil,
            user: user
        )
        return contact
    }
}

// MARK: - Server Wallet

extension WalletManager {
    /// Request server create wallet address, DO NOT call it multiple times.
    func asyncCreateWalletAddressFromServer() {
        Task {
            do {
                let _: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.User.userAddress)
                debugPrint("WalletManager -> asyncCreateWalletAddressFromServer success")
            } catch {
                debugPrint("WalletManager -> asyncCreateWalletAddressFromServer failed")
            }
        }
    }

    private func startWalletInfoRetryTimer() {
        debugPrint("WalletManager -> startWalletInfoRetryTimer")
        stopWalletInfoRetryTimer()
        let timer = Timer.scheduledTimer(
            timeInterval: WalletManager.walletFetchInterval,
            target: self,
            selector: #selector(onWalletInfoRetryTimer),
            userInfo: nil,
            repeats: false
        )
        walletInfoRetryTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopWalletInfoRetryTimer() {
        if let timer = walletInfoRetryTimer {
            timer.invalidate()
            walletInfoRetryTimer = nil
        }
    }

    @objc
    private func onWalletInfoRetryTimer() {
        debugPrint("WalletManager -> onWalletInfoRetryTimer")
        reloadWalletInfo()
    }

    func reloadWalletInfo() {
        log.debug("reloadWalletInfo")
        stopWalletInfoRetryTimer()
        guard let uid = UserManager.shared.activatedUID else { return }

        Task {
            do {
                let response: UserWalletResponse = try await Network.request(FRWAPI.User.userWallet)

                if UserManager.shared.activatedUID != uid { return }

                await MainActor.run {
                    self.walletInfo = response
                    try? MultiAccountStorage.shared.saveWalletInfo(response, uid: uid)
                    self.pollingWalletInfoIfNeeded()
                }
            } catch {
                if UserManager.shared.activatedUID != uid { return }
                log.error("reloadWalletInfo failed", context: error)

                await MainActor.run {
                    self.startWalletInfoRetryTimer()
                }
            }
        }
    }

    /// polling wallet info, if wallet address is not exists

    private func pollingWalletInfoIfNeeded() {
        debugPrint("WalletManager -> pollingWalletInfoIfNeeded")
        let isEmptyBlockChain = walletInfo?.currentNetworkWalletModel?.isEmptyBlockChain ?? true
        if isEmptyBlockChain {
            startWalletInfoRetryTimer()

            Task {
                do {
                    if retryCheckCount % 4 == 0 {
                        let _: Network.EmptyResponse = try await Network
                            .requestWithRawModel(FRWAPI.User.manualCheck)
                    }
                    retryCheckCount += 1
                } catch {
                    debugPrint(error)
                }
            }

        } else {
            // is valid data, save to page cache
            if let info = walletInfo {
                PageCache.cache.set(value: info, forKey: CacheKeys.walletInfo.rawValue)
            }
        }
    }
}

// MARK: - Mnemonic Create & Save

extension WalletManager {
    func createHDWallet(mnemonic: String? = nil, passphrase: String = "") -> HDWallet? {
        if let mnemonic = mnemonic {
            return HDWallet(mnemonic: mnemonic, passphrase: passphrase)
        }

        return HDWallet(strength: WalletManager.mnemonicStrength, passphrase: passphrase)
    }

    func storeAndActiveMnemonicToKeychain(_ mnemonic: String, uid: String) throws {
        guard var data = mnemonic.data(using: .utf8) else {
            throw WalletError.storeAndActiveMnemonicFailed
        }

        defer {
            data = Data()
        }

        var encodedData = try WalletManager.encryptionChaChaPoly(key: uid, data: data)
        defer {
            encodedData = Data()
        }

        try set(
            toMainKeychain: encodedData,
            forKey: getMnemonicStoreKey(uid: uid),
            comment: "Lilico user uid: \(uid)"
        )

        DispatchQueue.main.async {
            self.resetProperties()
            _ = self.activeMnemonic(mnemonic)
        }
    }
}

// MARK: - Mnemonic Restore

extension WalletManager {
    func getMnemonicFromKeychain(uid: String) -> String? {
        if var encryptedData = getEncryptedMnemonicData(uid: uid),
           var decryptedData = try? WalletManager.decryptionChaChaPoly(
               key: uid,
               data: encryptedData
           ),
           var mnemonic = String(data: decryptedData, encoding: .utf8)
        {
            defer {
                encryptedData = Data()
                decryptedData = Data()
                mnemonic = ""
            }

            return mnemonic
        }

        return nil
    }

    private func restoreMnemonicForCurrentUser() {
        if let uid = UserManager.shared.activatedUID {
            if !restoreMnemonicFromKeychain(uid: uid), UserManager.shared.userType == .phrase {
                HUD.error(title: "no_private_key".localized)
            }
            reloadWallet()
        }
    }

    private func restoreMnemonicFromKeychain(uid: String) -> Bool {
        do {
            if var encryptedData = getEncryptedMnemonicData(uid: uid) {
                debugPrint(
                    "WalletManager -> start restore mnemonic from keychain, uid = \(uid), encryptedData.count = \(encryptedData.count)"
                )

                var decryptedData = try WalletManager.decryptionChaChaPoly(
                    key: uid,
                    data: encryptedData
                )
                defer {
                    encryptedData = Data()
                    decryptedData = Data()
                }

                if var mnemonic = String(data: decryptedData, encoding: .utf8) {
                    defer {
                        mnemonic = ""
                    }

                    return activeMnemonic(mnemonic)
                }
            }
        } catch {
            debugPrint(
                "WalletManager -> restoreMnemonicFromKeyChain failed: uid = \(uid), error = \(error)"
            )
        }

        return false
    }

    private func activeMnemonic(_ mnemonic: String) -> Bool {
        guard let model = createHDWallet(mnemonic: mnemonic) else {
            return false
        }

        hdWallet = model
        return true
    }
}

// MARK: - Internal Getter

extension WalletManager {
    private func getMnemonicStoreKey(uid: String) -> String {
        "\(WalletManager.mnemonicStoreKeyPrefix).\(uid)"
    }

    private func getEncryptedMnemonicData(uid: String) -> Data? {
        getData(fromMainKeychain: getMnemonicStoreKey(uid: uid))
    }
}

// MARK: - Coins

extension WalletManager {
    func fetchWalletDatas() async throws {
        guard getPrimaryWalletAddress() != nil else {
            return
        }
        log.debug("fetchWalletDatas")
        // First fetch evm and link address of this address
        await EVMAccountManager.shared.refreshSync()
        await ChildAccountManager.shared.refreshAsync()

        try await fetchSupportedTokens()
        try await fetchActivatedTokens()

        try await fetchBalance()

        try await fetchAccessible()

        flowAccountKey = nil
        try await findFlowAccount()

        try? await fetchAccountInfo()
    }

    private func fetchSupportedTokens() async throws {
        guard let addr = getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
              let address = FWAddressDector.create(address: addr)
        else {
            return
        }
        let supportedToken = try await TokenBalanceHandler.shared.getSupportTokens(address: address)
        await MainActor.run {
            self.supportedCoins = supportedToken
        }
        PageCache.cache.set(value: supportedToken, forKey: CacheKeys.supportedCoins.rawValue)
    }

    /// fetch main or child activated token and balances
    private func fetchActivatedTokens() async throws {
        guard let supportedCoins = supportedCoins, !supportedCoins.isEmpty else {
            await MainActor.run {
                self.activatedCoins.removeAll()
            }
            return
        }
        guard let currrentAddr = getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
              let address = FWAddressDector.create(address: currrentAddr)
        else {
            await MainActor.run {
                self.activatedCoins.removeAll()
            }
            return
        }

        let availableTokens: [TokenModel] = try await TokenBalanceHandler.shared.getActivatedTokens(address: address)
        await MainActor.run {
            self.activatedCoins = availableTokens
        }
        PageCache.cache.set(value: availableTokens, forKey: CacheKeys.activatedCoins.rawValue)
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

    var minimumStorageBalance: Decimal {
        guard let accountInfo else { return Self.fixedMoveFee }
        return accountInfo.storageFlow + Self.fixedMoveFee
    }

    var isStorageInsufficient: Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        guard accountInfo.storageCapacity >= accountInfo.storageUsed else { return true }
        return accountInfo.storageCapacity - accountInfo.storageUsed < Self.mininumStorageThreshold
    }

    var isBalanceInsufficient: Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        return accountInfo.balance < Self.minFlowBalance
    }

    func isBalanceInsufficient(for amount: Decimal) -> Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        return accountInfo.availableBalance - amount < Self.averageTransactionFee
    }

    func isFlowInsufficient(for amount: Decimal) -> Bool {
        guard isSelectedFlowAccount else { return false }
        guard let accountInfo else { return false }
        return accountInfo.balance - amount < Self.minFlowBalance
    }

    func fetchBalance() async throws {
        balanceProvider.refreshBalance()
    }

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

    func fetchAccessible() async throws {
        try await accessibleManager.fetchFT()
    }
}

// MARK: - Helper

extension WalletManager {
    private func preloadActivatedIcons() {
        for token in activatedCoins {
            KingfisherManager.shared.retrieveImage(with: token.iconURL) { _ in
            }
        }
    }

    // MARK: -

    private func set(toMainKeychain value: String, forKey key: String) throws {
        try mainKeychain.set(value, key: key)
    }

    private func set(
        toMainKeychain value: Data,
        forKey key: String,
        comment: String? = nil
    ) throws {
        if let comment = comment {
            try mainKeychain.comment(comment).set(value, key: key)
        } else {
            try mainKeychain.set(value, key: key)
        }
    }

    private func getString(fromMainKeychain key: String) -> String? {
        try? mainKeychain.getString(key)
    }

    private func getData(fromMainKeychain key: String) -> Data? {
        try? mainKeychain.getData(key)
    }

    static func encryptionAES(
        key: String,
        iv: String = LocalEnvManager.shared.aesIV,
        data: Data
    ) throws -> Data {
        guard var keyData = key.data(using: .utf8), let ivData = iv.data(using: .utf8) else {
            throw LLError.aesKeyEncryptionFailed
        }
        if keyData.count > 16 {
            keyData = keyData.prefix(16)
        } else {
            keyData = keyData.paddingZeroRight(blockSize: 16)
        }

        guard let encrypted = AES.encryptCBC(key: keyData, data: data, iv: ivData, mode: .pkcs7)
        else {
            throw LLError.aesEncryptionFailed
        }
        return encrypted
    }

    static func decryptionAES(
        key: String,
        iv: String = LocalEnvManager.shared.aesIV,
        data: Data
    ) throws -> Data {
        guard var keyData = key.data(using: .utf8), let ivData = iv.data(using: .utf8) else {
            throw LLError.aesKeyEncryptionFailed
        }

        if keyData.count > 16 {
            keyData = keyData.prefix(16)
        } else {
            keyData = keyData.paddingZeroRight(blockSize: 16)
        }

        guard let decrypted = AES.decryptCBC(key: keyData, data: data, iv: ivData, mode: .pkcs7)
        else {
            throw LLError.aesEncryptionFailed
        }
        return decrypted
    }

    static func encryptionChaChaPoly(key: String, data: Data) throws -> Data {
        guard let cipher = ChaChaPolyCipher(key: key) else {
            throw EncryptionError.initFailed
        }
        return try cipher.encrypt(data: data)
    }

    static func decryptionChaChaPoly(key: String, data: Data) throws -> Data {
        guard let cipher = ChaChaPolyCipher(key: key) else {
            throw EncryptionError.initFailed
        }
        return try cipher.decrypt(combinedData: data)
    }
}

// MARK: FlowSigner

extension WalletManager: FlowSigner {
    public var address: Flow.Address {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            return Flow.Address(hex: "")
        }
        return Flow.Address(hex: address)
    }

    public var hashAlgo: Flow.HashAlgorithm {
        if let key = accountKey {
            return key.hashAlgo
        }
        if userSecretSign() {
            return flowAccountKey?.hashAlgo ?? .SHA2_256
        }
        return phraseAccountkey?.hashAlgo ?? .SHA2_256
    }

    public var signatureAlgo: Flow.SignatureAlgorithm {
        if let key = accountKey {
            return key.signAlgo
        }

        if userSecretSign() {
            return flowAccountKey?.signAlgo ?? .ECDSA_P256
        }
        return phraseAccountkey?.signAlgo ?? .ECDSA_SECP256k1
    }

    public var keyIndex: Int {
        if let key = accountKey {
            return key.index
        }
        if userSecretSign() {
            return flowAccountKey?.index ?? 0
        }
        return phraseAccountkey?.index ?? 0
    }

    public func sign(transaction _: Flow.Transaction, signableData: Data) async throws -> Data {
        let result = await SecurityManager.shared.SecurityVerify()
        if result == false {
            HUD.error(title: "verify_failed".localized)
            throw WalletError.securityVerifyFailed
        }

        if flowAccountKey == nil {
            try await findFlowAccount()
        }

        if let provider = keyProvider, let key = accountKey {
            let signature = try provider.sign(
                data: signableData,
                signAlgo: key.signAlgo,
                hashAlgo: key.hashAlgo
            )
            return signature
        }
        // TODO: Ready to delete below
        if userSecretSign() {
            if let userId = walletInfo?.id {
                let secureKey = try SecureEnclaveKey.wallet(id: userId)
                let signature = try secureKey.sign(data: signableData, hashAlgo: .SHA2_256)
                return signature
            }
        }

        guard let hdWallet = hdWallet else {
            throw LLError.emptyWallet
        }

        var privateKey = hdWallet.getKeyByCurve(
            curve: .secp256k1,
            derivationPath: WalletManager.flowPath
        )
        let hashedData = Hash.sha256(data: signableData)

        defer {
            privateKey = PrivateKey()
        }

        guard var signature = privateKey.sign(digest: hashedData, curve: .secp256k1) else {
            throw LLError.signFailed
        }

        signature.removeLast()

        return signature
    }

    public func sign(signableData: Data) async throws -> Data {
        let result = await SecurityManager.shared.SecurityVerify()
        if result == false {
            HUD.error(title: "verify_failed".localized)
            throw WalletError.securityVerifyFailed
        }
        if flowAccountKey == nil {
            try await findFlowAccount()
        }
        if let provider = keyProvider, let key = accountKey {
            let signature = try provider.sign(
                data: signableData,
                signAlgo: key.signAlgo,
                hashAlgo: key.hashAlgo
            )
            return signature
        }
        
        // Old logic
        if userSecretSign() {
            if let userId = walletInfo?.id {
                let secureKey = try SecureEnclaveKey.wallet(id: userId)
                let signature = try secureKey.sign(data: signableData, hashAlgo: .SHA2_256)
                return signature
            }
        }

        guard let hdWallet = hdWallet else {
            throw LLError.emptyWallet
        }

        var privateKey = hdWallet.getKeyByCurve(
            curve: .secp256k1,
            derivationPath: WalletManager.flowPath
        )
        let hashedData = Hash.sha256(data: signableData)

        defer {
            privateKey = PrivateKey()
        }

        guard var signature = privateKey.sign(digest: hashedData, curve: .secp256k1) else {
            throw LLError.signFailed
        }

        signature.removeLast()

        return signature
    }

    public func signSync(signableData: Data) -> Data? {
        if let provider = keyProvider, let key = accountKey {
            do {
                let signature = try provider.sign(
                    data: signableData,
                    signAlgo: key.signAlgo,
                    hashAlgo: key.hashAlgo
                )
                return signature
            } catch {
                return nil
            }
        }

        if userSecretSign() {
            do {
                if let userId = walletInfo?.id {
                    let secureKey = try SecureEnclaveKey.wallet(id: userId)
                    let signature = try secureKey.sign(data: signableData, hashAlgo: .SHA2_256)
                    return signature
                }
            } catch {
                return nil
            }
        }

        guard let hdWallet = hdWallet else {
            return nil
        }

        var privateKey = hdWallet.getKeyByCurve(
            curve: .secp256k1,
            derivationPath: WalletManager.flowPath
        )
        let hashedData = Hash.sha256(data: signableData)

        defer {
            privateKey = PrivateKey()
        }

        guard var signature = privateKey.sign(digest: hashedData, curve: .secp256k1) else {
            return nil
        }
        signature.removeLast()
        return signature
    }

    private func userSecretSign() -> Bool {
        if UserManager.shared.userType == .phrase {
            return false
        }
        return true
    }

    func findFlowAccount() async throws {
        guard let userId = walletInfo?.id else {
            return
        }
        let address = getPrimaryWalletAddress() ?? ""
        try await findFlowAccount(with: userId, at: address)
    }

    func findFlowAccount(with _: String, at address: String) async throws {
        guard let provider = keyProvider,
              let key = accountKey,
              let publicKey = try? provider.publicKey(signAlgo: key.signAlgo)?.hexValue
        else {
            return
        }

        let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)
        let sortedAccount = account.keys.sorted { $0.weight > $1.weight }
        flowAccountKey = sortedAccount.filter {
            $0.publicKey.description == publicKey
        }.first
        if flowAccountKey == nil {
            log.error("[Account] not find account")
        }
    }

    func updateFlowAccount() {
        guard let userId = walletInfo?.id,
              let hdWallet = hdWallet,
              let address = getPrimaryWalletAddress()
        else {
            return
        }
        Task {
            do {
                let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)
                let sortedAccount = account.keys.filter { $0.weight >= 1000 }
                phraseAccountkey = sortedAccount.filter {
                    $0.publicKey.description == hdWallet.getPublicKey()
                }.first
                if phraseAccountkey == nil {
                    log.error("[Account] import Phrase flow account key not find.")
                }
            } catch {
                log.error("[Account] import Phrase fetch fail.\(error.localizedDescription)")
            }
        }
    }

    @discardableResult
    func warningIfKeyIsInvalid(userId: String, markHide _: Bool = false) -> Bool {
        if let mnemonic = WalletManager.shared.getMnemonicFromKeychain(uid: userId),
           !mnemonic.isEmpty, mnemonic.split(separator: " ").count != 15
        {
            return false
        }
        // FIXME: private key migrate from device to device, it's destructive, this only for fix bugs, move to migrate
        return false
        /*
         do {
             let model = try WallectSecureEnclave.Store.fetchModel(by: userId)
             let list = try WallectSecureEnclave.Store.fetchAllModel(by: userId)
             if model == nil && list.count > 0 {
                 DispatchQueue.main.async {
                     if self.isShow {
                         return
                     }
                     self.isShow = true
                     let alertVC = BetterAlertController(title: "Something__is__wrong::message".localized, message: "profile_key_invalid".localized, preferredStyle: .alert)

                     let cancelAction = UIAlertAction(title: "action_cancel".localized, style: .cancel) { _ in
                         self.isShow = false
                     }

                     let restoreAction = UIAlertAction(title: "Restore Profile".localized, style: .default) { _ in
                         self.isShow = false
                         Router.route(to: RouteMap.RestoreLogin.restoreList)
                     }
                     alertVC.modalPresentationStyle = .overFullScreen
                     alertVC.addAction(cancelAction)
                     alertVC.addAction(restoreAction)

                     if markHide {
                         let hideAction = UIAlertAction(title: "Hide Profile".localized, style: .default) { _ in
                             self.isShow = false
                             do {
                                 try WallectSecureEnclave.Store.hideInvalidKey(by: userId)
                                 UserManager.shared.deleteLoginUID(userId)
                             }catch {
                                 log.error("[SecureEnclave] hide key for \(userId) failed. \(error.localizedDescription)")
                             }
                         }
                         alertVC.addAction(hideAction)
                     }
                     Router.topNavigationController()?.present(alertVC, animated: true)
                 }

                 return true
             }
         }catch {
             return true
         }

         return false
          */
    }
}

extension HDWallet {
    func getPublicKey() -> String {
        let p256PublicKey = getKeyByCurve(curve: .secp256k1, derivationPath: WalletManager.flowPath)
            .getPublicKeySecp256k1(compressed: false)
            .uncompressed
            .data
            .hexValue
            .dropPrefix("04")
        return p256PublicKey
    }

    func getPrivateKey() -> String {
        let privateKey = getKeyByCurve(curve: .secp256k1, derivationPath: WalletManager.flowPath)
        return privateKey.data.hexValue
    }

    func sign(_ text: String) -> String? {
        guard let textData = text.data(using: .utf8) else {
            return nil
        }

        let data = Flow.DomainTag.user.normalize + textData
        return sign(data)
    }

    func sign(_ data: Data) -> String? {
        var privateKey = getKeyByCurve(curve: .secp256k1, derivationPath: WalletManager.flowPath)

        defer {
            privateKey = PrivateKey()
        }

        let hashedData = Hash.sha256(data: data)
        guard var signature = privateKey.sign(digest: hashedData, curve: .secp256k1) else {
            return nil
        }

        signature.removeLast()
        return signature.hexValue
    }

    var flowAccountKey: Flow.AccountKey {
        let p256PublicKey = getPublicKey()
        let key = Flow.PublicKey(hex: String(p256PublicKey))
        return Flow.AccountKey(
            publicKey: key,
            signAlgo: .ECDSA_SECP256k1,
            hashAlgo: .SHA2_256,
            weight: 1000
        )
    }

    var flowAccountP256Key: Flow.AccountKey {
        let p256PublicKey = getKeyByCurve(curve: .nist256p1, derivationPath: WalletManager.flowPath)
            .getPublicKeyNist256p1()
            .uncompressed
            .data
            .hexValue
            .dropPrefix("04")
        let key = Flow.PublicKey(hex: String(p256PublicKey))
        return Flow.AccountKey(
            publicKey: key,
            signAlgo: .ECDSA_P256,
            hashAlgo: .SHA2_256,
            weight: 1000
        )
    }
}

extension Flow.AccountKey {
    func toCodableModel() -> AccountKey {
        AccountKey(
            hashAlgo: hashAlgo.index,
            publicKey: publicKey.hex,
            signAlgo: signAlgo.index,
            weight: weight
        )
    }
}

extension String {
    func dropPrefix(_ prefix: String) -> Self {
        if hasPrefix(prefix) {
            return String(dropFirst(prefix.count))
        }
        return self
    }
}

// MARK: Account
