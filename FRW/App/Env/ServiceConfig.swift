//
//  ServiceConfig.swift
//  FRW
//
//  Created by cat on 2023/11/28.
//

import Foundation
import Instabug
import SwiftyDropbox

// MARK: - ServiceConfig

class ServiceConfig {
    // MARK: Lifecycle

    init() {
        guard let filePath = Bundle.main.path(forResource: "ServiceConfig", ofType: "plist") else {
            fatalError("fatalError ===> Can't find ServiceConfig.plist")
        }
        self.dict = NSDictionary(contentsOfFile: filePath) as? [String: String] ?? [:]
    }

    // MARK: Internal

    static let shared = ServiceConfig()

    static func configure() {
        ServiceConfig.shared.setupInstabug()
        ServiceConfig.shared.setupMixPanel()
        ServiceConfig.shared.setupDropbox()
    }

    // MARK: Private

    private let dict: [String: String]
}

// MARK: config

extension ServiceConfig {
    private func setupInstabug() {
        guard let token = dict["instabug-key"] else {
            fatalError("fatalError ===> Can't find instabug key at ServiceConfig.plist")
        }

        InstabugConfig.start(token: token)
    }

    private func setupMixPanel() {
        guard let token = dict["MixPanelToken"] else {
            fatalError("fatalError ===> Can't find MixPanel Token at ServiceConfig.plist")
        }
        EventTrack.start(token: token)
    }
    
    private func setupDropbox() {
        let appKey = ServiceConfig.shared.dropboxAppKey
        DropboxClientsManager.setupWithTeamAppKey(appKey)
    }
}

extension ServiceConfig {

    var dropboxAppKey: String {
        guard let appKey = dict["dropbox-appkey"] else {
            fatalError("Can't find Dropbox appKey at ServiceConfig.plist")
        }
        return appKey
    }
    
    var scriptPublicKey: String {
        guard let key = dict["scripts-publicKey"] else {
            fatalError("Can't find scripts publicKey at ServiceConfig.plist")
        }
        return key
    }
}
