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
import SwiftUI

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
        
        start()
    }

    // MARK: Internal
    static let shared = WalletManager()
    
    @Published
    var supportedCoins: [TokenModel]?
    
    @Published
    private(set) var activatedCoins: [TokenModel] = []

    @Published
    var childAccount: ChildAccount? = nil
    
    @Published
    var evmAccount: EVMAccountManager.Account? = nil
    
    @Published
    var accountInfo: Flow.AccountInfo?

    var accessibleManager: ChildAccountManager.AccessibleManager = .init()

    var mainKeychain =
        Keychain(service: (Bundle.main.bundleIdentifier ?? defaultBundleID) + ".local")
            .label("Lilico app backup")
            .synchronizable(false)
            .accessibility(.whenUnlocked)

    var walletAccount = WalletAccount()
    
    var balanceProvider = BalanceProvider()
    
    @Published
    var walletEntity: FlowWalletKit.Wallet?
    
    @Published
    var currentMainAccount: FlowWalletKit.Account?
    
    var currentNetworkAccounts: [FlowWalletKit.Account] {
        walletEntity?.accounts?[currentNetwork.toFlowType()] ?? []
    }
    
    @Published
//    @AppStorage(LocalUserDefaults.Keys.selectedAddress.rawValue)
    private(set) var selectedAccount: FWAccount?
    
    var keyProvider: (any KeyProtocol)?

    var customTokenManager: CustomTokenManager = .init()

//    @Published
//    var walletInfo: UserWalletResponse?
    
//    var selectedAccount: WalletAccount.User {
//        WalletManager.shared.walletAccount
//            .readInfo(at: getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? "")
//    }
    
    var walletMetadata: WalletAccount.User {
        walletAccount.readInfo(at: selectedAccount?.address.hexAddr ?? "")
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
    
    var coa: COA? {
        currentMainAccount?.coa
    }
    
    var childs: [FlowWalletKit.ChildAccount]? {
        currentMainAccount?.childs
    }
    
    func start() {
        UserManager.shared.$activatedUID
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { _ in
                self.reloadWallet()
                self.reloadWalletInfo()
            }.store(in: &cancellableSet)
        
        $walletEntity
            .compactMap { $0 }
            .flatMap { entity in
                entity.$accounts
                    .compactMap { $0 }
            }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] accounts in
                print("Wallet Entity Accounts Updated")
                self?.loadRecentFlowAccount()
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
            let cacheSupportedCoins = try? await PageCache.cache.get(
                forKey: CacheKeys.supportedCoins.rawValue,
                type: [TokenModel].self
            )
            let cacheActivatedCoins = try? await PageCache.cache.get(
                forKey: CacheKeys.activatedCoins.rawValue,
                type: [TokenModel].self
            )

            await MainActor.run {
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
            guard let provider = keyProvider, let user = userStore(with: uid) else {
                log.error("[Wallet] not found provider or user at \(uid)")
                return
            }
            updateKeyProvider(provider: provider, storeUser: user)
            walletEntity = FlowWalletKit.Wallet(type: .key(provider))
            Task {
                do {
                    try await walletEntity?.fetchAccount()
                } catch {
//                    print("AAA===>", error)
//                    HUD.error(WalletError.emptyAccountKey)
                    let _ = try await walletEntity?.fetchAllNetworkAccounts()
                }
            }
        }
    }
    
    private func loadRecentFlowAccount() {
        guard let accounts = walletEntity?.accounts else { return }
        guard let accounts = accounts[currentNetwork.toFlowType()], let account = accounts.first else {
            // TODO: Handle newtork swicth
            return
        }

        currentMainAccount = account
        
        // If there is no selected
        if selectedAccount == nil {
            selectedAccount = .main(account.address)
        }
        
        loadCacheData()
        loadLinkedAccounts()
        Task {
            do {
                try await fetchWalletDatas()
            } catch {
                log.error(WalletError.fetchLinkedAccountsFailed)
            }
        }
    }
    
    func loadLinkedAccounts() {
        Task {
            do {
                try await currentMainAccount?.loadLinkedAccounts()
            } catch {
                log.error(WalletError.fetchLinkedAccountsFailed)
            }
        }
    }

    func updateKeyProvider(provider: any KeyProtocol, storeUser: UserManager.StoreUser) {
        keyProvider = provider
//        accountKey = storeUser.account
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
        return childs?.first{ $0.address.hexAddr == selectedAccount?.address.hexAddr }?.name ?? "Child"
    }

    var selectedAccountAddress: String {
        return selectedAccount?.address.hexAddr ?? ""
    }
    
    func changeSelectedAccount(address: String, type: FWAccount.AccountType) {
        guard let address = FWAddressDector.create(address: address) else {
            HUD.error(WalletError.invaildAddress)
            return
        }
        
        selectedAccount = .init(type: type, addr: address)
        
        UserDefaults.standard.set(selectedAccount?.value, forKey: LocalUserDefaults.Keys.selectedAddress.rawValue)
        
        if type == .main {
            loadLinkedAccounts()
        }
    }

    func changeNetwork(_ type: FlowNetworkType) {
        if currentNetwork == type {
            return
        }
        LocalUserDefaults.shared.flowNetwork = type
        FlowNetwork.setup()
        NotificationCenter.default.post(name: .networkChange)
        
//        if LocalUserDefaults.shared.flowNetwork == type {
//            if isSelectedChildAccount {
//                ChildAccountManager.shared.select(nil)
//            }
//            if !isSelectedEVMAccount {
//                return
//            }
//        }
//
//        if isSelectedEVMAccount {
//            EVMAccountManager.shared.select(nil)
//        }
//        if getPrimaryWalletAddress() == nil {
//            WalletManager.shared.reloadWalletInfo()
//        }
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
//    private func resetProperties() {
//        walletInfo = nil
//    }

    @objc
    private func reset() {
        debugPrint("WalletManager: reset start")

//        resetProperties()

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
        return currentMainAccount?.fullWeightKey?.publicKey.hex
    }

    func getCurrentPrivateKey() -> String? {
        guard let signAlgo = currentMainAccount?.fullWeightKey?.signAlgo else {
            return nil
        }
        return keyProvider?.privateKey(signAlgo: signAlgo)?.hexValue
    }

    func getPrimaryWalletAddress() -> String? {
        return currentMainAccount?.address.hexAddr
    }
    
    func getAddress() -> String? {
        return selectedAccount?.address.hexAddr
    }

    /// get custom watch address first, then primary address, this method is only used for tab2.
    func getPrimaryWalletAddressOrCustomWatchAddress() -> String? {
        LocalUserDefaults.shared.customWatchAddress ?? getAddress()
    }

    /// watch address -> child account address -> primary address
    func getWatchAddressOrChildAccountAddressOrPrimaryAddress() -> String? {
        if let customAddress = LocalUserDefaults.shared.customWatchAddress, !customAddress.isEmpty {
            return customAddress
        }

        return getAddress()
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
        
        Task {
            do {
                let _ = try await walletEntity?.fetchAllNetworkAccounts()
//                try? MultiAccountStorage.shared.saveWalletInfo(response, uid: uid)
                self.pollingWalletInfoIfNeeded()
            } catch {
                self.startWalletInfoRetryTimer()
            }
        }
    }

    /// polling wallet info, if wallet address is not exists

    private func pollingWalletInfoIfNeeded() {
        debugPrint("WalletManager -> pollingWalletInfoIfNeeded")
        if currentNetworkAccounts.isEmpty {
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

        }
    }
}

// MARK: - Internal Getter

extension WalletManager {
    private func getMnemonicStoreKey(uid: String) -> String {
        "\(WalletManager.mnemonicStoreKeyPrefix).\(uid)"
    }

//    private func getEncryptedMnemonicData(uid: String) -> Data? {
//        getData(fromMainKeychain: getMnemonicStoreKey(uid: uid))
//    }
}

// MARK: - Coins

extension WalletManager {
    func fetchWalletDatas() async throws {
        guard getPrimaryWalletAddress() != nil else {
            return
        }
//        log.debug("fetchWalletDatas")
        // First fetch evm and link address of this address
//        await EVMAccountManager.shared.refreshSync()
//        await ChildAccountManager.shared.refreshAsync()

        try await fetchSupportedTokens()
        try await fetchActivatedTokens()
        try await fetchBalance()
        try await fetchAccessible()
        try? await fetchAccountInfo()
    }

    private func fetchSupportedTokens() async throws {
        guard let address = selectedAccount?.address else {
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
        guard let supportedCoins = supportedCoins, !supportedCoins.isEmpty,
              let address = selectedAccount?.address else {
            self.activatedCoins.removeAll()
            return
        }

        let availableTokens: [TokenModel] = try await TokenBalanceHandler.shared.getActivatedTokens(address: address)
        self.activatedCoins = availableTokens
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
            KingfisherManager.shared.retrieveImage(with: token.iconURL, completionHandler: nil)
        }
    }

    // MARK: -
//
//    private func set(toMainKeychain value: String, forKey key: String) throws {
//        try mainKeychain.set(value, key: key)
//    }
//
//    private func set(
//        toMainKeychain value: Data,
//        forKey key: String,
//        comment: String? = nil
//    ) throws {
//        if let comment = comment {
//            try mainKeychain.comment(comment).set(value, key: key)
//        } else {
//            try mainKeychain.set(value, key: key)
//        }
//    }
    
//    private func getString(fromMainKeychain key: String) -> String? {
//        try? mainKeychain.getString(key)
//    }
//
//    private func getData(fromMainKeychain key: String) -> Data? {
//        try? mainKeychain.getData(key)
//    }

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
    var keyIndex: Int {
        currentMainAccount?.keyIndex ?? 0
    }
    
    public var address: Flow.Address {
        currentMainAccount?.address ?? .init(hex: "")
    }

    public func sign(transaction _: Flow.Transaction, signableData: Data) async throws -> Data {
        return try await sign(signableData: signableData)
    }

    public func sign(signableData: Data) async throws -> Data {
        let result = await SecurityManager.shared.SecurityVerify()
        if result == false {
            HUD.error(title: "verify_failed".localized)
            throw WalletError.securityVerifyFailed
        }
        
        guard let provider = keyProvider else {
            throw WalletError.emptyKeyProvider
        }
        
        guard let key = currentMainAccount?.fullWeightKey else {
            throw WalletError.emptyAccountKey
        }
        
        let signature = try provider.sign(
            data: signableData,
            signAlgo: key.signAlgo,
            hashAlgo: key.hashAlgo
        )
        return signature
    }

    private func userSecretSign() -> Bool {
        UserManager.shared.userType != .phrase
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
