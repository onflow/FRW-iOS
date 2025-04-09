//
//  KeychainListViewModel.swift
//  FRW
//
//  Created by cat on 2024/4/26.
//

import FlowWalletKit
import Foundation
import KeychainAccess
import SwiftUI

class KeychainListViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        let remoteService = (Bundle.main.bundleIdentifier ?? "com.flowfoundation.wallet")
        self.remoteKeychain = Keychain(service: remoteService)
            .label("Lilico app backup")

        let localService = remoteService + ".local"
        self.localKeychain = Keychain(service: localService)
            .label("Flow Wallet Backup")

        self.seKeychain = Keychain(service: "com.flowfoundation.wallet.securekey")
        
        fecth()
    }

    // MARK: Internal

    @Published
    var localList: [[String: Any]] = []
    @Published
    var remoteList: [[String: Any]] = []
    @Published
    var seList: [[String: String]] = []
    @Published
    var multiICloudBackUpList: [[String: String]] = []

    func loadiCloudBackup() {
        Task {
            if let list = try? await MultiBackupManager.shared.getCloudDriveItems(from: .icloud) {
                DispatchQueue.main.async {
                    self.multiICloudBackUpList = list.map { [$0.userId: $0.publicKey] }
                }
            }
        }
    }

    func radomUpdatePrivateKey(index _: Int) {
        if isDevModel {
            // Modifying private key for test
        }
    }

    func deleteSeedPhrase(_ index: Int) {
        do {
            let keychain = SeedPhraseKey.seedPhraseStorage
            guard let key = spItem[safe:index]?["userId"] else {
                return
            }
            try keychain.remove(key)
            HUD.success(title: "remove Seed Phrase key")
        }catch {
            HUD.error(title: error.localizedDescription)
        }
    }

    func getKey(item: [String: Any]) -> String {
        guard let key = item["key"] as? String else {
            return "not found key"
        }
        return key.removedPrefix(mnemonicPrefix)
    }

    func mnemonicValue(item: [String: Any]) -> String {
        guard let key = item["key"] as? String, let value = item["value"] else {
            return "error item"
        }

        if key.contains(mnemonicPrefix), let data = value as? Data {
            let uid = key.removePrefix(mnemonicPrefix)
            if let decryptedData = try? WalletManager.decryptionChaChaPoly(key: uid, data: data),
               let mnemonic = String(
                   data: decryptedData,
                   encoding: .utf8
               ) {
                return mnemonic
            }
            return "decrypted failed"
        }

        return "not mnemonic"
    }

    // MARK: Private

    private let remoteKeychain: Keychain
    private let localKeychain: Keychain
    private let seKeychain: Keychain
    private let mnemonicPrefix = "lilico.mnemonic."

    var seItem: [[String: String]] = []
    var spItem: [[String: String]] = []
    var pkItem: [[String: String]] = []
    var ksItem: [[String: String]] = []

    private func fecth() {
        fetchSecureEnclave()
        fetchSeedphrase()
        fetchPrivateKey()
    }

    private func fetchSecureEnclave() {
        let keychain = SecureEnclaveKey.KeychainStorage
        let keys = keychain.allKeys
        for key in keys {
            let wallet = try? SecureEnclaveKey.wallet(id: key)
            if let wallet {
                let publicKey = (wallet.publicKey()?.hexString) ?? ""
                seItem.append(["userId": key, "public key": publicKey])
            }else {
                seItem.append(["userId": key, "public key": "error"])
            }
        }
    }

    private func fetchSeedphrase() {
        let keychain = SeedPhraseKey.seedPhraseStorage
        let keys = keychain.allKeys
        for key in keys {
            let wallet = try? SeedPhraseKey.wallet(id: key)
            if let wallet {
                let mnemonic = wallet.hdWallet.mnemonic
                var result = ["userId": key,
                              "mnemonic": mnemonic,
                              "length": String(mnemonic.split(separator: " ").count)]
                result["passphrase"] = wallet.passphrase
                result["derivationPath"] = SeedPhraseKey.derivationPath
                spItem.append(result)
            }else {
                spItem.append(["userId": key,"mnemonic": "error"])
            }
        }
    }

    private func fetchPrivateKey() {
        let keychain = PrivateKey.PKStorage
        let keys = keychain.allKeys
        for key in keys {
            let wallet = try? PrivateKey.wallet(id: key)
            if let wallet {
                let P256publicKey = (wallet.publicKey(signAlgo: .ECDSA_P256)?.hexString) ?? ""
                let SECPpublicKey = (wallet.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexString) ?? ""
                pkItem.append(["userId": key,"P256": P256publicKey, "SECP256k1": SECPpublicKey])
            }else {
                pkItem.append(["userId": key,"public key": "error"])
            }
        }
    }


    func clearAllKey() {
        let seKeychain = SecureEnclaveKey.KeychainStorage
        try? seKeychain.removeAll()
        let spKeychain = SeedPhraseKey.seedPhraseStorage
        try? spKeychain.removeAll()
        let pKeychain = PrivateKey.PKStorage
        try? pKeychain.removeAll()
        LocalUserDefaults.shared.migrationFinished = false
    }
}
