//
//  WalletAccount+Helpers.swift
//  FRW
//
//  Created by cat on 11/20/25.
//

import Foundation

// MARK: - Native WalletAccount Helper Methods

extension WalletAccount {

  /// Creates a copy of the account with updated asset data
  /// - Parameters:
  ///   - balance: Optional new balance value
  ///   - nftCount: Optional new NFT count
  /// - Returns: New WalletAccount with updated assets
  func copyWith(balance: Double? = nil, nftCount: Int? = nil) -> WalletAccount {
    let currentBalance = assets.balance ?? 0
    let currentNFTCount = assets.nftCount ?? 0

    let newBalance = balance ?? currentBalance
    let newNFTCount = nftCount ?? currentNFTCount

    let newAssets: AssetData = .loaded(balance: newBalance, nftCount: newNFTCount)

    return WalletAccount(
      id: id,
      address: address,
      type: type,
      network: network,
      user: user,
      childInfo: childInfo,
      parent: parent,
      isActive: isActive,
      assets: newAssets
    )
  }

  /// Updates the account's display info from WalletUser emoji data
  /// - Parameter userId: Optional user ID. If nil, uses current user
  /// - Returns: New WalletAccount with updated emoji and name
  func updatedFromEmoji(userId: String? = nil) -> WalletAccount {
    let addr = address.addHexPrefix()
    let newUser = WalletUser.get(address: addr, userId: userId)

    return WalletAccount(
      id: id, // Preserve original ID
      address: addr,
      type: type,
      network: network,
      user: newUser,
      childInfo: childInfo,
      parent: parent,
      isActive: isActive,
      assets: assets
    )
  }

  /// Convert WalletAccount.AccountType to FWAccount.AccountType
  /// - Returns: FWAccount.AccountType for compatibility with legacy code
  var FWAccountType: FWAccount.AccountType {
    switch type {
    case .main:
      return .main
    case .child:
      return .child
    case .coa:
      return .coa
    case .eoa:
      return .eoa
    }
  }
}
