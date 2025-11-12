//
//  BackupManager.swift
//  Flow Wallet
//
//  Created by Hao Fu on 2/1/22.
//

import FirebaseAuth
import Foundation
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForRESTCore
import GoogleSignIn
import GTMSessionFetcherCore
import WalletCore

// MARK: - BackupTarget

protocol BackupTarget {
    func uploadMnemonic(password: String) async throws
    func getCurrentDriveItems() async throws -> [BackupManager.DriveItem]
}

extension BackupManager {
    enum BackupType: Int, Codable {
        case none = -1
        case icloud = 0
        case googleDrive
        case manual
        case multi

        // MARK: Internal

        var descLocalizedString: String {
            switch self {
            case .none:
                return ""
            case .icloud:
                return "icloud_drive".localized
            case .googleDrive:
                return "google_drive".localized
            case .manual:
                return "manually".localized
            case .multi:
                return "multi_backup".localized
            }
        }
    }

    static let backupFileName = "outblock_backup"
}

// MARK: - BackupManager.DriveItem

extension BackupManager {
    class DriveItem: Codable {
        // MARK: Lifecycle

        init() {
            self.username = ""
            self.uid = ""
            self.data = ""
            self.version = ""
        }

        // MARK: Internal

        var username: String?
        var uid: String?
        var data: String
        var version: String?
        var time: String?
    }
}

// MARK: - Public

extension BackupManager {
    func uploadMnemonic(to type: BackupManager.BackupType, password: String) async throws {
        switch type {
        case .googleDrive:
            try await gdTarget.uploadMnemonic(password: password)
        case .icloud:
            try await iCloudTarget.uploadMnemonic(password: password)
        default:
            break
        }
    }

    func getCloudDriveItems(
        from type: BackupManager
            .BackupType
    ) async throws -> [BackupManager.DriveItem] {
        switch type {
        case .googleDrive:
            try await gdTarget.relogin()
            return try await gdTarget.getCurrentDriveItems()
        case .icloud:
            return try await iCloudTarget.getCurrentDriveItems()
        default:
            return []
        }
    }

    func isExistOnCloud(_ type: BackupManager.BackupType) async throws -> Bool {
      guard let uid = UserManager.shared.activatedUID else {
            return false
        }

        let items = try await getCloudDriveItems(from: type)
        for item in items {
          if item.uid == uid {
                return true
            }
        }

        return false
    }
}

// MARK: - BackupManager

class BackupManager: ObservableObject {
    // MARK: Internal

    static let shared = BackupManager()

    // MARK: Private

    private let gdTarget = BackupGDTarget()
    private let iCloudTarget = BackupiCloudTarget()
}

// MARK: - Helper

extension BackupManager {
    /// append current user mnemonic to list with encrypt
    func addCurrentMnemonicToList(
        _ list: [BackupManager.DriveItem],
        password: String
    ) throws -> [BackupManager.DriveItem] {
        guard let activatedUID = UserManager.shared.activatedUID, !activatedUID.isEmpty else {
          throw BackupError.missingUid
        }

        guard let mnemonic = WalletManager.shared.getCurrentMnemonic(), !mnemonic.isEmpty,
              let mnemonicData = mnemonic.data(using: .utf8) else {
            throw BackupError.missingMnemonic
        }

        let dataHexString = try encryptMnemonic(mnemonicData, password: password)

        let existItem = list.first { item in
          item.uid == activatedUID
        }

        if let existItem = existItem {
            existItem.version = "1"
            existItem.data = dataHexString
            return list
        }


        let item = BackupManager.DriveItem()
        item.username = UserManager.shared.userInfo?.nickname
        item.uid = activatedUID
        item.version = "1"
        item.data = dataHexString

        var newList = [item]
        newList.append(contentsOf: list)
        return newList
    }

    /// encrypt list to hex string
    func encryptList(_ list: [BackupManager.DriveItem]) throws -> String {
        let jsonData = try JSONEncoder().encode(list)
        let encrypedData = try WalletManager.encryptionAES(
            key: LocalEnvManager.shared.backupAESKey,
            data: jsonData
        )
        return encrypedData.hexString
    }

    /// decrypt hex string to list
    func decryptHexString(_ hexString: String) throws -> [BackupManager.DriveItem] {
        guard let data = Data(hexString: hexString) else {
            throw BackupError.hexStringToDataFailed
        }

        return try decryptData(data)
    }

    private func decryptData(_ data: Data) throws -> [BackupManager.DriveItem] {
        let jsonData = try WalletManager.decryptionAES(
            key: LocalEnvManager.shared.backupAESKey,
            data: data
        )
        let list = try JSONDecoder().decode([BackupManager.DriveItem].self, from: jsonData)
        return list
    }

    /// encrypt mnemonic data to hex string
    func encryptMnemonic(_ mnemonicData: Data, password: String) throws -> String {
        let dataHexString = try WalletManager.encryptionAES(key: password, data: mnemonicData)
            .hexString
        return dataHexString
    }

    /// decrypt hex string to mnemonic string
    func decryptMnemonic(_ hexString: String, password: String) throws -> String {
        guard let encryptData = Data(hexString: hexString) else {
            throw BackupError.hexStringToDataFailed
        }

        let decryptedData = try WalletManager.decryptionAES(key: password, data: encryptData)
        guard let mm = String(data: decryptedData, encoding: .utf8), !mm.isEmpty else {
            throw BackupError.decryptMnemonicFailed
        }

        return mm
    }
}
