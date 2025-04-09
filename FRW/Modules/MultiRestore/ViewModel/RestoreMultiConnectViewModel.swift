//
//  RestoreMultiConnectViewModel.swift
//  FRW
//
//  Created by cat on 2024/1/7.
//

import Flow
import Foundation
import WalletCore

// MARK: - RestoreMultiConnectViewModel

class RestoreMultiConnectViewModel: ObservableObject {
    // MARK: Lifecycle

    init(items: [MultiBackupType]) {
        self.items = items
        self.currentIndex = 0
        if !self.items.isEmpty {
            self.currentType = self.items[0]
        }
    }

    // MARK: Internal

    let items: [MultiBackupType]
    @Published
    var enable: Bool = true
    @Published
    var process: BackupProcess = .idle
    @Published
    var isEnd: Bool = false
    var currentType: MultiBackupType = .google

    var storeItems: [[MultiBackupManager.StoreItem]] = []
    var phraseItem: MultiBackupManager.StoreItem?

    @Published
    var currentIndex: Int = 0 {
        didSet {
            if currentIndex < items.count {
                currentType = items[currentIndex]
            }
        }
    }

    // MARK: Private

    private var validationErrorsOccurred: Bool = false
}

// MARK: Action

extension RestoreMultiConnectViewModel {
    func onClickButton() {
        if isEnd {
            let list = checkValidUser()
            if list.isEmpty {
                enable = true
                Router.route(to: RouteMap.RestoreLogin.restoreErrorView(.noAccountFound))
                return
            }
            Router.route(to: RouteMap.RestoreLogin.multiAccount(list))
            return
        }
        if currentType == .phrase {
            Router.route(to: RouteMap.RestoreLogin.inputMnemonic { str in
                self.createStoreItem(with: str)
            })
            return
        }
        enable = false
        Task {
            do {
                let list = try await MultiBackupManager.shared.getAllCloudDriveItem(from: currentType)
                if list.isEmpty {
                    self.enable = true
                    Router.route(to: RouteMap.RestoreLogin.restoreErrorView(.notfound))
                    return
                }
                if currentType.needPin {
                    Router.route(to: RouteMap.Backup.verityPin(.restore) { allow, pin in
                        if allow {
                            let verifyList = self.verify(list: list, with: pin)
                            if !list.isEmpty, self.validationErrorsOccurred {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.enable = true
                                    Router
                                        .route(
                                            to: RouteMap.RestoreLogin
                                                .restoreErrorView(.decryption)
                                        )
                                }
                                return
                            }
                            self.storeItem(list: verifyList)
                        } else {
                            DispatchQueue.main.async {
                                self.enable = true
                            }
                        }
                    })
                } else {
                    storeItem(list: list)
                }
            } catch {
                DispatchQueue.main.async {
                    self.enable = true
                    Router.route(to: RouteMap.RestoreLogin.restoreErrorView(.notfound))
                }
            }
        }
    }

    private func storeItem(list: [MultiBackupManager.StoreItem]) {
        DispatchQueue.main.async {
            self.storeItems.append(list)
            let nextIndex = self.currentIndex + 1
            if self.items.count <= nextIndex {
                self.currentIndex = nextIndex
                self.isEnd = true
            } else {
                self.currentIndex = nextIndex
            }
            self.enable = true
        }
    }

    private func verify(
        list: [MultiBackupManager.StoreItem],
        with pin: String
    ) -> [MultiBackupManager.StoreItem] {
        let pinCode = pin.toPassword() ?? pin
        var result: [MultiBackupManager.StoreItem] = []
        validationErrorsOccurred = false
        for item in list {
            if let _ = try? MultiBackupManager.shared
                .decryptMnemonic(item.data, password: pinCode) {
                var newItem = item
                newItem.code = pin
                result.append(newItem)
            }
        }

        return result
    }

    private func createStoreItem(with mnemonic: String) {
        guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: ""),
              let mnemonicData = hdWallet.mnemonic.data(using: .utf8)
        else {
            HUD.error(WalletError.invalidMnemonic)
            return
        }
        
        let isOldAccount = hdWallet.mnemonic.words.count == 12
        let signAlgo = isOldAccount ? Flow.SignatureAlgorithm.ECDSA_SECP256k1 : Flow
            .SignatureAlgorithm.ECDSA_P256
        
        guard let publicKey = hdWallet.getPublicKey(signAlgo: signAlgo) else {
            HUD.error(WalletError.invaildPublicKey)
            return
        }
        
        let key = LocalEnvManager.shared.backupAESKey
        do {
            let dataHexString = try MultiBackupManager.shared.encryptMnemonic(
                mnemonicData,
                password: key
            )

            let item = MultiBackupManager.StoreItem(
                address: "",
                userId: "",
                userName: "",
                publicKey: publicKey.data.hexValue,
                data: dataHexString,
                keyIndex: 0,
                signAlgo: signAlgo.index,
                hashAlgo: Flow.HashAlgorithm.SHA2_256.index,
                weight: isOldAccount ? 1000 : 500,
                deviceInfo: IPManager.shared.toParams()
            )
            phraseItem = item
            let nextIndex = currentIndex + 1
            if items.count <= nextIndex {
                currentIndex = nextIndex
                isEnd = true
            } else {
                currentIndex = nextIndex
            }
            enable = true
        } catch {
            HUD.error(BackupError.decryptMnemonicFailed)
        }
    }

    func checkValidUser() -> [[MultiBackupManager.StoreItem]] {
        var items: [String: [MultiBackupManager.StoreItem]] = [:]
        for list in storeItems {
            for storeItem in list {
                if var exitList = items[storeItem.userId] {
                    exitList.append(storeItem)
                    items[storeItem.userId] = exitList
                } else {
                    items[storeItem.userId] = [storeItem]
                }
            }
        }
        var result = items.values.map { list in
            var res = list
            if var phraseItem = self.phraseItem, let firstItem = list.first {
                phraseItem.address = firstItem.address
                res.append(phraseItem)
            }
            return res
        }
        result = result.filter { $0.count > 1 }
        return result
    }
}

// MARK: UI

extension RestoreMultiConnectViewModel {
    var currentIcon: String {
        currentType.iconName()
    }

    var currentTitle: String {
        if isEnd {
            return "prepared_to_restore".localized
        }
        return "connect_to_x".localized(currentType.title)
    }

    var currentNote: String {
        currentType.noteDes
    }

    var currentButton: String {
        if isEnd {
            return "restore_wallet".localized
        }
        return "connect".localized + " " + currentType.title
    }
}
