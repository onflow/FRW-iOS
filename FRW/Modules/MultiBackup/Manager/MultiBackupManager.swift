//
//  MultiBackupManager.swift
//  FRW
//
//  Created by cat on 2024/1/6.
//

import CryptoKit
import FirebaseAuth
import Flow
import FlowWalletKit
import Foundation
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForRESTCore
import GoogleSignIn
import GTMSessionFetcherCore
import WalletCore

// MARK: - MultiBackupTarget

protocol MultiBackupTarget {
    var uploadedItem: MultiBackupManager.StoreItem? { get set }
    var registeredDeviceInfo: SyncInfo.DeviceInfo? { get set }
    func loginCloud() async throws
    func upload(password: String) async throws
    func getCurrentDriveItems() async throws -> [MultiBackupManager.StoreItem]
    func removeItem(password: String) async throws
}

// MARK: - MultiBackupManager

class MultiBackupManager: ObservableObject {
    // MARK: Lifecycle

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onTransactionManagerChanged),
            name: .transactionManagerDidChanged,
            object: nil
        )
    }

    // MARK: Internal

    static let shared = MultiBackupManager()

    static let backupFileName = "outblock_multi_backup"

    var deviceInfo: SyncInfo.DeviceInfo?
    var backupType: BackupType = .undefined
    var backupList: [MultiBackupType] = []

    @Published
    var mnemonic: String?

    // MARK: Private

    private let gdTarget = MultiBackupGoogleDriveTarget()
    private let iCloudTarget = MultiBackupiCloudTarget()
    private let phraseTarget = MultiBackupPhraseTarget()
    private let passkeyTarget = MultiBackupPasskeyTarget()
    private let dropboxTarget = MultiBackupDropboxTarget()
    private let password = LocalEnvManager.shared.backupAESKey
}

// MARK: MultiBackupManager.StoreItem

extension MultiBackupManager {
    struct StoreItem: Codable {
        var address: String
        var userId: String
        var userName: String
        var userAvatar: String?
        var publicKey: String
        var data: String
        var keyIndex: Int
        var signAlgo: Int
        var hashAlgo: Int
        var weight: Int?
        var updatedTime: Double? = Date.now.timeIntervalSince1970
        let deviceInfo: DeviceInfoRequest?
        var code: String?
        var backupType: MultiBackupType? = .phrase

        func showDate() -> String {
            guard let updatedTime = updatedTime else { return "" }
            let date = Date(timeIntervalSince1970: updatedTime)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM dd,yyyy"
            let res = dateFormatter.string(from: date)
            return res
        }
    }
}

// MARK: - Public

// MARK: - Steps to create a backup

extension MultiBackupManager {
    func preLogin(with type: MultiBackupType) async throws {
        switch type {
        case .google:
            try await gdTarget.loginCloud()
        case .dropbox:
            try await dropboxTarget.loginCloud()
        default:
            log.info("")
        }
    }

    func registerKeyToChain(on type: MultiBackupType) async throws -> Bool {
        guard let username = UserManager.shared.userInfo?.username, !username.isEmpty else {
            throw BackupError.missingUserName
        }

        guard let uid = UserManager.shared.activatedUID, !uid.isEmpty else {
            throw BackupError.missingUid
        }

        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            throw BackupError.missingMnemonic
        }

        guard let hdWallet = HDWallet(strength: WalletManager.mnemonicStrength, passphrase: ""),
              let mnemonicData = hdWallet.mnemonic.data(using: .utf8)
        else {
            HUD.error(title: "empty_wallet_key".localized)
            throw BackupError.missingMnemonic
        }
        if type == .phrase {
            mnemonic = hdWallet.mnemonic
        }

        guard let pinCode = SecurityManager.shared.currentPinCode.toPassword() else {
            throw BackupError.hexStringToDataFailed
        }
        
        guard let publicKey = hdWallet.getPublicKey(signAlgo: .ECDSA_P256)?.description else {
            throw BackupError.invaildPublicKey
        }

        let dataHexString = try encryptMnemonic(
            mnemonicData,
            password: type.needPin ? pinCode : password
        )
        
        let result = try await addKeyToFlow(key: publicKey)
        if !result {
            return false
        }
        let keyIndex = try await fetchKeyIndex(publicKey: publicKey)

        // fetch ip info
        if IPManager.shared.info == nil {
            await IPManager.shared.fetch()
        }

        let flowPublicKey = Flow.PublicKey(hex: publicKey)
        let flowKey = Flow.AccountKey(
            publicKey: flowPublicKey,
            signAlgo: .ECDSA_P256,
            hashAlgo: .SHA2_256,
            weight: 500
        )
        let backupName = type.showName()
        let deviceInfo = SyncInfo.DeviceInfo(
            accountKey: flowKey.toCodableModel(),
            deviceInfo: IPManager.shared.toParams(),
            backupInfo: BackupInfoModel(
                createTime: nil,
                name: backupName,
                type: type.toBackupType().rawValue
            )
        )

        let item = MultiBackupManager.StoreItem(
            address: address,
            userId: uid,
            userName: username,
            publicKey: publicKey,
            data: dataHexString,
            keyIndex: keyIndex,
            signAlgo: Flow.SignatureAlgorithm.ECDSA_P256.index,
            hashAlgo: Flow.HashAlgorithm.SHA2_256.index,
            weight: 500,
            deviceInfo: IPManager.shared.toParams()
        )
        updateTarget(on: type, item: item, deviceInfo: deviceInfo)
        return true
    }

    func backupKey(on type: MultiBackupType) async throws {
        switch type {
        case .google:
            backupType = .google
            try await gdTarget.upload(password: password)
        case .passkey:
            backupType = .passkey
            log.warning("not surport")
        case .icloud:
            backupType = .iCloud
            try await iCloudTarget.upload(password: password)
        case .phrase:
            backupType = .manual
            try await phraseTarget.upload(password: password)
        case .dropbox:
            backupType = .dropbox
            try await dropboxTarget.upload(password: password)
        }
    }

    func syncKeyToServer(on type: MultiBackupType) async throws {
        guard let model = getTarget(with: type).registeredDeviceInfo else {
            return
        }
        do {
            let response: Network.EmptyResponse = try await Network
                .requestWithRawModel(FRWAPI.User.syncDevice(model))
        } catch {
            log.error("[sync account] error \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Private,

extension MultiBackupManager {
    func getTarget(with type: MultiBackupType) -> MultiBackupTarget {
        switch type {
        case .google:
            return gdTarget
        case .passkey:
            return passkeyTarget
        case .icloud:
            return iCloudTarget
        case .phrase:
            return phraseTarget
        case .dropbox:
            return dropboxTarget
        }
    }

    private func updateTarget(
        on type: MultiBackupType,
        item: MultiBackupManager.StoreItem,
        deviceInfo: SyncInfo.DeviceInfo
    ) {
        switch type {
        case .google:
            gdTarget.uploadedItem = item
            gdTarget.registeredDeviceInfo = deviceInfo
        case .passkey:
            passkeyTarget.uploadedItem = item
            passkeyTarget.registeredDeviceInfo = deviceInfo
        case .icloud:
            iCloudTarget.uploadedItem = item
            iCloudTarget.registeredDeviceInfo = deviceInfo
        case .phrase:
            phraseTarget.uploadedItem = item
            phraseTarget.registeredDeviceInfo = deviceInfo
        case .dropbox:
            dropboxTarget.uploadedItem = item
            dropboxTarget.registeredDeviceInfo = deviceInfo
        }
    }
}

extension MultiBackupManager {
    
    private func updateItemType(from type: MultiBackupType, list: [MultiBackupManager.StoreItem]) -> [MultiBackupManager.StoreItem] {
        let result = list.map { item in
            var model = item
            model.backupType = type
            return model
        }
        return result
    }
    
    func getAllCloudDriveItem(from type: MultiBackupType) async throws -> [MultiBackupManager.StoreItem] {
        var list = try await getCloudDriveItems(from: type)
        if type == .dropbox {
            if let readList = try? await dropboxTarget.getReadDriveItems() {
                let updatedReadList = updateItemType(from: type, list: readList)
                list.append(contentsOf: updatedReadList)
            }
        }
        return list
    }
    
    func getCloudDriveItems(from type: MultiBackupType) async throws
        -> [MultiBackupManager.StoreItem] {
        switch type {
        case .google:
            try await login(from: type)
            var list = try await gdTarget.getCurrentDriveItems()
            list = updateItemType(from: type, list: list)
            return list
        case .passkey:
            return []
        case .icloud:
            var list = try await iCloudTarget.getCurrentDriveItems()
            list = updateItemType(from: type, list: list)
            return list
        case .phrase:
            return []
        case .dropbox:
            try await login(from: type)
            var list = try await dropboxTarget.getCurrentDriveItems()
            list = updateItemType(from: type, list: list)
            return list
        }
    }

    func login(from type: MultiBackupType) async throws {
        switch type {
        case .google:
            try await gdTarget.loginCloud()
        case .passkey:
            log.info("not finished")
        case .icloud:
            try await iCloudTarget.loginCloud()
        case .phrase:
            log.info("not finished")
        case .dropbox:
            log.info("[Multi] dropbox ")
            try await dropboxTarget.loginCloud()
        }
    }

    func removeItem(with type: MultiBackupType) async throws {
        let password = LocalEnvManager.shared.backupAESKey
        switch type {
        case .google:
            try await login(from: type)
            try await gdTarget.removeItem(password: password)
        case .passkey:
            log.info("not surport")
        case .icloud:
            try await iCloudTarget.removeItem(password: password)
        case .phrase:
            log.info("wait")
        case .dropbox:
            try await login(from: type)
            try await dropboxTarget.removeItem(password: password)
        }
    }
}

// MARK: - Helper

extension MultiBackupManager {
    /// append current user mnemonic to list
    func addNewMnemonic(
        on type: MultiBackupType,
        list: [MultiBackupManager.StoreItem],
        password _: String
    ) async throws -> [MultiBackupManager.StoreItem] {
        guard let uid = UserManager.shared.activatedUID, !uid.isEmpty else {
            throw BackupError.missingUid
        }
        guard let item = getTarget(with: type).uploadedItem else {
            throw BackupError.missingMnemonic
        }
        var newList = list
        if let i = list.firstIndex(where: { $0.userId == uid }) {
            newList.remove(at: i)
        }

        newList.append(item)
        return newList
    }

    func removeCurrent(
        _ list: [MultiBackupManager.StoreItem],
        password _: String
    ) async throws -> [MultiBackupManager.StoreItem] {
        guard let username = UserManager.shared.userInfo?.username, !username.isEmpty else {
            throw BackupError.missingUserName
        }

        guard let uid = UserManager.shared.activatedUID, !uid.isEmpty else {
            throw BackupError.missingUid
        }
        let res = list.filter { item in
            item.userId != uid && item.userName != username
        }
        return res
    }

    func iv() -> String {
        let key = LocalEnvManager.shared.backupAESKey
        let oldIV = LocalEnvManager.shared.aesIV
        guard let result = key.toPassword() else {
            return oldIV
        }
        return result
    }

    /// encrypt list to hex string
    func encryptList(_ list: [MultiBackupManager.StoreItem]) throws -> String {
        let jsonData = try JSONEncoder().encode(list)
        let iv = iv()
        let encrypedData = try WalletManager.encryptionAES(
            key: LocalEnvManager.shared.backupAESKey,
            iv: iv,
            data: jsonData
        )
        return encrypedData.hexString
    }

    /// decrypt hex string to list
    func decryptHexString(_ hexString: String) throws -> [MultiBackupManager.StoreItem] {
        guard let data = Data(hexString: hexString) else {
            throw BackupError.hexStringToDataFailed
        }

        return try decryptData(data)
    }

    private func decryptData(_ data: Data) throws -> [MultiBackupManager.StoreItem] {
        let iv = iv()
        let jsonData = try WalletManager.decryptionAES(
            key: LocalEnvManager.shared.backupAESKey,
            iv: iv,
            data: data
        )
        let list = try JSONDecoder().decode([MultiBackupManager.StoreItem].self, from: jsonData)
        return list
    }

    /// encrypt mnemonic data to hex string
    func encryptMnemonic(_ mnemonicData: Data, password: String) throws -> String {
        guard let iv = password.toPassword() else {
            throw BackupError.decryptMnemonicFailed
        }
        let dataHexString = try WalletManager.encryptionAES(
            key: password,
            iv: iv,
            data: mnemonicData
        ).hexString
        return dataHexString
    }

    /// decrypt hex string to mnemonic string
    func decryptMnemonic(_ hexString: String, password: String) throws -> String {
        guard let encryptData = Data(hexString: hexString) else {
            throw BackupError.hexStringToDataFailed
        }
        guard let iv = password.toPassword() else {
            throw BackupError.decryptMnemonicFailed
        }
        let decryptedData = try WalletManager.decryptionAES(
            key: password,
            iv: iv,
            data: encryptData
        )
        guard let mm = String(data: decryptedData, encoding: .utf8), !mm.isEmpty else {
            throw BackupError.decryptMnemonicFailed
        }

        return mm
    }
}

extension MultiBackupManager {
    @objc
    private func onTransactionManagerChanged() {
        if TransactionManager.shared.holders.isEmpty {
            return
        }
    }

    private func addKeyToFlow(key: String) async throws -> Bool {
        let address = WalletManager.shared.address
        let accountKey = Flow.AccountKey(
            publicKey: Flow.PublicKey(hex: key),
            signAlgo: .ECDSA_P256,
            hashAlgo: .SHA2_256,
            weight: 500
        )
        let flowId = try await FlowNetwork.addKeyToAccount(
            address: address,
            accountKey: accountKey,
            signers: WalletManager.shared.defaultSigners
        )
        guard let data = try? JSONEncoder().encode(key) else {
            return false
        }
        let holder = TransactionManager.TransactionHolder(id: flowId, type: .addToken, data: data)
        TransactionManager.shared.newTransaction(holder: holder)
        let result = try await flowId.onceSealed()
        if result.isFailed {
            return false
        }
        return true
    }

    func fetchKeyIndex(publicKey: String) async throws -> Int {
        let address = WalletManager.shared.getPrimaryWalletAddress() ?? ""
        let accounts = try await FlowNetwork.getAccountAtLatestBlock(address: address)
        let model = accounts.keys.first { $0.publicKey.description == publicKey }
        guard let accountModel = model else {
            return 0
        }
        return accountModel.index
    }
}

extension MultiBackupManager {
    func addKeyToAccount(with list: [MultiBackupManager.StoreItem]) async throws {
        guard list.count > 1 else {
            return
        }

        var firstItem = list[0]
        var secondItem = list[1]
        let addressDes = list[0].address

        let account = try await FlowNetwork.getAccountAtLatestBlock(address: addressDes)
        var sequenNum: Int64 = 0
        for accountKey in account.keys {
            let publicKey = accountKey.publicKey.description
            if publicKey == firstItem.publicKey {
                sequenNum = accountKey.sequenceNumber
                firstItem.keyIndex = accountKey.index
            }
            if publicKey == secondItem.publicKey {
                secondItem.keyIndex = accountKey.index
                if secondItem.address.isEmpty {
                    secondItem.address = firstItem.address
                }
            }
        }

        let firstSigner = MultiBackupManager.Signer(provider: firstItem)
        let secondSigner = MultiBackupManager.Signer(provider: secondItem)

        let address = Flow.Address(hex: addressDes)

        let secureKey = try SecureEnclaveKey.create()
        let key = try secureKey.flowAccountKey()

        do {
            HUD.loading()
            let tx = try await FlowNetwork.addKeyWithMulti(
                address: address,
                keyIndex: firstItem.keyIndex,
                sequenceNum: sequenNum,
                accountKey: key,
                signers: [firstSigner, secondSigner, RemoteConfigManager.shared]
            )
            let result = try await tx.onceSealed()
            if result.isComplete {
                let userId = firstSigner.provider.userId

                let firstSignature = firstSigner.sign(userId) ?? ""
                let firstKeySignature = AccountKeySignature(
                    hashAlgo: firstSigner.hashAlgo.index,
                    publicKey: firstSigner.provider.publicKey,
                    signAlgo: firstSigner.signatureAlgo.index,
                    signMessage: userId,
                    signature: firstSignature,
                    weight: firstSigner.weight
                )

                let secondSignature = secondSigner.sign(userId) ?? ""

                let secondKeySignature = AccountKeySignature(
                    hashAlgo: secondSigner.hashAlgo.index,
                    publicKey: secondSigner.provider.publicKey,
                    signAlgo: secondSigner.signatureAlgo.index,
                    signMessage: userId,
                    signature: secondSignature,
                    weight: secondSigner.weight
                )
                let request = SignedRequest(
                    accountKey: AccountKey(
                        hashAlgo: key.hashAlgo.index,
                        publicKey: key.publicKey.description,
                        signAlgo: key.signAlgo.index,
                        weight: key.weight
                    ),
                    signatures: [firstKeySignature, secondKeySignature]
                )
                let response: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.User.addSigned(request))
                if response.httpCode != 200 {
                    log.error("[Multi-backup] sync failed")
                } else {
                    try secureKey.store(id: firstItem.userId)
                    let storeUser = UserManager.StoreUser(
                        publicKey: key.publicKey.description,
                        address: firstItem.address,
                        userId: firstItem.userId,
                        keyType: .secureEnclave,
                        account: nil
                    )
                    LocalUserDefaults.shared.addUser(user: storeUser)
                    try await UserManager.shared.restoreLogin(with: firstItem.userId)
                    Router.popToRoot()
                }
            } else {
                HUD.error(title: "Incorrect signature information")
            }
            HUD.dismissLoading()

            print(tx)
        } catch {
            HUD.dismissLoading()
            print(error)
        }
    }
}

// MARK: MultiBackupManager.Signer

extension MultiBackupManager {
    class Signer: FlowSigner {
        // MARK: Lifecycle

        init(provider: MultiBackupManager.StoreItem) {
            self.provider = provider
        }

        // MARK: Public

        public var address: Flow.Address {
            Flow.Address(hex: provider.address)
        }

        public var hashAlgo: Flow.HashAlgorithm {
            .SHA2_256
        }

        public var signatureAlgo: Flow.SignatureAlgorithm {
            if hdWallet?.mnemonic.words.count == 12 {
                return .ECDSA_SECP256k1
            }
            return .ECDSA_P256
        }

        public var keyIndex: Int {
            provider.keyIndex
        }

        public var weight: Int {
            if hdWallet?.mnemonic.words.count == 12 {
                return 1000
            }
            return provider.weight ?? 500
        }

        public func sign(signableData: Data, transaction: Flow.Transaction? ) async throws -> Data {
            _ = try await createHDWallet()

            guard let hdWallet = hdWallet else {
                throw BackupError.missingMnemonic
            }
            let curve: WalletCore.Curve = hdWallet.mnemonic.words
                .count == 15 ? .nist256p1 : .secp256k1
            var privateKey = hdWallet.getKeyByCurve(
                curve: curve,
                derivationPath: WalletManager.flowPath
            )
            let hashedData = Hash.sha256(data: signableData)

            defer {
                privateKey = PrivateKey()
            }

            guard var signature = privateKey.sign(digest: hashedData, curve: curve) else {
                throw LLError.signFailed
            }

            signature.removeLast()
            return signature
        }

        // MARK: Internal

        let provider: MultiBackupManager.StoreItem
        var signature: Data?
        var hdWallet: HDWallet?

        func sign(_ text: String) -> String? {
            guard let textData = text.data(using: .utf8) else {
                return nil
            }

            let data = Flow.DomainTag.user.normalize + textData
            return sign(data)
        }

        func sign(_ data: Data) -> String? {
            guard let hdWallet = hdWallet else {
                return nil
            }
            let curve: WalletCore.Curve = hdWallet.mnemonic.words
                .count == 15 ? .nist256p1 : .secp256k1
            var privateKey = hdWallet.getKeyByCurve(
                curve: curve,
                derivationPath: WalletManager.flowPath
            )

            defer {
                privateKey = PrivateKey()
            }

            let hashedData = Hash.sha256(data: data)
            guard var signature = privateKey.sign(digest: hashedData, curve: curve) else {
                return nil
            }

            signature.removeLast()
            return signature.hexValue
        }

        // MARK: Private

        private func createHDWallet() async throws {
            if hdWallet != nil {
                return
            }
            var key = LocalEnvManager.shared.backupAESKey
            if let code = provider.code {
                guard let pinCode = code.toPassword() else {
                    throw BackupError.hexStringToDataFailed
                }
                key = pinCode
            }

            let mnemonic = try MultiBackupManager.shared.decryptMnemonic(
                provider.data,
                password: key
            )

            self.hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "")
        }
    }
}

extension MultiBackupManager {
    func clearCloud() {
        Task {
            do {
                try await gdTarget.clearCloud()
                try await iCloudTarget.clearCloud()
            }
        }
    }
}

extension String {
    func toPassword() -> String? {
        guard let input = data(using: .utf8) else {
            return nil
        }
        let digest = SHA256.hash(data: input)
        let hashString = digest
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return String(hashString.prefix(16))
    }
}
