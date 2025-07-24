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
      return RNBridge.WalletAccount.init(
        id: UUID().uuidString,
        name: user.name,
        address: addr,
        emoji: user.emoji.rawValue,
        avatar: nil,
        isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
        isIncompatible: false,
        type: .main
      )
    }
}

extension FlowWalletKit.ChildAccount {
    func toWalletAccount() -> RNBridge.WalletAccount {
      let addr = address.hexAddr
      return RNBridge.WalletAccount(
        id: UUID().uuidString,
        name: name ?? "",
        address: addr,
        emoji: "",
        avatar: icon?.absoluteString,
        isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
        isIncompatible: false,
        type: .child
      )
    }
}

extension FlowWalletKit.COA {
    func toWalletAccount() -> RNBridge.WalletAccount {
      let addr = address.addHexPrefix()
      let user = WalletManager.shared.walletAccount.readInfo(at: addr)
      return RNBridge.WalletAccount(
        id: UUID().uuidString,
        name: user.name,
        address: addr,
        emoji: user.emoji.rawValue,
        avatar: nil,
        isActive: WalletManager.shared.selectedAccount?.address.hexAddr == addr,
        isIncompatible: false,
        type: .evm
      )
    }
}

extension Contact {
  func toRNContact() -> RNBridge.Contact {
    return RNBridge.Contact(
      id: String(id),
      name: displayName,
      address: address ?? "",
      avatar: avatar,
      username: username,
      contactName: contactName
    )
  }
}
