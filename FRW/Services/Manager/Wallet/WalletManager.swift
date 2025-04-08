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
    
    var supportNetworks: Set<Flow.ChainID> = [
        .mainnet,
        .testnet
    ]

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
    var accountInfo: Flow.AccountInfo?

    var accessibleManager: ChildAccountManager.AccessibleManager = .init()

    var mainKeychain =
        Keychain(service: (Bundle.main.bundleIdentifier ?? defaultBundleID) + ".local")
            .label("Lilico app backup")
            .synchronizable(false)
            .accessibility(.whenUnlocked)

    var walletAccount = WalletAccount()
    
    @Published
    var walletEntity: FlowWalletKit.Wallet?
    
    @Published
    var currentMainAccount: FlowWalletKit.Account?
    
    var currentNetworkAccounts: [FlowWalletKit.Account] {
        walletEntity?.accounts?[currentNetwork.toFlowType()] ?? []
    }
    
    @Published
    private(set) var selectedAccount: FWAccount?
    
    var keyProvider: (any KeyProtocol)?

    var customTokenManager: CustomTokenManager = .init()
    
    var walletMetadata: WalletAccount.User {
        walletAccount.readInfo(at: selectedAccount?.address.hexAddr ?? "")
    }

    var defaultSigners: [FlowSigner] {
        if RemoteConfigManager.shared.freeGasEnabled {
            return [WalletManager.shared, RemoteConfigManager.shared]
        }
        return [WalletManager.shared]
    }

    // TODO: Remove this
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
            .filter{ $0.count >= self.supportNetworks.count }
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] accounts in
                print("Wallet Entity Accounts Updated \(accounts.count)")
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
            walletEntity = FlowWalletKit.Wallet(type: .key(provider), networks: supportNetworks)
            Task {
                do {
                    try await walletEntity?.fetchAccount()
                } catch {
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
        
        loadLinkedAccounts()
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
        selectedAccount?.type == .child
    }

    var isSelectedEVMAccount: Bool {
        selectedAccount?.type == .coa
    }

    var isSelectedFlowAccount: Bool {
        selectedAccount?.type == .main
    }

    var selectedAccountAddress: String? {
        return selectedAccount?.address.hexAddr
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
        
        if let firstAccount = currentNetworkAccounts.first {
            currentMainAccount = firstAccount
            selectedAccount = .main(firstAccount.address)
        }
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

    @objc
    private func reset() {
        debugPrint("WalletManager: reset start")
        
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
}

// MARK: - Coins

extension WalletManager {
    func fetchWalletDatas() async throws {
        
        print("AAAAAAAAA =====> fetchWalletDatas ")
        
        guard getPrimaryWalletAddress() != nil else {
            return
        }
        
        try await fetchSupportedTokens()
        try await fetchActivatedTokens()
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
//        PageCache.cache.set(value: supportedToken, forKey: CacheKeys.supportedCoins.rawValue)
    }

    /// fetch main or child activated token and balances
    private func fetchActivatedTokens() async throws {
        guard let supportedCoins = supportedCoins, !supportedCoins.isEmpty,
              let address = selectedAccount?.address else {
            self.activatedCoins.removeAll()
            return
        }

        let availableTokens: [TokenModel] = try await TokenBalanceHandler.shared.getActivatedTokens(address: address)
        await MainActor.run {
            self.activatedCoins = availableTokens
//            PageCache.cache.set(value: availableTokens, forKey: CacheKeys.activatedCoins.rawValue)
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
    
    private func preloadActivatedIcons() {
        for token in activatedCoins {
            KingfisherManager.shared.retrieveImage(with: token.iconURL, completionHandler: nil)
        }
    }
}
