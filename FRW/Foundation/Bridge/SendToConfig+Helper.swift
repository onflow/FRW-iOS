//
//  SendToConfig+Helper.swift
//  FRW
//
//  Created by cat on 8/6/25.
//

import Foundation

extension RNBridge.SendToConfig {
  
  static func token(_ token: TokenModel) -> RNBridge.SendToConfig? {
    guard let currentAccount = getCurrentAccount() else {
      log.error("❌ No selected account found")
      return nil
    }
    return RNBridge.SendToConfig(
      selectedToken: RNTokenModel.fromTokenModel(token),
      fromAccount: currentAccount,
      transactionType: .tokens,
      selectedNFTs: nil,
      targetAddress: nil
    )
  }
  
  static func nft(_ nft: NFTModel) -> RNBridge.SendToConfig? {
    guard let currentAccount = getCurrentAccount(), let model = RNNFTModel.fromNFTModel(nft) else {
      log.error("❌ No selected account found")
      return nil
    }
    return RNBridge.SendToConfig(
      selectedToken: nil,
      fromAccount: currentAccount,
      transactionType: .singleNft,
      selectedNFTs: [model],
      targetAddress: nil
    )
  }

  static func nfts(_ nfts: [NFTModel]) -> RNBridge.SendToConfig? {
    guard let currentAccount = getCurrentAccount() ,
            let list = RNNFTModel.fromNFTModels(nfts) else {
      log.error("❌ No selected account found")
      return nil
    }
    return RNBridge.SendToConfig(
      selectedToken: nil,
      fromAccount: currentAccount,
      transactionType: .multipleNfts,
      selectedNFTs: list,
      targetAddress: nil
    )
  }

  static func targetAddress(_ address: String) -> RNBridge.SendToConfig? {
    guard let currentAccount = getCurrentAccount() else {
      log.error("❌ No selected account found")
      return nil
    }
    return RNBridge.SendToConfig(
      selectedToken: nil,
      fromAccount: currentAccount,
      transactionType: .targetAddress,
      selectedNFTs: nil,
      targetAddress: address
    )
  }
  
  //MARK: - current account for RN
  private static func getCurrentAccount() -> RNBridge.WalletAccount? {
      guard let selectedAccount = WalletManager.shared.selectedAccount else {
        log.error("❌ No selected account found")
          return nil
      }
      
      switch selectedAccount.type {
      case .main:
          // For main account, use the main account from WalletManager
          guard let mainAccount = WalletManager.shared.mainAccount else {
            log.error("❌ Main account not found")
              return nil
          }
          return mainAccount.toWalletAccount()
          
      case .child:
          // For child account, find the child account by address
          guard let childs = WalletManager.shared.childs,
                let childAccount = childs.first(where: { $0.address.hexAddr == selectedAccount.address.hexAddr }) else {
            log.error("❌ Child account not found for address: \(selectedAccount.address.hexAddr)")
              return nil
          }
          return childAccount.toWalletAccount()
          
      case .coa:
          // For EVM account (COA), use the COA account
          guard let coa = WalletManager.shared.coa else {
            log.error("❌ COA account not found")
              return nil
          }
          return coa.toWalletAccount()
      }
  }
}
