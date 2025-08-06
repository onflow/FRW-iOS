//
//  RNTokenModel.swift
//  FRW
//
//  Created by Auto-generated on 2025-01-08.
//  Model that matches RN TokenInfo structure for cross-platform compatibility
//

import Foundation

// MARK: - RNWalletType

/// Wallet type enum matching RN WalletType
enum RNWalletType: String, Codable, CaseIterable {
    case Flow = "Flow"
    case EVM = "EVM"
}

// MARK: - RNFlowPath

/// Flow path structure matching RN FlowPath
struct RNFlowPath: Codable, Hashable {
    let domain: String?
    let identifier: String?
    
    init(domain: String? = nil, identifier: String? = nil) {
        self.domain = domain
        self.identifier = identifier
    }
}

// MARK: - RNTokenModel

/// TokenModel that exactly matches RN TokenInfo structure
struct RNTokenModel: Codable, Hashable {
    
    // MARK: - Properties
    
    let type: RNWalletType
    let name: String
    let symbol: String?
    let description: String?
    let balance: String?
    let contractAddress: String?
    let contractName: String?
    let storagePath: RNFlowPath?
    let receiverPath: RNFlowPath?
    let balancePath: RNFlowPath?
    let identifier: String?
    let isVerified: Bool?
    let logoURI: String?
    let priceInUSD: String?
    let balanceInUSD: String?
    let priceInFLOW: String?
    let balanceInFLOW: String?
    let currency: String?
    let priceInCurrency: String?
    let balanceInCurrency: String?
    let displayBalance: String?
    let availableBalanceToUse: String?
    let change: String?
    let decimal: Int?
    let evmAddress: String?
    let website: String?
    
    // MARK: - Initializer
    
    init(
        type: RNWalletType,
        name: String,
        symbol: String? = nil,
        description: String? = nil,
        balance: String? = nil,
        contractAddress: String? = nil,
        contractName: String? = nil,
        storagePath: RNFlowPath? = nil,
        receiverPath: RNFlowPath? = nil,
        balancePath: RNFlowPath? = nil,
        identifier: String? = nil,
        isVerified: Bool? = nil,
        logoURI: String? = nil,
        priceInUSD: String? = nil,
        balanceInUSD: String? = nil,
        priceInFLOW: String? = nil,
        balanceInFLOW: String? = nil,
        currency: String? = nil,
        priceInCurrency: String? = nil,
        balanceInCurrency: String? = nil,
        displayBalance: String? = nil,
        availableBalanceToUse: String? = nil,
        change: String? = nil,
        decimal: Int? = nil,
        evmAddress: String? = nil,
        website: String? = nil
    ) {
        self.type = type
        self.name = name
        self.symbol = symbol
        self.description = description
        self.balance = balance
        self.contractAddress = contractAddress
        self.contractName = contractName
        self.storagePath = storagePath
        self.receiverPath = receiverPath
        self.balancePath = balancePath
        self.identifier = identifier
        self.isVerified = isVerified
        self.logoURI = logoURI
        self.priceInUSD = priceInUSD
        self.balanceInUSD = balanceInUSD
        self.priceInFLOW = priceInFLOW
        self.balanceInFLOW = balanceInFLOW
        self.currency = currency
        self.priceInCurrency = priceInCurrency
        self.balanceInCurrency = balanceInCurrency
        self.displayBalance = displayBalance
        self.availableBalanceToUse = availableBalanceToUse
        self.change = change
        self.decimal = decimal
        self.evmAddress = evmAddress
        self.website = website
    }
    
    // MARK: - Convenience Methods
    
    /// Check if this is a Flow token
    func isFlow() -> Bool {
        return symbol?.uppercased() == "FLOW"
    }
    
    /// Get display balance with symbol
    func getDisplayBalanceWithSymbol() -> String {
        guard let displayBalance = displayBalance,
              let displayBalanceNum = Double(displayBalance),
              !displayBalanceNum.isNaN else {
            return ""
        }
        
        let symbolText = symbol ?? ""
        return "\(formatCurrency(displayBalanceNum)) \(symbolText)".trimmingCharacters(in: .whitespaces)
    }
    
    /// Get display balance in FLOW
    func getDisplayBalanceInFLOW() -> String {
        guard let balanceInFLOW = balanceInFLOW,
              let balanceNum = Double(balanceInFLOW),
              !balanceNum.isNaN else {
            return ""
        }
        
        return "\(formatCurrency(balanceNum)) FLOW"
    }
    
    // MARK: - Private Helpers
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Dictionary Conversion

extension RNTokenModel {
    
    /// Convert to dictionary for bridge communication
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["type"] = type.rawValue
        dict["name"] = name
        dict["symbol"] = symbol
        dict["description"] = description
        dict["balance"] = balance
        dict["contractAddress"] = contractAddress
        dict["contractName"] = contractName
        
        if let storagePath = storagePath {
            dict["storagePath"] = [
                "domain": storagePath.domain,
                "identifier": storagePath.identifier
            ]
        }
        
        if let receiverPath = receiverPath {
            dict["receiverPath"] = [
                "domain": receiverPath.domain,
                "identifier": receiverPath.identifier
            ]
        }
        
        if let balancePath = balancePath {
            dict["balancePath"] = [
                "domain": balancePath.domain,
                "identifier": balancePath.identifier
            ]
        }
        
        dict["identifier"] = identifier
        dict["isVerified"] = isVerified
        dict["logoURI"] = logoURI
        dict["priceInUSD"] = priceInUSD
        dict["balanceInUSD"] = balanceInUSD
        dict["priceInFLOW"] = priceInFLOW
        dict["balanceInFLOW"] = balanceInFLOW
        dict["currency"] = currency
        dict["priceInCurrency"] = priceInCurrency
        dict["balanceInCurrency"] = balanceInCurrency
        dict["displayBalance"] = displayBalance
        dict["availableBalanceToUse"] = availableBalanceToUse
        dict["change"] = change
        dict["decimal"] = decimal
        dict["evmAddress"] = evmAddress
        dict["website"] = website
        
        return dict
    }
    
    /// Create from dictionary (from bridge communication)
    static func fromDictionary(_ dict: [String: Any]) -> RNTokenModel? {
        guard let typeString = dict["type"] as? String,
              let type = RNWalletType(rawValue: typeString),
              let name = dict["name"] as? String else {
            return nil
        }
        
        func flowPathFromDict(_ pathDict: Any?) -> RNFlowPath? {
            guard let pathDict = pathDict as? [String: Any] else { return nil }
            return RNFlowPath(
                domain: pathDict["domain"] as? String,
                identifier: pathDict["identifier"] as? String
            )
        }
        
        return RNTokenModel(
            type: type,
            name: name,
            symbol: dict["symbol"] as? String,
            description: dict["description"] as? String,
            balance: dict["balance"] as? String,
            contractAddress: dict["contractAddress"] as? String,
            contractName: dict["contractName"] as? String,
            storagePath: flowPathFromDict(dict["storagePath"]),
            receiverPath: flowPathFromDict(dict["receiverPath"]),
            balancePath: flowPathFromDict(dict["balancePath"]),
            identifier: dict["identifier"] as? String,
            isVerified: dict["isVerified"] as? Bool,
            logoURI: dict["logoURI"] as? String,
            priceInUSD: dict["priceInUSD"] as? String,
            balanceInUSD: dict["balanceInUSD"] as? String,
            priceInFLOW: dict["priceInFLOW"] as? String,
            balanceInFLOW: dict["balanceInFLOW"] as? String,
            currency: dict["currency"] as? String,
            priceInCurrency: dict["priceInCurrency"] as? String,
            balanceInCurrency: dict["balanceInCurrency"] as? String,
            displayBalance: dict["displayBalance"] as? String,
            availableBalanceToUse: dict["availableBalanceToUse"] as? String,
            change: dict["change"] as? String,
            decimal: dict["decimal"] as? Int,
            evmAddress: dict["evmAddress"] as? String,
            website: dict["website"] as? String
        )
    }
}

// MARK: - Mock Data

extension RNTokenModel {
    
    /// Create mock Flow token
    static func mockFlow() -> RNTokenModel {
        return RNTokenModel(
            type: .Flow,
            name: "Flow",
            symbol: "FLOW",
            description: "Flow is the digital currency that powers the Flow network.",
            balance: "100000000", // 1.0 FLOW in smallest unit
            contractAddress: "1654653399040a61",
            contractName: "FlowToken",
            storagePath: RNFlowPath(domain: "storage", identifier: "flowTokenVault"),
            receiverPath: RNFlowPath(domain: "public", identifier: "flowTokenReceiver"),
            balancePath: RNFlowPath(domain: "public", identifier: "flowTokenBalance"),
            identifier: "A.1654653399040a61.FlowToken",
            isVerified: true,
            logoURI: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.1654653399040a61.FlowToken/logo.svg",
            priceInUSD: "0.50",
            balanceInUSD: "50.0",
            priceInFLOW: "1.0",
            balanceInFLOW: "100.0",
            currency: "USD",
            priceInCurrency: "0.50",
            balanceInCurrency: "50.0",
            displayBalance: "100.0",
            availableBalanceToUse: "100.0",
            change: nil,
            decimal: 8,
            evmAddress: nil,
            website: "https://flow.com"
        )
    }
    
    /// Create mock USDC token
    static func mockUSDC() -> RNTokenModel {
        return RNTokenModel(
            type: .EVM,
            name: "USD Coin",
            symbol: "USDC",
            description: "USD Coin is a fully-collateralized US dollar stablecoin.",
            balance: "1000000000", // 1000.0 USDC in smallest unit (6 decimals)
            contractAddress: "A0b86a33E6842c4ce28d6b77f4F5b4A5FE6DbEFf",
            contractName: "FiatToken",
            storagePath: nil,
            receiverPath: nil,
            balancePath: nil,
            identifier: "A.A0b86a33E6842c4ce28d6b77f4F5b4A5FE6DbEFf.FiatToken",
            isVerified: true,
            logoURI: "https://assets.coingecko.com/coins/images/6319/large/USD_Coin_icon.png",
            priceInUSD: "1.00",
            balanceInUSD: "1000.0",
            priceInFLOW: "2.0",
            balanceInFLOW: "2000.0",
            currency: "USD",
            priceInCurrency: "1.00",
            balanceInCurrency: "1000.0",
            displayBalance: "1000.0",
            availableBalanceToUse: "1000.0",
            change: nil,
            decimal: 6,
            evmAddress: "0xA0b86a33E6842c4ce28d6b77f4F5b4A5FE6DbEFf",
            website: "https://www.centre.io/"
        )
    }
}

// MARK: - Conversion from Native TokenModel

extension RNTokenModel {
    
    /// Convert from native TokenModel to RNTokenModel
    static func fromTokenModel(_ tokenModel: TokenModel) -> RNTokenModel {
        // Convert TokenModel.TokenType to RNWalletType
        let rnType: RNWalletType = tokenModel.typeValue == .cadence ? .Flow : .EVM
        
        // Convert FlowPath if exists
        let rnStoragePath = tokenModel.storagePath.map { flowPath in
            RNFlowPath(domain: flowPath.domain, identifier: flowPath.identifier)
        }
        let rnReceiverPath = tokenModel.receiverPath.map { flowPath in
            RNFlowPath(domain: flowPath.domain, identifier: flowPath.identifier)
        }
        let rnBalancePath = tokenModel.balancePath.map { flowPath in
            RNFlowPath(domain: flowPath.domain, identifier: flowPath.identifier)
        }
        
        return RNTokenModel(
            type: rnType,
            name: tokenModel.name,
            symbol: tokenModel.symbol,
            description: tokenModel.description,
            balance: tokenModel.balance,
            contractAddress: tokenModel.contractAddress,
            contractName: tokenModel.contractName,
            storagePath: rnStoragePath,
            receiverPath: rnReceiverPath,
            balancePath: rnBalancePath,
            identifier: tokenModel.identifier,
            isVerified: tokenModel.isVerifiedValue,
            logoURI: tokenModel.logoURI,
            priceInUSD: tokenModel.priceInUSD,
            balanceInUSD: tokenModel.balanceInUSD,
            priceInFLOW: tokenModel.priceInFLOW,
            balanceInFLOW: tokenModel.balanceInFLOW,
            currency: tokenModel.currency,
            priceInCurrency: tokenModel.priceInCurrency,
            balanceInCurrency: tokenModel.balanceInCurrency,
            displayBalance: tokenModel.displayBalance,
            availableBalanceToUse: tokenModel.availableBalanceToUse,
            change: nil, // TokenModel doesn't have change field
            decimal: tokenModel.decimalValue,
            evmAddress: tokenModel.evmAddress,
            website: tokenModel.website?.absoluteString
        )
    }
}