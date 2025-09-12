//
//  NativeToRNModel.swift
//  FRW
//
//  Created by cat on 7/24/25.
//

import Foundation
import FlowWalletKit

extension FlowWalletKit.Account {
  func toWalletAccount() -> RNBridge.WalletAccount {
    let addr = address.hexAddr
    let user = WalletManager.shared.walletAccount.readInfo(at: addr)
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
      nfts: nil,
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
    parentAddress: String? = WalletManager.shared.mainAccount?
      .hexAddr
  ) -> RNBridge.WalletAccount {
    let addr = address.hexAddr
    var parentEmoji: RNBridge.EmojiInfo?
    if let parentAddress {
      let user = WalletManager.shared.walletAccount.readInfo(at: parentAddress)
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
      nfts: nil,
    )
  }
}

extension FlowWalletKit.COA {
  func toWalletAccount(
    parentAddress: String? = WalletManager.shared.mainAccount?
      .hexAddr
  ) -> RNBridge.WalletAccount {
    let addr = address.addHexPrefix()
    let user = WalletManager.shared.walletAccount.readInfo(at: addr)
    var parentEmoji: RNBridge.EmojiInfo?
    if let parentAddress {
      let parentUser = WalletManager.shared.walletAccount.readInfo(at: parentAddress)
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
      nfts: nil,
    )
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
