//
//  WalletManager+WalletAccount.swift
//  FRW
//
//  Created by cat on 7/11/25.
//

import Foundation
import FlowWalletKit

// MARK: - Migration Notice
// The wallet account building methods have been moved to WalletAccount+FlowWalletKit.swift
// to support the new native WalletAccount type architecture.
//
// Old behavior: buildWalletAccounts() -> [[RNBridge.WalletAccount]]
// New behavior: buildWalletAccounts() -> [[WalletAccount]]
//
// For RN bridge communication, use .toRNBridge() extension method:
//   let accounts = try await wallet.buildWalletAccounts()
//   let rnAccounts = accounts.toRNBridge()
