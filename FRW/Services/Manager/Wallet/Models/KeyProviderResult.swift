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

  /// No provider found or all providers are revoked
  case noValidProvider(NoValidProviderReason)
}

/// Data returned when key provider is successfully validated
struct KeyProviderData {
  let provider: any KeyProtocol
  let accountKey: Flow.AccountKey
  let address: String
  let wallet: FlowWalletKit.Wallet
  let accounts: [FlowWalletKit.Account]
}

/// Reason why no valid provider was found
enum NoValidProviderReason {
  /// No keys exist at all for this UID
  case noKeys

  /// Keys exist but all are revoked on-chain
  case allKeysRevoked(revokedKeyIds: [String])

  /// Keys exist but failed to load (wrong password, corrupted keychain, etc.)
  case keysCorrupted

  var shouldShowAlert: Bool {
    switch self {
    case .noKeys, .allKeysRevoked:
      return true
    case .keysCorrupted:
      return true
    }
  }

  var alertReason: String {
    switch self {
    case .noKeys:
      return "No keys found for user"
    case .allKeysRevoked(let keyIds):
      return "All keys are revoked (keyIds: \(keyIds.joined(separator: ", ")))"
    case .keysCorrupted:
      return "Keys exist but failed to load"
    }
  }
}
