//
//  SecureEnclaveMigration.swift
//  FRW
//
//  Created by cat on 2024/9/10.
//

import CryptoKit
import FlowWalletKit
import Foundation
import KeychainAccess
import WalletCore

// MARK: - SecureEnclaveMigration

enum SecureEnclaveMigration {
    // MARK: Internal

    static func start() {
        guard !LocalUserDefaults.shared.migrationFinished else {
            return
        }
        LocalUserDefaults.shared.loginUIDList = []
        migrationFromOldSE()
        migrationFromLilicoTag()
        migrationOldSeedPhrase()
        migrationSeedPhraseBackup()
        LocalUserDefaults.shared.migrationFinished = true
    }

    private static func migrationFromOldSE() {
        let service = "com.flowfoundation.wallet.securekey"
        let userKey = "user.keystore"
        let keychain = Keychain(service: service)
        guard let data = try? keychain.getData(userKey) else {
            print("[Mig] SecureEnclave get value from keychain empty,\(service)")
            return
        }
        guard let users = try? JSONDecoder().decode([StoreInfo].self, from: data) else {
            print("[Mig] SecureEnclave list decoder failed ")
            return
        }
        migration(users: users)
    }

    // migrate from lilico tag,Caused by a misquote
    private static func migrationFromLilicoTag() {
        let lilicoService = "io.outblock.lilico.securekey"
        let userKey = "user.keystore"
        let keychain = Keychain(service: lilicoService)
        guard let data = try? keychain.getData(userKey) else {
            log.info("[Mig] migration empty ")
            return
        }
        guard let users = try? JSONDecoder().decode([StoreInfo].self, from: data) else {
            log.info("[Mig] decoder failed on loginedUser ")
            return
        }
        migration(users: users)
    }

    private static func migration(users: [StoreInfo]) {
        var userIds = LocalUserDefaults.shared.loginUIDList
        let startAt = CFAbsoluteTimeGetCurrent()
        var finishCount = 0
        for model in users {
            do {
                guard let privateKey = try? SecureEnclave.P256.Signing
                    .PrivateKey(dataRepresentation: model.publicKey)
                else {
                    log.error("[Mig] migration from Lilico Tag error: private key")
                    continue
                }
                let secureKey = SecureEnclaveKey(
                    key: privateKey,
                    storage: SecureEnclaveKey.KeychainStorage
                )
                if canKeySign(privateKey: secureKey) {
                    guard let publicKey = try secureKey.publicKey()?.hexString else {
                        log.warning("[Mig] migration error: public key is empty")
                        continue
                    }
                    let address = address(by: model.uniq)
                    let storeUser = UserManager.StoreUser(publicKey: publicKey, address: address, userId: model.uniq, keyType: .secureEnclave, account: nil, userInfo: nil)
                    LocalUserDefaults.shared.addUser(user: storeUser)
                    try secureKey.store(id: model.uniq)
                    if !userIds.contains(model.uniq) {
                        userIds.append(model.uniq)
                    }
                    finishCount += 1
                } else {
                    log.warning("[Mig] migration error: not sign")
                }
            } catch {
                log.error("[Mig] migration error:\(error.localizedDescription)")
                continue
            }
        }
        LocalUserDefaults.shared.loginUIDList = userIds
        let endAt = CFAbsoluteTimeGetCurrent()
        log.debug("[Mig] Secure Enclave total: \(users.count), finish: \(finishCount), time:\(endAt - startAt)")
    }

    static func canKeySign(privateKey: SecureEnclaveKey) -> Bool {
        guard let data = generateRandomBytes(),
              let _ = try? privateKey.sign(data: data, hashAlgo: .SHA2_256)
        else {
            return false
        }
        return true
    }

    // MARK: - phrase

    private static func migrationOldSeedPhrase() {
        let mainKeychain =
            Keychain(service: (Bundle.main.bundleIdentifier ?? "com.flowfoundation.wallet") + ".local")
                .label("Lilico app backup")
                .synchronizable(false)
                .accessibility(.whenUnlocked)
        var userIds = LocalUserDefaults.shared.loginUIDList
        let allKeys = mainKeychain.allKeys()
        var finishCount = 0
        for theKey in allKeys {
            let uid = theKey.removePrefix("lilico.mnemonic.")
            guard let data = try? mainKeychain.getData(theKey),
                  let decryptedData = try? WalletManager.decryptionChaChaPoly(key: uid, data: data),
                  let mnemonic = String(data: decryptedData, encoding: .utf8),
                  !mnemonic.isEmpty
            else {
                log.debug("[Mig] invalid userId:\(uid)")
                continue
            }

            guard mnemonic.split(separator: " ").count == 12 else {
                log.debug("[Mig] invalid userId:\(uid)")
                continue
            }

            guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
                log.debug("[Mig] invalid mnemonic:\(uid)")
                continue
            }
            let providerKey = FlowWalletKit.SeedPhraseKey(
                hdWallet: hdWallet,
                storage: FlowWalletKit.SeedPhraseKey.seedPhraseStorage
            )
            guard let publicKey = try? providerKey.publicKey(signAlgo: .ECDSA_SECP256k1)?.hexValue else {
                continue
            }
            let address = address(by: uid)
            let storeUser = UserManager.StoreUser(publicKey: publicKey, address: address, userId: uid, keyType: .seedPhrase, account: nil, userInfo: nil)
            LocalUserDefaults.shared.addUser(user: storeUser)
            finishCount += 1
            try? providerKey.store(id: uid)
            if !userIds.contains(uid) {
                userIds.append(uid)
            }
        }
        log.debug("[Mig] Seed Phrase total: \(allKeys.count), finish: \(finishCount)")
        LocalUserDefaults.shared.loginUIDList = userIds
    }

    private static func migrationSeedPhraseBackup() {
        let mainKeychain =
            Keychain(service: (Bundle.main.bundleIdentifier ?? "com.flowfoundation.wallet") + ".backup.phrase")
                .label("Lilico app backup")
                .synchronizable(false)
                .accessibility(.whenUnlocked)

        let allKeys = mainKeychain.allKeys()
        for userId in allKeys {
            guard let data = try? mainKeychain.getData(userId),
                  let decryptedData = try? WalletManager.decryptionChaChaPoly(key: userId, data: data),
                  let mnemonic = String(data: decryptedData, encoding: .utf8),
                  !mnemonic.isEmpty
            else {
                log.debug("[Mig] invalid userId:\(userId)")
                continue
            }
            guard mnemonic.split(separator: " ").count == 12 else {
                log.debug("[Mig] invalid userId:\(userId)")
                continue
            }

            guard let hdWallet = HDWallet(mnemonic: mnemonic, passphrase: "") else {
                log.debug("[Mig] invalid mnemonic:\(userId)")
                continue
            }
            let providerKey = FlowWalletKit.SeedPhraseKey(
                hdWallet: hdWallet,
                storage: FlowWalletKit.SeedPhraseKey.seedPhraseBackupStorage
            )
            let uid = userId.components(separatedBy: "-backup-").first ?? userId

            try? providerKey.store(id: uid)
        }
    }

    static func address(by uid: String) -> String? {
        var address = MultiAccountStorage.shared.getWalletInfo(uid)?
            .getNetworkWalletModel(network: .mainnet)?.getAddress
        if address == nil {
            address = LocalUserDefaults.shared.userAddressOfDeletedApp[uid]
        }
        return address
    }

    // MARK: Private

    private static func generateRandomBytes(length: Int = 32) -> Data? {
        var keyData = Data(count: length)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }

        if result == errSecSuccess {
            return keyData
        }

        return nil
    }
}

// MARK: - StoreInfo

private struct StoreInfo: Codable {
    // MARK: Lifecycle

    init(uniq: String, publicKey: Data) {
        self.uniq = uniq
        self.publicKey = publicKey
    }

    // MARK: Internal

    var uniq: String
    var publicKey: Data
}
