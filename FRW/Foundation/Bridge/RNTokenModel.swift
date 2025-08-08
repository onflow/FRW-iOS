//
//  RNTokenModel.swift
//  FRW
//
//  Created by Auto-generated on 2025-01-08.
//  Model that matches RN TokenInfo structure for cross-platform compatibility
//

import Foundation


// MARK: - Conversion from Native TokenModel

extension RNBridge.TokenModel {
  /// Convert from native TokenModel to RNTokenModel
  static func fromTokenModel(_ tokenModel: TokenModel?) -> RNBridge.TokenModel? {
    guard let tokenModel else {
      return nil
    }
    // Convert TokenModel.TokenType to RNWalletType
    let rnType: RNBridge.WalletType = tokenModel.typeValue == .cadence ? .flow : .evm

    // Convert FlowPath if exists
    let rnStoragePath = tokenModel.storagePath.map { flowPath in
      RNBridge.FlowPath(domain: flowPath.domain, identifier: flowPath.identifier)
    }
    let rnReceiverPath = tokenModel.receiverPath.map { flowPath in
      RNBridge.FlowPath(domain: flowPath.domain, identifier: flowPath.identifier)
    }
    let rnBalancePath = tokenModel.balancePath.map { flowPath in
      RNBridge.FlowPath(domain: flowPath.domain, identifier: flowPath.identifier)
    }

    return RNBridge.TokenModel(
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
