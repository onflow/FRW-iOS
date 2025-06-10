//
//  LocalUserDefaults.swift
//  Flow Wallet
//
//  Created by Selina on 7/6/2022.
//

import Flow
import SwiftUI
import UIKit

// MARK: - LocalUserDefaults.Keys

extension LocalUserDefaults {
    enum Keys: String {
        case activatedUID
        case network
        case legacyUserInfo = "userInfo"
        case walletHidden
        case quoteMarket
        case coinSummary
        case recentSendByToken
        case legacyBackupType = "backupType"
        case securityType
        case lockOnExit
        case panelHolderFrame
        case transactionCount
        case customWatchAddress
        case tryToRestoreAccountFlag
        case currentCurrency
        case currentCurrencyRate
        case stakingGuideDisplayed
        case nftCount
        case onBoardingShown
        case multiAccountUpgradeFlag
        case loginUIDList
        case selectedChildAccount
        case switchProfileTipsFlag
        case freeGas
        case selectedEVMAccount
        case userAddressOfDeletedApp
        case walletAccountInfo
        case EVMAddress
        case showMoveAssetOnBrowser
        case removedNewsIds
        case shouldShowConfettiOnHome

        case whatIsBack
        case backupSheetNotAsk

        case userList
        case checkCoa

        case customToken
        case migrationFinished

        case userDefaultTheme
        case selectedAddress

        case filterToken

        case filterAccount
    }
}

// MARK: - LocalUserDefaults

class LocalUserDefaults: ObservableObject {
    // MARK: Lifecycle

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willReset),
            name: .willResetWallet,
            object: nil
        )
    }

    // MARK: Internal

    static let shared = LocalUserDefaults()

    @AppStorage(Keys.network.rawValue)
    var network: Flow.ChainID = .mainnet

    @AppStorage(Keys.shouldShowConfettiOnHome.rawValue)
    var shouldShowConfettiOnHome: Bool = false

    @AppStorage(Keys.activatedUID.rawValue)
    var activatedUID: String?

    @AppStorage(Keys.recentSendByToken.rawValue)
    var recentToken: String?

    @AppStorage(Keys.legacyBackupType.rawValue)
    var legacyBackupType: BackupManager
        .BackupType = .none

    @AppStorage(Keys.securityType.rawValue)
    var securityType: SecurityManager.SecurityType = .none
    @AppStorage(Keys.lockOnExit.rawValue)
    var lockOnExit: Bool = false

    @AppStorage(Keys.tryToRestoreAccountFlag.rawValue)
    var tryToRestoreAccountFlag: Bool = false

    @AppStorage(Keys.currentCurrency.rawValue)
    var currentCurrency: Currency = .USD
    @AppStorage(Keys.currentCurrencyRate.rawValue)
    var currentCurrencyRate: Double = 1

    @AppStorage(Keys.stakingGuideDisplayed.rawValue)
    var stakingGuideDisplayed: Bool = false

    @AppStorage(Keys.onBoardingShown.rawValue)
    var onBoardingShown: Bool = false
    @AppStorage(Keys.multiAccountUpgradeFlag.rawValue)
    var multiAccountUpgradeFlag: Bool = false

    @AppStorage(Keys.showMoveAssetOnBrowser.rawValue)
    var showMoveAssetOnBrowser: Bool = true

    @AppStorage(Keys.switchProfileTipsFlag.rawValue)
    var switchProfileTipsFlag: Bool = false

    var openLogWindow: Bool = false

    @AppStorage(Keys.whatIsBack.rawValue)
    var clickedWhatIsBack: Bool = false

    @AppStorage(Keys.backupSheetNotAsk.rawValue)
    var backupSheetNotAsk: Bool = false

    @AppStorage(Keys.migrationFinished.rawValue)
    var migrationFinished: Bool = false

    var legacyUserInfo: UserInfo? {
        set {
            if let value = newValue, let data = try? FRWAPI.jsonEncoder.encode(value) {
                UserDefaults.standard.set(data, forKey: Keys.legacyUserInfo.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.legacyUserInfo.rawValue)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.legacyUserInfo.rawValue),
               let info = try? FRWAPI.jsonDecoder.decode(
                   UserInfo.self,
                   from: data
               )
            {
                return info
            } else {
                return nil
            }
        }
    }

    @AppStorage(Keys.walletHidden.rawValue)
    var walletHidden: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .walletHiddenFlagUpdated, object: nil)
        }
    }

    @AppStorage(Keys.quoteMarket.rawValue)
    var market: QuoteMarket = .binance {
        didSet {
            NotificationCenter.default.post(name: .quoteMarketUpdated, object: nil)
        }
    }

    var coinSummarys: [CoinRateCache.CoinRateModel]? {
        set {
            if let value = newValue, let data = try? FRWAPI.jsonEncoder.encode(value) {
                UserDefaults.standard.set(data, forKey: Keys.coinSummary.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.coinSummary.rawValue)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.coinSummary.rawValue),
               let info = try? FRWAPI.jsonDecoder.decode(
                   [CoinRateCache.CoinRateModel].self,
                   from: data
               )
            {
                return info
            } else {
                return nil
            }
        }
    }

    var panelHolderFrame: CGRect? {
        set {
            if let value = newValue {
                let str = NSCoder.string(for: value)
                UserDefaults.standard.set(str, forKey: Keys.panelHolderFrame.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.panelHolderFrame.rawValue)
            }
        }
        get {
            if let str = UserDefaults.standard.string(forKey: Keys.panelHolderFrame.rawValue) {
                return NSCoder.cgRect(for: str)
            } else {
                return nil
            }
        }
    }

    @AppStorage(Keys.transactionCount.rawValue)
    var transactionCount: Int = 0 {
        didSet {
            NotificationCenter.default.post(name: .transactionCountDidChanged, object: nil)
        }
    }

    @AppStorage(Keys.customWatchAddress.rawValue)
    var customWatchAddress: String? {
        didSet {
            NotificationCenter.default.post(name: .watchAddressDidChanged, object: nil)
        }
    }

    @AppStorage(Keys.nftCount.rawValue)
    var nftCount: Int = 0 {
        didSet {
            NotificationCenter.default.post(name: .nftCountChanged, object: nil)
        }
    }

    var loginUIDList: [String] {
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.loginUIDList.rawValue)
        }
        get {
            UserDefaults.standard.array(forKey: Keys.loginUIDList.rawValue) as? [String] ?? []
        }
    }

    var userAddressOfDeletedApp: [String: String] {
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.userAddressOfDeletedApp.rawValue)
        }
        get {
            UserDefaults.standard
                .dictionary(forKey: Keys.userAddressOfDeletedApp.rawValue) as? [String: String] ??
                [:]
        }
    }

    var selectedChildAccount: ChildAccount? {
        set {
            if let value = newValue, let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: Keys.selectedChildAccount.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.selectedChildAccount.rawValue)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.selectedChildAccount.rawValue),
               let model = try? JSONDecoder().decode(
                   ChildAccount.self,
                   from: data
               )
            {
                return model
            } else {
                return nil
            }
        }
    }

    var selectedEVMAccount: EVMAccountManager.Account? {
        set {
            if let value = newValue, let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: Keys.selectedEVMAccount.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.selectedEVMAccount.rawValue)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.selectedEVMAccount.rawValue),
               let model = try? JSONDecoder().decode(
                   EVMAccountManager.Account.self,
                   from: data
               )
            {
                return model
            } else {
                return nil
            }
        }
    }

    var walletAccount: [String: [WalletUserProfile.User]]? {
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.walletAccountInfo.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.walletAccountInfo.rawValue)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.walletAccountInfo.rawValue),
               let model = try? JSONDecoder().decode(
                   [String: [WalletUserProfile.User]].self,
                   from: data
               )
            {
                return model
            } else {
                return nil
            }
        }
    }

    var EVMAddress: [String: [String]] {
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.EVMAddress.rawValue)
        }
        get {
            UserDefaults.standard
                .dictionary(forKey: Keys.EVMAddress.rawValue) as? [String: [String]] ?? [:]
        }
    }

    var removedNewsIds: [String] {
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.removedNewsIds.rawValue)
        }
        get {
            UserDefaults.standard.array(forKey: Keys.removedNewsIds.rawValue) as? [String] ?? []
        }
    }

    var userList: [UserManager.StoreUser] {
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.userList.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.userList.rawValue)
            }
        }
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.userList.rawValue) else {
                return []
            }
            do {
                let model = try JSONDecoder().decode([UserManager.StoreUser].self, from: data)
                return model
            } catch {
                return []
            }
        }
    }

    var checkCoa: [String] {
        set {
            UserDefaults.standard.setValue(newValue, forKey: Keys.checkCoa.rawValue)
        }
        get {
            UserDefaults.standard.array(forKey: Keys.checkCoa.rawValue) as? [String] ?? []
        }
    }

    var customToken: [CustomToken] {
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard
                    .set(data, forKey: Keys.customToken.rawValue)
            } else {
                UserDefaults.standard
                    .removeObject(forKey: Keys.customToken.rawValue)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.customToken.rawValue),
               let list = try? JSONDecoder().decode([CustomToken].self, from: data)
            {
                return list

            } else {
                return []
            }
        }
    }

    var filterTokens: TokenFilterModel? {
        set {
            if let value = newValue, let data = try? JSONEncoder().encode(value) {
                UserDefaults.standard.set(data, forKey: Keys.filterToken.rawValue)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.filterToken.rawValue)
            }
        }
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.filterToken.rawValue),
               let model = try? JSONDecoder().decode(TokenFilterModel.self, from: data)
            {
                return model
            } else {
                return nil
            }
        }
    }

    func addUser(user: UserManager.StoreUser) {
        var list = userList
        let index = list.lastIndex { $0.publicKey == user.publicKey && $0.keyType == user.keyType }
        if let result = index {
            list[result] = user
        } else {
            list.append(user)
        }
        userList = list
    }

    func updateUser(
        by userId: String,
        publicKey: String,
        address: String? = nil,
        account: UserManager.Accountkey? = nil
    ) {
        var users = userList
        let index = users.lastIndex(where: { $0.userId == userId && $0.publicKey == publicKey })
        guard let index = index else {
            return
        }
        let user = users[index]
        let newUser = user.copy(address: address, account: account)
        users[index] = newUser
        userList = users
    }

    func updateSEUser(by userId: String, address: String) {
        var users = userList
        let index = users.lastIndex(where: { $0.userId == userId && $0.keyType == .secureEnclave })
        guard let index = index else {
            return
        }
        let user = users[index]
        let newUser = user.copy(address: address, account: nil)
        users[index] = newUser
        userList = users
    }
}

extension LocalUserDefaults {
    @objc
    private func willReset() {
        recentToken = nil
        WalletManager.shared.changeNetwork(.mainnet)
    }
}
