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
        .testnet,
    ]

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reset),
            name: .willResetWallet,
            object: nil
        )
        currentNetwork = LocalUserDefaults.shared.network
        flow.configure(chainID: currentNetwork)
        start()
    }

    // MARK: Internal

    static let shared = WalletManager()

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
    var mainAccount: FlowWalletKit.Account?

    var currentNetworkAccounts: [FlowWalletKit.Account] {
        walletEntity?.accounts?[currentNetwork] ?? []
    }

    @Published
    private(set) var selectedAccount: FWAccount?

    @Published
    private(set) var currentNetwork: Flow.ChainID = .mainnet

    @ObservedObject var filterToken: TokenFilterModel = LocalUserDefaults.shared.filterTokens ?? TokenFilterModel()

    var keyProvider: (any KeyProtocol)?

    var customTokenManager: CustomTokenManager = .init()

    var walletMetadata: WalletAccount.User {
        walletAccount.readInfo(at: selectedAccount?.address.hexAddr ?? "")
    }

    var flowToken: TokenModel? {
        WalletManager.shared.activatedCoins.first(where: { $0.isFlowCoin })
    }

    var coa: COA? {
        mainAccount?.coa
    }

    var childs: [FlowWalletKit.ChildAccount]? {
        mainAccount?.childs
    }

    func start() {
        UserManager.shared.$activatedUID
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { _ in
                self.initWallet()
            }.store(in: &cancellableSet)

        $walletEntity
            .compactMap { $0 }
            .flatMap { entity in
                entity.securityDelegate = self
                return entity.$accounts.compactMap { $0 }
            }
//            .filter { $0.count >= self.supportNetworks.count }
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
        guard let accounts = walletEntity?.accounts, !accounts.isEmpty else {
            reloadWalletInfo()
            return
        }
        guard let accounts = accounts[currentNetwork], let account = accounts.first else {
            // TODO: Handle newtork swicth, if no account
            mainAccount = nil
            return
        }

        mainAccount = account

        // If there is no selected
        if selectedAccount == nil {
            selectedAccount = .main(account.address)
        }

        loadLinkedAccounts()
        Task {
            do {
                try await fetchWalletDatas()
            } catch {
                log.error(error)
            }
        }
    }

    func loadLinkedAccounts() {
        Task {
            do {
                try await mainAccount?.loadLinkedAccounts()
            } catch {
                log.error(error)
                log.error(WalletError.fetchLinkedAccountsFailed)
            }
        }
    }

    func updateKeyProvider(provider: any KeyProtocol, storeUser _: UserManager.StoreUser) {
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
    func changeSelectedAccount(address: String, type: FWAccount.AccountType) {
        UIFeedbackGenerator.impactOccurred(.selectionChanged)
        guard let fwAddress = FWAddressDector.create(address: address) else {
            HUD.error(WalletError.invaildAddress)
            return
        }

        selectedAccount = .init(type: type, addr: fwAddress)

        // Store selected account
        UserDefaults.standard.set(selectedAccount?.value, forKey: LocalUserDefaults.Keys.selectedAddress.rawValue)

        // If it's main account, reload the linked account
        if type == .main,
           let account = walletEntity?.accounts?[currentNetwork]?.first(where: { account in
               account.hexAddr == address
           })
        {
            mainAccount = account
            loadLinkedAccounts()
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
    /// called when switch profile
    func resetAfterSwitchProfile() {
        selectedAccount = nil
        activatedCoins = []
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
    func asyncCreateWalletAddressFromServer() {
        Task {
            do {
                let result: UserAddressV2Response = try await Network.request(FRWAPI.User.userAddressV2)
                let txId = Flow.ID(hex: result.txId)
                _ = try await txId.onceSealed()
                try? await walletEntity?.fetchAccountsByCreationTxId(txId: txId, network: currentNetwork)
                debugPrint("WalletManager -> asyncCreateWalletAddressFromServer success")
            } catch {
                print(error)
                debugPrint("WalletManager -> asyncCreateWalletAddressFromServer failed")
            }
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
        for token in activatedCoins {
            KingfisherManager.shared.retrieveImage(with: token.iconURL, completionHandler: nil)
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
