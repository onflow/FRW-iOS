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
  case Flow
  case EVM
}

// MARK: - RNFlowPath

/// Flow path structure matching RN FlowPath
struct RNFlowPath: Codable, Hashable {
  // MARK: Lifecycle

  init(domain: String? = nil, identifier: String? = nil) {
    self.domain = domain
    self.identifier = identifier
  }

  // MARK: Internal

  let domain: String?
  let identifier: String?
}

// MARK: - RNTokenModel

/// TokenModel that exactly matches RN TokenInfo structure
struct RNTokenModel: Codable, Hashable {
  // MARK: Lifecycle

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

  // MARK: Internal

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
}

// MARK: - Conversion from Native TokenModel

extension RNTokenModel {
  /// Convert from native TokenModel to RNTokenModel
  static func fromTokenModel(_ tokenModel: TokenModel?) -> RNTokenModel? {
    guard let tokenModel else {
      return nil
    }
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
