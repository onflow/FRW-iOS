//
//  WalletAccount+Helper.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import Foundation

// MARK: - Equatable Conformance

extension RNBridge.EmojiInfo: Equatable {
  public static func == (lhs: RNBridge.EmojiInfo, rhs: RNBridge.EmojiInfo) -> Bool {
    lhs.emoji == rhs.emoji &&
    lhs.name == rhs.name &&
    lhs.color == rhs.color
  }
}

extension RNBridge.WalletAccount: Equatable {
  public static func == (lhs: RNBridge.WalletAccount, rhs: RNBridge.WalletAccount) -> Bool {
    lhs.id == rhs.id &&
    lhs.name == rhs.name &&
    lhs.address == rhs.address &&
    lhs.emojiInfo == rhs.emojiInfo &&
    lhs.parentEmoji == rhs.parentEmoji &&
    lhs.parentAddress == rhs.parentAddress &&
    lhs.avatar == rhs.avatar &&
    lhs.type == rhs.type &&
    lhs.balance == rhs.balance &&
    lhs.nfts == rhs.nfts
  }
}

// MARK: - Helper Extensions

extension RNBridge.WalletAccount {

  func copyWith(flow: String? = nil, nft: String? = nil) -> RNBridge.WalletAccount {
    RNBridge.WalletAccount(
      id: self.id,
      name: self.name,
      address: self.address,
      emojiInfo: self.emojiInfo,
      parentEmoji: self.parentEmoji,
      parentAddress: self.parentAddress,
      avatar: self.avatar,
      isActive: false,
      type: self.type,
      balance: flow ?? self.balance,
      nfts: nft ?? self.nfts
    )
  }

  func updatedFromEmoji(userId: String? = nil) -> RNBridge.WalletAccount {
    let addr = address.addHexPrefix()
    let user = WalletUser.get(address: addr, userId: userId)
    return RNBridge.WalletAccount(
      id: self.id, // Preserve original ID instead of generating new UUID
      name: user.name,
      address: addr,
      emojiInfo: user.toRNEmoji(),
      parentEmoji: parentEmoji,
      parentAddress: parentAddress,
      avatar: avatar,
      isActive: false,
      type: type,
      balance: balance,
      nfts: nfts
    )
  }
}

extension RNBridge.WalletAccount {
  var FWAccountType: FWAccount.AccountType {
    switch self.type {
    case .main:
      return .main
    case .child:
      return .child
    case .evm:
      return .coa
    case .eoa:
      return .eoa
    case .none:
      return .main
    }
  }


  var isHidden: Bool {
    guard type == .evm else {
      return false
    }
    if let value = balance?.doubleValue, value > 0 {
      return false
    }
    if let value = nfts?.doubleValue, value > 0 {
      return false
    }
    return true
  }

  var displayBalance: String {
    guard let balance else {
      return "0.0 Flow"
    }
    return balance.doubleValue.formatDisplayFlowBalance
  }
  /// Indicates whether the COA account's asset data is ready.
  /// Returns `true` when both balance and NFT data have been loaded.
  var coaAssetsIsReady: Bool {
    balance != nil && nfts != nil
  }
}
