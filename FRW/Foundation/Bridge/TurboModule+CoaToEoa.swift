//
//  TurboModule+CoaToEoa.swift
//  FRW
//
//  Created by cat on 2/9/26.
//

import Foundation

// fetch balance and nft count for coa
extension TurboModuleSwift {
  static func fetchAmountForCoa(address: String) async throws -> RNBridge.MigrationAssetsData? {

    guard let addr = FWAddressDector.create(address: address), addr.type == .evm  else {
      return nil
    }
    let evmProvider = TokenBalanceHandler()
    let tokenList = try await evmProvider.getFTBalance(address: addr)
    let collectionList = try await evmProvider.getNFTCollections(address: addr)

    let erc20: [RNBridge.Erc20Asset] = tokenList.compactMap { model in
      guard let addr = model.getAddress(), let amount = model.balanceInFLOW else {
        return nil
      }
      guard amount.count > 0, amount != "0" else {
        return nil
      }
      return RNBridge.Erc20Asset(address: addr, amount: amount)
    }

    let erc721: [RNBridge.Erc721Asset] = collectionList.flatMap { model -> [RNBridge.Erc721Asset] in
      let contractType = model.collection.ERCType
      guard contractType == .erc721 else {
        return []
      }
      guard let rawAddr = model.collection.evmAddress else {
        return []
      }
      let addr = rawAddr.addHexPrefix()
      guard addr.hasPrefix("0x"), let list = model.ids, !list.isEmpty else {
        return []
      }
      let assets: [RNBridge.Erc721Asset] = list.compactMap { nftId in
        let trimmed = nftId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
          return nil
        }
        return RNBridge.Erc721Asset(address: addr, id: trimmed)
      }
      return assets
    }

    let erc1155: [RNBridge.Erc1155Asset] = collectionList.flatMap { model -> [RNBridge.Erc1155Asset] in
      let contractType = model.collection.ERCType
      guard contractType == .erc1155 else {
        return []
      }
      guard let rawAddr = model.collection.evmAddress else {
        return []
      }
      let addr = rawAddr.addHexPrefix()
      guard addr.hasPrefix("0x"), let list = model.ids, !list.isEmpty else {
        return []
      }
      var orderedIds: [String] = []
      var counts: [String: Int] = [:]
      list.forEach { nftId in
        let trimmed = nftId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
          return
        }
        if counts[trimmed] == nil {
          orderedIds.append(trimmed)
          counts[trimmed] = 1
        } else {
          counts[trimmed, default: 0] += 1
        }
      }
      let assets: [RNBridge.Erc1155Asset] = orderedIds.compactMap { nftId -> RNBridge.Erc1155Asset? in
        guard let count = counts[nftId], count > 0 else {
          return nil
        }
        return RNBridge.Erc1155Asset(address: addr, id: nftId, amount: "\(count)")
      }
      return assets
    }

    let data = RNBridge.MigrationAssetsData(erc20: erc20, erc721: erc721, erc1155: erc1155)
    return data
  }
}
