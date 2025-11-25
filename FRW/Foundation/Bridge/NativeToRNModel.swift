//
//  NativeToRNModel.swift
//  FRW
//
//  Created by cat on 7/24/25.
//

import Foundation
import FlowWalletKit

// MARK: - FlowWalletKit → Native WalletAccount Extensions
// Note: The primary FlowWalletKit → WalletAccount conversions have been moved to
// WalletAccount+FlowWalletKit.swift to maintain clean architecture separation.
// This file now focuses on RN-specific conversions.

// MARK: - Contact → RN Bridge

extension Contact {
  /// Convert internal Contact to RN bridge type
  func toRNContact() -> RNBridge.Contact {
    RNBridge.Contact(
      id: String(id),
      name: displayName,
      address: address ?? "",
      avatar: avatar,
      username: username,
      contactName: contactName
    )
  }
}

// MARK: - WalletUser → RN Bridge

extension WalletUser {
  /// Convert WalletUser emoji info to RN bridge type
  func toRNEmoji() -> RNBridge.EmojiInfo {
    .init(emoji: emoji.rawValue, name: emoji.name, color: emoji.colorHex)
  }
}
