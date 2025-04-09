//
//  Migration.swift
//  FRW
//
//  Created by cat on 2024/4/26.
//

import FlowWalletKit
import Foundation
import KeychainAccess

// MARK: - Migration

struct Migration {
    // MARK: Lifecycle

    init() {
        let remoteService = (Bundle.main.bundleIdentifier ?? "com.flowfoundation.wallet")
        self.remoteKeychain = Keychain(service: remoteService)
            .label("Lilico app backup")
            .accessibility(.whenUnlocked)

        let localService = remoteService + ".local"
        self.localKeychain = Keychain(service: localService)
            .label("Flow Wallet Backup")
            .accessibility(.whenUnlocked)
    }

    // MARK: Internal

    func start() {
        fetchiCloudRemoteList()
//        WallectSecureEnclave.Store.migrationFromLilicoTag()
//        try? WallectSecureEnclave.Store.twoBackupIfNeed()
    }

    // MARK: Private

    private let remoteKeychain: Keychain
    private let localKeychain: Keychain
    private let mnemonicPrefix = "lilico.mnemonic."
}

// MARK: iCloud Migration

extension Migration {
    private func fixPinCode(code: String, at key: String) {
        guard var data = code.data(using: .utf8) else {
            log.error("[MIG] fix pin: empty data")
            return
        }
        defer {
            data = Data()
        }
        for uid in UserManager.shared.loginUIDList {
            do {
                let encodedData = try WalletManager.encryptionChaChaPoly(key: uid, data: data)
                let newKey = "lilico.pinCode.\(uid)"
                try localKeychain.set(encodedData, key: newKey)
                try remoteKeychain.remove(key)
            } catch {
                log.error("[MIG] fix pin:\(uid)")
            }
        }
    }

    private func fetchiCloudRemoteList() {
        let list = remoteKeychain.allItems()
        for item in list {
            guard let key = item["key"] as? String else { continue }

            if key == "PinCodeKey", let value = item["value"] as? String {
                do {
                    try localKeychain.set(value, key: key)
                    try remoteKeychain.remove(key)
                    log.info("[MIG] remove key:\(key)")
                } catch {
                    log.error("[MIG] pin")
                }

                continue
            }

            if let value = item["value"] as? Data {
                guard key.contains(mnemonicPrefix) else {
                    continue
                }
                let uid = key.removePrefix(mnemonicPrefix)
                if let decryptedData = try? WalletManager.decryptionChaChaPoly(
                    key: uid,
                    data: value
                ), let mnemonic = String(data: decryptedData, encoding: .utf8), !mnemonic.isEmpty {
                    do {
                        try localKeychain.comment("Lilico user uid: \(uid)").set(value, key: key)
                        try remoteKeychain.remove(key)
                        log.info("[MIG] remove key:\(key)")
                    } catch {
                        log.error("[MIG] set to local:\(error)")
                    }
                }
            }
        }
    }
}
