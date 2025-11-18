//
//  WalletAccount+Helper.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import Foundation

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
      isActive: self.isActive,
      type: self.type,
      balance: flow ?? self.balance,
      nfts: nft ?? self.nfts
    )
  }

  func updatedFromEmoji(userId: String? = nil) -> RNBridge.WalletAccount {
    let addr = address.addHexPrefix()
    let user = WalletManager.shared.walletAccount.readInfo(at: addr, key: userId)
    return RNBridge.WalletAccount(
      id: UUID().uuidString,
      name: user.name,
      address: addr,
      emojiInfo: user.toRNEmoji(),
      parentEmoji: parentEmoji,
      parentAddress: parentAddress,
      avatar: avatar,
      isActive: isActive,
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
