//
//  InstallInfoManager.swift
//  FRW
//
//  Created by cat on 5/8/25.
//

import Foundation
import KeychainAccess

class InstallInfoManager {
    static let userDefaultsUUIDKey = "installUUID"
    static let userDefaultsInstallVersionKey = "installVersion"
    static let userDefaultsMigratedVersionKey = "migratedVersion"
    static let keychainUUIDKey = "installUUID_keychain"
    static let keychainInstallVersionKey = "installVersion_keychain"
    static let userDefaultsInstallVersionsKey = "installVersions"

    private static let keychain = Keychain(service: Bundle.main.bundleIdentifier ?? "com.default.app")

    private static func saveToKeychain(_ value: String, for key: String) {
        try? keychain
            .accessibility(.afterFirstUnlockThisDeviceOnly)
            .set(value, key: key)
    }

    private static func loadFromKeychain(for key: String) -> String? {
        return try? keychain.get(key)
    }

    // Entry: Called when the App is started
    static func recordInstallInfoIfNeeded() {
        let defaults = UserDefaults.standard
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        if defaults.string(forKey: userDefaultsUUIDKey) == nil {
            // First Install
            let uuid = UUID().uuidString
            defaults.set(uuid, forKey: userDefaultsUUIDKey)
            defaults.set(appVersion, forKey: userDefaultsInstallVersionKey)
            saveToKeychain(uuid, for: keychainUUIDKey)
            saveToKeychain(appVersion, for: keychainInstallVersionKey)
        } else if loadFromKeychain(for: keychainUUIDKey) == nil {
            // Migration scenario: Keychain is lost but User Defaults still exist
            if defaults.string(forKey: userDefaultsMigratedVersionKey) == nil {
                defaults.set(appVersion, forKey: userDefaultsMigratedVersionKey)
            }
        }
    }

    // Whether it is migrated
    static var isMigratedFromOtherDevice: Bool {
        let defaults = UserDefaults.standard
        let uuidInDefaults = defaults.string(forKey: userDefaultsUUIDKey)
        let uuidInKeychain = loadFromKeychain(for: keychainUUIDKey)
        // User Defaults have, Keychain does not, which means migration
        return uuidInDefaults != nil && uuidInKeychain == nil
    }

    static var isFirstInstall: Bool {
        return UserDefaults.standard.string(forKey: userDefaultsUUIDKey) == nil
    }

    static var firstInstallVersion: String? {
        return UserDefaults.standard.string(forKey: userDefaultsInstallVersionKey)
    }

    static var migratedVersion: String? {
        return UserDefaults.standard.string(forKey: userDefaultsMigratedVersionKey)
    }

    static var installVersions: [String] {
        return UserDefaults.standard.stringArray(forKey: userDefaultsInstallVersionsKey) ?? []
    }

    // must be called when app start
    static func updateInstallVersionsIfNeeded() {
        let defaults = UserDefaults.standard
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        var versions = defaults.stringArray(forKey: userDefaultsInstallVersionsKey) ?? []
        if !versions.contains(appVersion) {
            versions.append(appVersion)
            defaults.set(versions, forKey: userDefaultsInstallVersionsKey)
        }
    }
}
