//
//  ServiceConfig.swift
//  FRW
//
//  Created by cat on 2023/11/28.
//

import Foundation
import InstabugSDK
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

  static var instabugRNToken: String {
    ServiceConfig.shared.dict["INSTABUG_RN_TOKEN"] ?? ""
  }
  
  static var mixpanelRNToken: String {
    ServiceConfig.shared.dict["MixPanelToken"] ?? ""
  }

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
    Instabug.willSendReportHandler = { report in
      if let uid = UserManager.shared.activatedUID {
        report.setUserAttribute(uid, withKey: "uid")
      }
      if let userName = UserManager.shared.userInfo?.username {
        report.setUserAttribute(userName, withKey: "username")
      }

      if let selectedAccount = WalletManager.shared.selectedAccountAddress {
        report.setUserAttribute(selectedAccount, withKey: "SelectedAccount")
      }

      if let address = WalletManager.shared.getPrimaryWalletAddress() {
        report.setUserAttribute(address, withKey: "FlowAccount")
      }

      if let address = WalletManager.shared.coa?.address {
        report.setUserAttribute(address, withKey: "COA")
      }
      if let addresses = WalletManager.shared.EOAs?.map({ $0.address }) {
        let result = addresses.joined(separator: ",")
        report.setUserAttribute(result, withKey: "EOA")
      }
      if let url = try? ZipFile.zipLogFile() {
        report.addFileAttachment(with: url)
      }

      let childAddress = WalletManager.shared.childs?
        .reduce("") { $0 + "," + $1.address.hexAddr } ?? ""
      report.setUserAttribute(childAddress, withKey: "Childs")
      return report
    }
    // Enabling Proactive Reporting
    let configurations = ProactiveReportingConfigurations()
    configurations.enabled = true // Enable/disable
    configurations.gapBetweenModals = 5 // Time in seconds
    configurations.modalDelayAfterDetection = 5 // Time in seconds
    BugReporting.setProactiveReportingConfigurations(configurations)
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
