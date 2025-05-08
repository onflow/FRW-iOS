//
//  FlowLog+Add.swift
//  FRW
//
//  Created by cat on 4/23/25.
//

import FlowWalletKit
import Foundation
import UIKit

// MARK: - FlowLog+Start

extension FlowLog {
    static func logEnv() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        let network = currentNetwork.rawValue

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.timeZone = TimeZone.current
        let currentTime = formatter.string(from: Date())

        let userId = UserManager.shared.activatedUID ?? "Not logged in"
        let locale = Locale.current.identifier

        let systemVersion = UIDevice.current.systemVersion

        let info = """
        \n==================
        System Version:             \(systemVersion)
        App Version:                \(version)(\(buildVersion))
        Current Network:            \(network)
        Current Time:               \(currentTime)
        Current User ID:            \(userId)
        Current Locale:             \(locale)
        First Install Version:      \(InstallInfoManager.firstInstallVersion ?? "")
        Migrate from other Devic:   \(InstallInfoManager.isMigratedFromOtherDevice ?? false)
        Migrate Version:            \(InstallInfoManager.migratedVersion ?? "")
        installed Versions:         \(InstallInfoManager.installVersions ?? "")
        ==================
        """

        FlowLog.shared.info(info)
    }
}

extension FlowLog {
    static func SEKeychain() {
        let keychain = SecureEnclaveKey.KeychainStorage
        let keys = keychain.allKeys
        log.info("==== list ====")
        for key in keys {
            let wallet = try? SecureEnclaveKey.wallet(id: key)
            if let wallet {
                let publicKey = wallet.publicKey()?.hexString ?? ""
                log.info("userId: \(key), key: \(publicKey)")
            } else {
                log.info("userId: \(key), error key")
            }
        }
        log.info("=============")
    }
}
