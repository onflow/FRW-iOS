//
//  KeyProviderResult.swift
//  FRW
//
//  Created by Claude on 2026/01/26.
//

import Flow
import FlowWalletKit
import Foundation

// MARK: - Key Provider Result Models

/// Result of finding a key provider with on-chain validation
enum KeyProviderResult {
  /// Successfully found a valid key with on-chain account
  case success(KeyProviderData)

  /// Provider exists but no on-chain account yet (async account creation in progress)
  case providerWithoutAccount(any KeyProtocol)

  /// No valid provider found - contains the specific WalletError
  case noValidProvider(WalletError)
}

/// Data returned when key provider is successfully validated
struct KeyProviderData {
  let provider: any KeyProtocol
  let accountKey: Flow.AccountKey
  let address: String
  let wallet: FlowWalletKit.Wallet
  let accounts: [FlowWalletKit.Account]
}
