//
//  ServiceConfig.swift
//  FRW
//
//  Created by cat on 2023/11/28.
//

import Foundation
import Instabug

class ServiceConfig {
    static let shared = ServiceConfig()
    private let dict: [String: String]

    init() {
        guard let filePath = Bundle.main.path(forResource: "ServiceConfig", ofType: "plist") else {
            fatalError("fatalError ===> Can't find ServiceConfig.plist")
        }
        dict = NSDictionary(contentsOfFile: filePath) as? [String: String] ?? [:]
    }

    static func configure() {
        ServiceConfig.shared.setupInstabug()
        ServiceConfig.shared.setupMixPanel()
    }
}

// MARK: instabug config

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
}
