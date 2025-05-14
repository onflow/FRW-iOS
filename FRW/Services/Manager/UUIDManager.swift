//
//  UUIDManager.swift
//  FRW
//
//  Created by cat on 2023/10/25.
//

import KeychainAccess
import SwiftUI

enum UUIDManager {
    static func appUUID() -> String {
        var service = Bundle.main.bundleIdentifier ?? "com.flowfoundation.wallet"
        service += ".uuid"
        let mainKeychain = Keychain(service: service)
            .label("Flow Core UUID")
            .synchronizable(false)
            .accessibility(.whenUnlockedThisDeviceOnly)
        let applicationUUID = (UIDevice.current.identifierForVendor?.uuidString)!
        do {
            let key = "uuid"
            let uuid = try mainKeychain.getString(key)
            if uuid == nil {
                try mainKeychain.set(applicationUUID, key: key)
            }
            return uuid ?? applicationUUID
        } catch {
            return applicationUUID
        }
    }
}
