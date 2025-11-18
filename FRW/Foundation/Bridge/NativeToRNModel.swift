//
//  NativeToRNModel.swift
//  FRW
//
//  Created by cat on 7/24/25.
//

import Foundation
import FlowWalletKit

extension FlowWalletKit.Account {
  func toWalletAccount(userId: String? = nil) -> RNBridge.WalletAccount {
    let addr = address.hexAddr
    let user = WalletManager.shared.walletAccount.readInfo(at: addr, key: userId)
    return RNBridge.WalletAccount(
      id: UUID().uuidString,
      name: user.name,
      address: addr,
      emojiInfo: user.toRNEmoji(),
      parentEmoji: nil,
      parentAddress: nil,
      avatar: nil,
      isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
      type: .main,
      balance: nil,
      nfts: nil
    )
  }

  func walletAccountUser() -> WalletAccount.User {
    let addr = address.hexAddr
    let user = WalletManager.shared.walletAccount.readInfo(at: addr)
    return user
  }
}

extension FlowWalletKit.ChildAccount {
  func toWalletAccount(
    parentAddress: String? = WalletManager.shared.mainAccount?.hexAddr,
    userId: String? = nil
  ) -> RNBridge.WalletAccount {
    let addr = address.hexAddr
    var parentEmoji: RNBridge.EmojiInfo?
    if let parentAddress {
      let user = WalletManager.shared.walletAccount.readInfo(at: parentAddress, key: userId)
      parentEmoji = user.toRNEmoji()
    }

    return RNBridge.WalletAccount(
      id: UUID().uuidString,
      name: name ?? "",
      address: addr,
      emojiInfo: nil,
      parentEmoji: parentEmoji,
      parentAddress: parentAddress,
      avatar: icon?.absoluteString,
      isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
      type: .child,
      balance: nil,
      nfts: nil
    )
  }
}

extension FlowWalletKit.COA {
  func toWalletAccount(
    parentAddress: String? = WalletManager.shared.mainAccount?
      .hexAddr,
    userId: String? = nil
  ) -> RNBridge.WalletAccount {
    let addr = address.addHexPrefix()
    let user = WalletManager.shared.walletAccount.readInfo(at: addr, key: userId)
    var parentEmoji: RNBridge.EmojiInfo?
    if let parentAddress {
      let parentUser = WalletManager.shared.walletAccount.readInfo(at: parentAddress, key: userId)
      parentEmoji = parentUser.toRNEmoji()
    }
    return RNBridge.WalletAccount(
      id: UUID().uuidString,
      name: user.name,
      address: addr,
      emojiInfo: user.toRNEmoji(),
      parentEmoji: parentEmoji,
      parentAddress: parentAddress,
      avatar: nil,
      isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
      type: .evm,
      balance: nil,
      nfts: nil
    )
  }
}

extension EOA {
  func toWalletAccount(
    parentAddress: String? = nil,
    userId: String? = nil
  ) -> RNBridge.WalletAccount {
    let addr = address.addHexPrefix()
    let user = WalletManager.shared.walletAccount.readInfo(at: addr, key: userId)
    
    return RNBridge.WalletAccount(
      id: UUID().uuidString,
      name: user.name,
      address: addr,
      emojiInfo: user.toRNEmoji(),
      parentEmoji: nil,
      parentAddress: parentAddress,
      avatar: nil,
      isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
      type: .eoa,
      balance: nil,
      nfts: nil
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
      if parentAddress == nil {
        return .eoa
      }
      return .coa
    case .eoa:
      return .eoa
    case .none:
      return .main
    }
  }
  
  func copyWith(flow: String? = nil, nft: String? = nil) -> RNBridge.WalletAccount {
    RNBridge.WalletAccount(
      id: self.id,
      name: self.name,
      address: self.address,
      emojiInfo: self.emojiInfo,
      parentEmoji: self.parentEmoji,
      parentAddress: self.parentAddress,
      avatar: self.avatar,
      isActive: self.isActive,
      type: self.type,
      balance: flow ?? self.balance,
      nfts: nft ?? self.nfts
    )
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

  /// Indicates whether the COA account's asset data is ready.
  /// Returns `true` when both balance and NFT data have been loaded.
  var coaAssetsIsReady: Bool {
    balance != nil && nfts != nil
  }
}
// MARK: Tool for RN Model

extension Contact {
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

extension WalletAccount.User {
  func toRNEmoji() -> RNBridge.EmojiInfo {
    .init(emoji: emoji.rawValue, name: emoji.name, color: emoji.colorHex)
  }
}
