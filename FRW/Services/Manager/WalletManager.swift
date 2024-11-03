//
//  WalletManager.swift
//  Flow Wallet
//
//  Created by Hao Fu on 30/12/21.
//

import Combine
import Flow
import FlowWalletCore
import Foundation
import KeychainAccess
import Kingfisher
import WalletCore
import UIKit


// MARK: - Define

extension WalletManager {
    static let flowPath = "m/44'/539'/0'/0/0"
    static let mnemonicStrength: Int32 = 160
    static let defaultGas: UInt64 = 30_000_000
    static let moveFee = 0.001
    static let minDefaultBlance = 0.001
    private static let defaultBundleID = "com.flowfoundation.wallet"
    private static let mnemonicStoreKeyPrefix = "lilico.mnemonic"
    private static let walletFetchInterval: TimeInterval = 5

    private enum CacheKeys: String {
        case walletInfo
        case supportedCoins
        case activatedCoins
        case coinBalances
    }
}

class WalletManager: ObservableObject {
    static let shared = WalletManager()

    @Published var walletInfo: UserWalletResponse? {
        didSet {
            // TODO: remove after update new Flow Wallet SDK
            updateFlowAccount()
        }
    }

    @Published var supportedCoins: [TokenModel]?
    @Published var evmSupportedCoins: [TokenModel]?
    @Published var activatedCoins: [TokenModel] = []
    @Published var coinBalances: [String: Double] = [:]
    @Published var childAccount: ChildAccount? = nil
    @Published var evmAccount: EVMAccountManager.Account? = nil

    var accessibleManager: ChildAccountManager.AccessibleManager = .init()

    private var childAccountInited: Bool = false

    private var hdWallet: HDWallet?
    var flowAccountKey: Flow.AccountKey?
    // TODO: remove after update Flow Wallet SDK
    var phraseAccountkey: Flow.AccountKey?

    var mainKeychain = Keychain(service: (Bundle.main.bundleIdentifier ?? defaultBundleID) + ".local")
        .label("Lilico app backup")
        .synchronizable(false)
        .accessibility(.whenUnlocked)

    private var walletInfoRetryTimer: Timer?
    private var cancellableSet = Set<AnyCancellable>()

    var walletAccount: WalletAccount = .init()
    @Published var balanceProvider = BalanceProvider()

    var currentAccount: WalletAccount.User {
        WalletManager.shared.walletAccount.readInfo(at: getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? "")
    }

    var defaultSigners: [FlowSigner] {
        if RemoteConfigManager.shared.freeGasEnabled {
            return [WalletManager.shared, RemoteConfigManager.shared]
        }
        return [WalletManager.shared]
    }

    private var retryCheckCount = 1
    
    
    private var isShow: Bool = false

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(reset), name: .willResetWallet, object: nil)

        if UserManager.shared.activatedUID != nil {
            restoreMnemonicForCurrentUser()
            loadCacheData()
        }

        UserManager.shared.$activatedUID
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { _ in
                self.clearFlowAccount()
                self.reloadWalletInfo()
            }.store(in: &cancellableSet)
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

    private func loadCacheData() {
        guard let uid = UserManager.shared.activatedUID else { return }
        let cacheWalletInfo = MultiAccountStorage.shared.getWalletInfo(uid)

        Task {
            let cacheSupportedCoins = try? await PageCache.cache.get(forKey: CacheKeys.supportedCoins.rawValue, type: [TokenModel].self)
            let cacheActivatedCoins = try? await PageCache.cache.get(forKey: CacheKeys.activatedCoins.rawValue, type: [TokenModel].self)
            let cacheBalances = try? await PageCache.cache.get(forKey: CacheKeys.coinBalances.rawValue, type: [String: Double].self)

            DispatchQueue.main.async {
                self.walletInfo = cacheWalletInfo

                if let cacheSupportedCoins = cacheSupportedCoins, let cacheActivatedCoins = cacheActivatedCoins {
                    self.supportedCoins = cacheSupportedCoins
                    self.activatedCoins = cacheActivatedCoins
                }

                if let cacheBalances = cacheBalances {
                    self.coinBalances = cacheBalances
                }
            }
        }
    }
}

// MARK: - Child Account

extension WalletManager {
    var isSelectedChildAccount: Bool {
        return childAccount != nil
    }

    var isSelectedEVMAccount: Bool {
        return evmAccount != nil
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

    func changeNetwork(_ type: LocalUserDefaults.FlowNetworkType) {
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
        return EVMAccountManager.shared.accounts
            .filter {
                $0.showAddress.lowercased().contains(address.lowercased())
            }.count > 0
    }
    
    func isMain() -> Bool {
        
        guard let currentAddress = getWatchAddressOrChildAccountAddressOrPrimaryAddress(), !currentAddress.isEmpty else {
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
        coinBalances = [:]
    }

    func clearFlowAccount() {
        flowAccountKey = nil
    }

    @objc private func reset() {
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
        return hdWallet?.mnemonic
    }

    func getCurrentPublicKey() -> String? {
        if let accountkey = flowAccountKey {
            return accountkey.publicKey.description
        }
        return hdWallet?.getPublicKey()
    }

    func getCurrentPrivateKey() -> String? {
        return hdWallet?.getPrivateKey()
    }

    func getCurrentFlowAccountKey() -> Flow.AccountKey? {
        return hdWallet?.flowAccountKey
    }

    func getPrimaryWalletAddress() -> String? {
        return walletInfo?.currentNetworkWalletModel?.getAddress
    }

    func getFlowNetworkTypeAddress(network: LocalUserDefaults.FlowNetworkType) -> String? {
        return walletInfo?.getNetworkWalletModel(network: network)?.getAddress
    }

    /// get custom watch address first, then primary address, this method is only used for tab2.
    func getPrimaryWalletAddressOrCustomWatchAddress() -> String? {
        return LocalUserDefaults.shared.customWatchAddress ?? getPrimaryWalletAddress()
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

    var isPreviewEnabled: Bool {
        return walletInfo?.wallets?.first(where: { $0.chainId == LocalUserDefaults.FlowNetworkType.previewnet.rawValue })?.getAddress != nil
    }

    func isTokenActivated(symbol: String) -> Bool {
        for token in activatedCoins {
            if token.symbol == symbol {
                return true
            }
        }

        return false
    }

    func getToken(bySymbol symbol: String) -> TokenModel? {
        for token in activatedCoins {
            if token.symbol?.lowercased() == symbol.lowercased() {
                return token
            }
        }

        return nil
    }

    func getBalance(bySymbol symbol: String) -> Double {
        return coinBalances[symbol] ?? coinBalances[symbol.lowercased()] ?? coinBalances[symbol.uppercased()] ?? 0
    }

    func currentContact() -> Contact {
        let address = getWatchAddressOrChildAccountAddressOrPrimaryAddress()
        var user: WalletAccount.User?
        if let addr = address {
            user = WalletManager.shared.walletAccount.readInfo(at: addr)
        }

        let contact = Contact(address: address, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: nil, user: user)
        return contact
    }
}

// MARK: - Server Wallet

extension WalletManager {
    /// Request server create wallet address, DO NOT call it multiple times.
    func asyncCreateWalletAddressFromServer() {
        Task {
            do {
                let _: Network.EmptyResponse = try await Network.requestWithRawModel(FRWAPI.User.userAddress)
                debugPrint("WalletManager -> asyncCreateWalletAddressFromServer success")
            } catch {
                debugPrint("WalletManager -> asyncCreateWalletAddressFromServer failed")
            }
        }
    }

    private func startWalletInfoRetryTimer() {
        debugPrint("WalletManager -> startWalletInfoRetryTimer")
        stopWalletInfoRetryTimer()
        let timer = Timer.scheduledTimer(timeInterval: WalletManager.walletFetchInterval, target: self, selector: #selector(onWalletInfoRetryTimer), userInfo: nil, repeats: false)
        walletInfoRetryTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopWalletInfoRetryTimer() {
        if let timer = walletInfoRetryTimer {
            timer.invalidate()
            walletInfoRetryTimer = nil
        }
    }

    @objc private func onWalletInfoRetryTimer() {
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

                DispatchQueue.main.async {
                    self.walletInfo = response
                    try? MultiAccountStorage.shared.saveWalletInfo(response, uid: uid)
                    self.pollingWalletInfoIfNeeded()
                }
            } catch {
                if UserManager.shared.activatedUID != uid { return }
                log.error("reloadWalletInfo failed", context: error)

                DispatchQueue.main.async {
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
                        let _: Network.EmptyResponse = try await Network.requestWithRawModel(FRWAPI.User.manualCheck)
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

        try set(toMainKeychain: encodedData, forKey: getMnemonicStoreKey(uid: uid), comment: "Lilico user uid: \(uid)")

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
           var decryptedData = try? WalletManager.decryptionChaChaPoly(key: uid, data: encryptedData),
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
            if let hdWallet = hdWallet {
                // TODO:
            }
        }
    }

    private func restoreMnemonicFromKeychain(uid: String) -> Bool {
        do {
            if var encryptedData = getEncryptedMnemonicData(uid: uid) {
                debugPrint("WalletManager -> start restore mnemonic from keychain, uid = \(uid), encryptedData.count = \(encryptedData.count)")

                var decryptedData = try WalletManager.decryptionChaChaPoly(key: uid, data: encryptedData)
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
            debugPrint("WalletManager -> restoreMnemonicFromKeyChain failed: uid = \(uid), error = \(error)")
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
        return "\(WalletManager.mnemonicStoreKeyPrefix).\(uid)"
    }

    private func getEncryptedMnemonicData(uid: String) -> Data? {
        return getData(fromMainKeychain: getMnemonicStoreKey(uid: uid))
    }
}

// MARK: - Coins

extension WalletManager {
    func fetchWalletDatas() async throws {
        guard getPrimaryWalletAddress() != nil else {
            return
        }

        log.debug("fetchWalletDatas")

        try await fetchSupportedCoins()
        try await fetchActivatedCoins()

        try await fetchBalance()
        try await fetchAccessible()
        ChildAccountManager.shared.refresh()
        EVMAccountManager.shared.refresh()

        flowAccountKey = nil
        try await findFlowAccount()
    }

    private func fetchSupportedCoins() async throws {
        let tokenResponse: SingleTokenResponse = try await Network.requestWithRawModel(GithubEndpoint.ftTokenList)
        let coins: [TokenModel] = tokenResponse.conversion()
        let validCoins = coins.filter { $0.getAddress()?.isEmpty == false }
        DispatchQueue.main.sync {
            self.supportedCoins = validCoins
        }
        await fetchEVMCoins()
        PageCache.cache.set(value: validCoins, forKey: CacheKeys.supportedCoins.rawValue)
    }

    private func fetchActivatedCoins() async throws {
        guard let supportedCoins = supportedCoins, supportedCoins.count != 0 else {
            DispatchQueue.main.sync {
                self.activatedCoins.removeAll()
            }
            return
        }

        let address = selectedAccountAddress
        if address.isEmpty {
            DispatchQueue.main.sync {
                self.activatedCoins.removeAll()
            }
            return
        }

        var enabledList: [String: Bool] = [:]
        if let account = ChildAccountManager.shared.selectedChildAccount {
            enabledList = try await FlowNetwork.linkedAccountEnabledTokenList(address: account.showAddress)
        } else {
            enabledList = try await FlowNetwork.checkTokensEnable(address: Flow.Address(hex: address))
        }

        var list = [TokenModel]()
        for (_, value) in enabledList.enumerated() {
            if value.value {
                let model = supportedCoins.first { $0.contractId.lowercased() == value.key.lowercased() }
                if let model = model {
                    list.append(model)
                }
            }
        }

        DispatchQueue.main.sync {
            self.activatedCoins = list
        }
        preloadActivatedIcons()

        PageCache.cache.set(value: list, forKey: CacheKeys.activatedCoins.rawValue)
    }

    private func fetchEVMCoins() async {
        guard EVMAccountManager.shared.selectedAccount != nil else {
            return
        }
        do {
            let tokenResponse: SingleTokenResponse = try await Network.requestWithRawModel(GithubEndpoint.EVMTokenList)
            let coins: [TokenModel] = tokenResponse.conversion()
            DispatchQueue.main.async {
                self.evmSupportedCoins = coins
            }
        } catch {
            log.error("[EVM] fetch token list failed.\(error.localizedDescription)")
        }
    }

    func fetchBalance() async throws {
        let address = selectedAccountAddress
        if address.isEmpty {
            throw WalletError.fetchBalanceFailed
        }
        balanceProvider.refreshBalance()
        if isSelectedEVMAccount {
            try await fetchEVMBalance()
//            try await fetchEVMTokenAndBalance()
            return
        }

        let balanceList = try await FlowNetwork.fetchBalance(at: Flow.Address(hex: address))

        var newBalanceMap: [String: Double] = [:]

        for (_, value) in activatedCoins.enumerated() {
            guard let symbol = value.symbol else {
                continue
            }
            let model = balanceList.first { $0.key.lowercased() == value.contractId.lowercased() }
            if let model = model {
                newBalanceMap[symbol] = model.value
            }
        }

        DispatchQueue.main.sync {
            self.coinBalances = newBalanceMap
        }

        PageCache.cache.set(value: newBalanceMap, forKey: CacheKeys.coinBalances.rawValue)
    }

    private func fetchEVMBalance() async throws {
        log.info("[EVM] load balance")
        guard let evmAccount = EVMAccountManager.shared.selectedAccount else { return }
        try await EVMAccountManager.shared.refreshBalance(address: evmAccount.address)

        let tokenModel = supportedCoins?.first { $0.name.lowercased() == "flow" }
        let balance = EVMAccountManager.shared.balance
        guard var tokenModel = tokenModel, let symbol = tokenModel.symbol else { return }

        let list = try await EVMAccountManager.shared.fetchTokens()

        DispatchQueue.main.sync {
            log.info("[EVM] load balance success \(balance)")
            tokenModel.flowIdentifier = tokenModel.contractId
            self.activatedCoins = [tokenModel]
            self.coinBalances = [symbol: balance.doubleValue]

            list.forEach { item in
                if item.flowBalance > 0 {
                    let result = self.evmSupportedCoins?.first(where: { model in
                        model.getAddress()?.lowercased() == item.address.lowercased()
                    })
                    if let result = result {
                        self.activatedCoins.append(result)
                    } else {
                        self.activatedCoins.append(item.toTokenModel())
                    }
                    self.coinBalances[item.symbol] = item.flowBalance
                }
            }
        }
    }

//    private func fetchEVMTokenAndBalance() async throws {
//        log.info("[EVM] fetch evm other token and balance")
//        let list = try await EVMAccountManager.shared.fetchTokens()
//        DispatchQueue.main.sync {
//            log.info("[EVM] load evm token and balance")
//            list.forEach { item in
//                if item.flowBalance > 0 {
//                    let result = self.evmSupportedCoins?.first(where: { model in
//                        model.getAddress()?.lowercased() == item.address.lowercased()
//                    })
//                    if let result = result {
//                        self.activatedCoins.append(result)
//                    }else {
//                        self.activatedCoins.append(item.toTokenModel())
//                    }
//                    self.coinBalances[item.symbol] = item.flowBalance
//                }
//            }
//        }
//    }

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

    private func set(toMainKeychain value: Data, forKey key: String, comment: String? = nil) throws {
        if let comment = comment {
            try mainKeychain.comment(comment).set(value, key: key)
        } else {
            try mainKeychain.set(value, key: key)
        }
    }

    private func getString(fromMainKeychain key: String) -> String? {
        return try? mainKeychain.getString(key)
    }

    private func getData(fromMainKeychain key: String) -> Data? {
        return try? mainKeychain.getData(key)
    }

    static func encryptionAES(key: String, iv: String = LocalEnvManager.shared.aesIV, data: Data) throws -> Data {
        guard var keyData = key.data(using: .utf8), let ivData = iv.data(using: .utf8) else {
            throw LLError.aesKeyEncryptionFailed
        }
        if keyData.count > 16 {
            keyData = keyData.prefix(16)
        } else {
            keyData = keyData.paddingZeroRight(blockSize: 16)
        }

        guard let encrypted = AES.encryptCBC(key: keyData, data: data, iv: ivData, mode: .pkcs7) else {
            throw LLError.aesEncryptionFailed
        }
        return encrypted
    }

    static func decryptionAES(key: String, iv: String = LocalEnvManager.shared.aesIV, data: Data) throws -> Data {
        guard var keyData = key.data(using: .utf8), let ivData = iv.data(using: .utf8) else {
            throw LLError.aesKeyEncryptionFailed
        }

        if keyData.count > 16 {
            keyData = keyData.prefix(16)
        } else {
            keyData = keyData.paddingZeroRight(blockSize: 16)
        }

        guard let decrypted = AES.decryptCBC(key: keyData, data: data, iv: ivData, mode: .pkcs7) else {
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

extension WalletManager: FlowSigner {
    public var address: Flow.Address {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            return Flow.Address(hex: "")
        }
        return Flow.Address(hex: address)
    }

    public var hashAlgo: Flow.HashAlgorithm {
        // TODO: FIX ME, make it dynamic
        if userSecretSign() {
            return flowAccountKey?.hashAlgo ?? .SHA2_256
        }
        return phraseAccountkey?.hashAlgo ?? .SHA2_256
    }

    public var signatureAlgo: Flow.SignatureAlgorithm {
        // TODO: FIX ME, make it dynamic
        if userSecretSign() {
            return flowAccountKey?.signAlgo ?? .ECDSA_SECP256k1
        }
        return phraseAccountkey?.signAlgo ?? .ECDSA_SECP256k1
    }

    public var keyIndex: Int {
        // TODO: FIX ME, make it dynamic
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

        if userSecretSign() {
            if let userId = walletInfo?.id, let data = try WallectSecureEnclave.Store.fetchModel(by: userId)?.publicKey {
                let sec = try WallectSecureEnclave(privateKey: data)
                let signature = try sec.sign(data: signableData)
                return signature
            }
        }

        guard let hdWallet = hdWallet else {
            throw LLError.emptyWallet
        }

        var privateKey = hdWallet.getKeyByCurve(curve: .secp256k1, derivationPath: WalletManager.flowPath)
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
        if userSecretSign() {
            if let userId = walletInfo?.id, let data = try WallectSecureEnclave.Store.fetchModel(by: userId)?.publicKey {
                let sec = try WallectSecureEnclave(privateKey: data)
                let signature = try sec.sign(data: signableData)
                return signature
            }
        }

        guard let hdWallet = hdWallet else {
            throw LLError.emptyWallet
        }

        var privateKey = hdWallet.getKeyByCurve(curve: .secp256k1, derivationPath: WalletManager.flowPath)
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
        
        if userSecretSign() {
            do {
                if let userId = walletInfo?.id, let data = try WallectSecureEnclave.Store.fetchModel(by: userId)?.publicKey {
                    let sec = try WallectSecureEnclave(privateKey: data)
                    let signature = try sec.sign(data: signableData)
                    return signature
                }
            } catch {
                return nil
            }
        }

        guard let hdWallet = hdWallet else {
            return nil
        }

        var privateKey = hdWallet.getKeyByCurve(curve: .secp256k1, derivationPath: WalletManager.flowPath)
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

    func findFlowAccount(with userId: String, at address: String) async throws {
        guard let data = try WallectSecureEnclave.Store.fetchModel(by: userId)?.publicKey else {
            return
        }

        let sec = try WallectSecureEnclave(privateKey: data)
        guard let publicKey = sec.key.publickeyValue else {
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
    func warningIfKeyIsInvalid(userId: String, markHide: Bool = false) -> Bool {
        if let mnemonic = WalletManager.shared.getMnemonicFromKeychain(uid: userId), !mnemonic.isEmpty, mnemonic.split(separator: " ").count != 15 {
            return false
        }
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
        return Flow.AccountKey(publicKey: key,
                               signAlgo: .ECDSA_SECP256k1,
                               hashAlgo: .SHA2_256,
                               weight: 1000)
    }

    var flowAccountP256Key: Flow.AccountKey {
        let p256PublicKey = getKeyByCurve(curve: .nist256p1, derivationPath: WalletManager.flowPath)
            .getPublicKeyNist256p1()
            .uncompressed
            .data
            .hexValue
            .dropPrefix("04")
        let key = Flow.PublicKey(hex: String(p256PublicKey))
        return Flow.AccountKey(publicKey: key,
                               signAlgo: .ECDSA_P256,
                               hashAlgo: .SHA2_256,
                               weight: 1000)
    }
}

extension Flow.AccountKey {
    func toCodableModel() -> AccountKey {
        return AccountKey(hashAlgo: hashAlgo.index,
                          publicKey: publicKey.hex,
                          signAlgo: signAlgo.index,
                          weight: weight)
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
