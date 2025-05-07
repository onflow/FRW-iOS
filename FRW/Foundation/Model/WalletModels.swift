//
//  WalletModels.swift
//  Flow Wallet
//
//  Created by Hao Fu on 30/4/2022.
//

import BigInt
import Flow
import Foundation
import Web3Core

// MARK: - QuoteMarket

enum QuoteMarket: String {
    case binance
    case kraken
    case huobi

    // MARK: Internal

    var flowPricePair: String {
        switch self {
        case .kraken:
            return "flowusd"
        default:
            return "flowusdt"
        }
    }

    var usdcPricePair: String {
        switch self {
        case .kraken:
            return "usdcusd"
        default:
            return "usdcusdt"
        }
    }

    var iconName: String {
        rawValue
    }
}

// MARK: - ListedToken

enum ListedToken: String, CaseIterable {
    case flow
    case fusd
    case stFlow
    case usdc
    case other

    // MARK: Lifecycle

    init?(rawValue: String) {
        if let item = ListedToken.allCases
            .first(where: { $0.rawValue.lowercased() == rawValue.lowercased() })
        {
            self = item
        } else {
            self = .other
        }
    }

    // MARK: Internal

    enum PriceAction {
        case fixed(price: Decimal)
        case query(String)
        case mirror(ListedToken)
    }

    var priceAction: PriceAction {
        switch self {
        case .flow:
            return .query(LocalUserDefaults.shared.market.flowPricePair)
        case .fusd:
            return .fixed(price: 1.0)
        case .stFlow:
            return .fixed(price: 1.0)
        case .usdc:
            return .fixed(price: 1.0)
        case .other:
            return .fixed(price: 0.0)
        }
    }
}

// MARK: - TokenModel

struct TokenModel: Codable, Identifiable, Mockable {
    // MARK: Public

    public enum TokenType: Codable { case cadence, evm }

    // MARK: Internal

    @available(*, deprecated, message: "Use typeValue")
    var type: TokenType? = .cadence

    let name: String
    let symbol: String?
    let description: String?

    var balance: String?
    let contractAddress: String?
    let contractName: String
    let storagePath: FlowPath?
    let receiverPath: FlowPath?
    let balancePath: FlowPath?
    let identifier: String?

    @available(*, deprecated, message: "Use isVerifiedValue")
    let isVerified: Bool?
    let logoURI: String?
    /// 0.405351
    let priceInUSD: String?
    /// "3468.0638534703663244"
    let balanceInUSD: String?
    /// 1
    let priceInFLOW: String?
    /// "8550.73240919"
    let balanceInFLOW: String?
    let currency: String?
    /// "0.40558676"
    let priceInCurrency: String?
    /// "3468.0638534703663244"
    let balanceInCurrency: String?
    /// e.g. 0.9998085919
    let displayBalance: String?
    var availableBalanceToUse: String?

    @available(*, deprecated, message: "Use decimalValue")
    var decimal: Int?

    let evmAddress: String?
    let website: URL?

    var vaultIdentifier: String? {
        if type == .evm {
            return identifier
        }

        return "\(contractId).Vault"
    }

    var listedToken: ListedToken? {
        ListedToken(rawValue: symbol ?? "")
    }

    var isFlowCoin: Bool {
        symbol?.lowercased() ?? "" == ListedToken.flow.rawValue
    }

    var contractId: String {
        let addressString = contractAddress?.stripHexPrefix() ?? ""
        return "A.\(addressString).\(contractName)"
    }

    var iconURL: URL {
        if let logoString = logoURI {
            if logoString.hasSuffix("svg") {
                return logoString.convertedSVGURL() ?? URL(string: placeholder)!
            }

            return URL(string: logoString) ?? URL(string: placeholder)!
        }

        return URL(string: placeholder)!
    }

    var readableBalance: Decimal? {
        guard let bal = balance, let bigBal = bal.parseToBigUInt(decimals: decimalValue) else {
            return nil
        }

        let result = Utilities.formatToPrecision(
            bigBal,
            units: .custom(decimalValue),
            formattingDecimals: decimalValue
        )
        return Decimal(string: result)
    }

    var readableBalanceStr: String? {
        guard let bal = readableBalance else {
            return nil
        }
        return bal.doubleValue.formatted(.number.precision(.fractionLength(0 ... 3)))
    }

    var precision: Int {
        switch typeValue {
        case .cadence:
            return min(decimalValue, 8)
        case .evm:
            return min(decimalValue, 18)
        }
    }

    var typeValue: TokenType {
        type ?? .cadence
    }

    var decimalValue: Int {
        decimal ?? (typeValue == .cadence ? 8 : 18)
    }

    var isVerifiedValue: Bool {
        isVerified ?? false
    }

    // Identifiable
    var id: String {
        getId(by: typeValue)
    }

    var isActivated: Bool {
        WalletManager.shared.isTokenActivated(model: self)
    }

    var showBalance: Decimal? {
        guard let bal = availableBalanceToUse ?? displayBalance, let bigBal = bal.parseToBigUInt(decimals: decimalValue) else {
            return nil
        }
        return Decimal(string: Utilities.formatToPrecision(bigBal, units: .custom(decimalValue), formattingDecimals: decimalValue))
    }

    static func mock() -> TokenModel {
        TokenModel(type: .cadence, name: "mockname", symbol: nil, description: nil, contractAddress: nil, contractName: "", storagePath: nil, receiverPath: nil, balancePath: nil, identifier: nil, isVerified: nil, logoURI: nil, priceInUSD: nil, balanceInUSD: nil, priceInFLOW: nil, balanceInFLOW: nil, currency: nil, priceInCurrency: nil, balanceInCurrency: nil, displayBalance: nil, decimal: 8, evmAddress: nil, website: nil,)
    }

    func getAddress() -> String? {
        contractAddress
    }

    func getPricePair(market: QuoteMarket) -> String {
        switch listedToken {
        case .flow:
            return market.flowPricePair
        case .usdc:
            return market.usdcPricePair
        default:
            return market.flowPricePair // TODO: #six Need to confirm
        }
    }

    func getId(by type: TokenType) -> String {
        switch type {
        case .evm:
            return contractAddress ?? ""
        case .cadence:
            return identifier?.removeSuffix(".Vault") ?? contractId
        }
    }
}

extension TokenModel: Equatable {
    static func == (lhs: TokenModel, rhs: TokenModel) -> Bool {
        return lhs.id == rhs.id
    }
}

extension TokenModel {
    func evmBridgeAddress() -> String? {
        guard let addr = identifier?.split(separator: ".")[1] else {
            return nil
        }
        return String(addr).addHexPrefix()
    }

    func evmBridgeContractName() -> String? {
        guard let name = identifier?.split(separator: ".")[2] else {
            return nil
        }
        return String(name)
    }
}

extension TokenModel {
    func aboutTokenUrl() -> URL? {
        let host = currentNetwork.baseUrl(accountType: AccountType.current)
        let path = AccountType.current == .flow ? "/ft/token" : "/token"
        guard let target = AccountType.current == .flow ? identifier : evmAddress else {
            HUD.error(title: "invalid identifier")
            log.error("invalid identifier")
            return nil
        }
        return URL(string: "\(host)\(path)/\(target)")
    }
}

// MARK: - FlowPath

struct FlowPath: Codable {
    let domain: String?
    let identifier: String?

    var value: String? {
        guard let domain, let identifier else {
            return ""
        }
        return domain + "/" + identifier
    }
}
