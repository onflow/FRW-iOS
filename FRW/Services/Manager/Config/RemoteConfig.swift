//
//  RemoteConfig.swift
//  Flow Wallet
//
//  Created by Hao Fu on 5/9/2022.
//

import Foundation

extension RemoteConfigManager {
    struct ContractAddress: Codable {
        let mainnet: [String: String]?
        let testnet: [String: String]?
        let crescendo: [String: String]?
    }

    struct ENVConfig: Codable {
        enum CodingKeys: String, CodingKey {
            case version
            case prod
            case staging
            case versionProd = "version_prod"
        }

        let version: String
        let versionProd: String
        let prod: Config
        let staging: Config
    }

    struct Config: Codable {
        let features: Features
        let payer: Payer
        let bridgeFeePayer: Payer
    }

    // MARK: - Features

    struct Features: Codable {
        enum CodingKeys: String, CodingKey {
            case freeGas = "free_gas"
            case walletConnect = "wallet_connect"
            case onRamp = "on_ramp"
            case appList = "app_list"
            case swap
            case browser
            case nftTransfer = "nft_transfer"
            case hideBrowser = "hide_browser"
            case transactionWarningPrediction = "tx_warning_prediction"
            case coverBridgeFee = "cover_bridge_fee"
        }

        let freeGas: Bool
        let walletConnect: Bool
        let onRamp: Bool?
        let appList: Bool?
        let swap: Bool?
        let browser: Bool?
        let nftTransfer: Bool?
        let hideBrowser: Bool?
        let transactionWarningPrediction: Bool?
        let coverBridgeFee: Bool?
    }

    // MARK: - Payer

    struct Payer: Codable {
        let mainnet: PayerInfo
        let testnet: PayerInfo
        let crescendo: PayerInfo?
    }

    // MARK: - Net

    struct PayerInfo: Codable {
        enum CodingKeys: String, CodingKey {
            case address
            case keyID = "keyId"
        }

        let address: String
        let keyID: Int
    }

    // MARK: - News

    enum NewsType: String, Codable {
        case message
        case image

        case undefined

        // MARK: Lifecycle

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try? container.decode(String.self)
            self = NewsType(rawValue: rawValue ?? "") ?? .undefined
        }
    }

    enum NewsPriority: String, Codable, Comparable {
        case low
        case medium
        case high
        case urgent

        // MARK: Lifecycle

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try? container.decode(String.self)
            self = NewsPriority(rawValue: rawValue ?? "") ?? .low
        }

        // MARK: Internal

        static func < (
            lhs: RemoteConfigManager.NewsPriority,
            rhs: RemoteConfigManager.NewsPriority
        ) -> Bool {
            lhs.level < rhs.level
        }

        // MARK: Private

        private var level: Int {
            switch self {
            case .low:
                return 100
            case .medium:
                return 500
            case .high:
                return 750
            case .urgent:
                return 1000
            }
        }
    }

    enum NewDisplayType: String, Codable {
        case once
        case click
        case expiry

        // MARK: Lifecycle

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try? container.decode(String.self)
            self = NewDisplayType(rawValue: rawValue ?? "") ?? .expiry
        }
    }

    enum NewsFlag: String, Codable {
        case normal
        case walletconnect
        case upgrade

        // MARK: Lifecycle

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try? container.decode(String.self)
            self = NewsFlag(rawValue: rawValue ?? "") ?? .normal
        }
    }

    struct Condition: Codable, Hashable {
        let type: ConditionType
//       let data: JsonObject? // can be ignored this time
    }

    enum ConditionType: String, Codable {
        case unknow
        case canUpgrade
        case insufficientStorage
        case insufficientBalance
        case isIOS
        case isAndroid
        case isWeb
        case cadence // can be ignored this time
        case noBackup // can be ignored this time
        case noBiometric // can be ignored this time

        // MARK: Lifecycle

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let rawValue = try? container.decode(String.self)
            self = ConditionType(rawValue: rawValue ?? "") ?? .unknow
        }

        // MARK: Internal

        func boolValue() -> Bool {
            switch self {
            case .unknow:
                return false
            case .canUpgrade:
                if let remoteVersion = RemoteConfigManager.shared.remoteVersion,
                   let currentVersion = Bundle.main
                   .infoDictionary?["CFBundleShortVersionString"] as? String
                {
                    return remoteVersion.compareVersion(to: currentVersion) == .orderedDescending
                } else {
                    return false
                }
            case .isIOS:
                return true
            case .insufficientStorage:
                // TODO: [AB] Not very elegant adding a dependency here, but implementing in a different way would probably require major refactoring
                return WalletManager.shared.isStorageInsufficient
            case .insufficientBalance:
                return WalletManager.shared.isBalanceInsufficient
            default:
                return false
            }
        }
    }

    struct News: Codable, Comparable, Identifiable, Hashable {
        let id: String
        let priority: NewsPriority
        let type: NewsType
        let title: String
        let body: String?
        /// Do not use this property directly, call 'iconURL'
        let icon: String?
        let image: String?
        let url: String?
        let expiryTime: Date
        let displayType: NewDisplayType

        var flag: NewsFlag? = .normal
        let conditions: [Condition]?

        var iconURL: URL? {
            if let logoString = icon {
                if logoString.hasSuffix("svg") {
                    return logoString.convertedSVGURL()
                }
                return URL(string: logoString)
            }
            return nil
        }

        static func < (lhs: RemoteConfigManager.News, rhs: RemoteConfigManager.News) -> Bool {
            lhs.priority < rhs.priority
        }

        static func == (lhs: RemoteConfigManager.News, rhs: RemoteConfigManager.News) -> Bool {
            lhs.id == rhs.id
        }
    }
}
