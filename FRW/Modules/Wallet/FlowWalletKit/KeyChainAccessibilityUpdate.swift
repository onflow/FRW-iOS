//
//  KeyChainAccessibilityUpdate.swift
//  FRW
//
//  Created by cat on 5/12/25.
//

import FlowWalletKit
import Foundation
import KeychainAccess

enum KeyChainAccessibilityUpdate {
    static func udpate() {
        updateSeedPhrase()
        updateSeedPhraseBackup()
        updatePrivate()
    }

    private static func updateSeedPhrase() {
        let keychain = Keychain(service: SeedPhraseKey.keychainService)
            .label(SeedPhraseKey.keychainTag)
        print(keychain.allItems())
        let allKeys = keychain.allKeys()
        for key in allKeys {
            if let value = try? keychain.getData(key) {
                do {
                    try keychain
                        .synchronizable(false)
                        .accessibility(.alwaysThisDeviceOnly)
                        .set(value, key: key)
                } catch {
                    log.debug(error)
                }
            }
        }
    }

    private static func updateSeedPhraseBackup() {
        let keychain = Keychain(service: SeedPhraseKey.keychainBackService)
            .label(SeedPhraseKey.keychainBackTag)
        print(keychain.allItems())
        let allKeys = keychain.allKeys()
        for key in allKeys {
            if let value = try? keychain.getData(key) {
                do {
                    try keychain
                        .synchronizable(false)
                        .accessibility(.alwaysThisDeviceOnly)
                        .set(value, key: key)
                } catch {
                    log.debug(error)
                }
            }
        }
    }

    private static func updatePrivate() {
        let keychain = Keychain(service: FlowWalletKit.PrivateKey.keychainService)
            .label(FlowWalletKit.PrivateKey.keychainTag)
        let allKeys = keychain.allKeys()
        print(keychain.allItems())
        for key in allKeys {
            if let value = try? keychain.getData(key) {
                do {
                    try keychain
                        .synchronizable(false)
                        .accessibility(.alwaysThisDeviceOnly)
                        .set(value, key: key)
                } catch {
                    log.debug(error)
                }
            }
        }
    }
}
