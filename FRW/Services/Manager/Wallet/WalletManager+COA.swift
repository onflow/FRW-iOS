//
//  WalletManager+COA.swift
//  FRW
//
//  Created by cat on 11/17/25.
//

import Foundation


//MARK: - Coa Enable

extension WalletManager {
  func enableCOA() async throws {
    guard let address = getPrimaryWalletAddress() else {
      throw EVMError.addressError
    }
    do {
        let tid = try await FlowNetwork.createEVM()
        let result = try await tid.onceSealed()
        if result.isFailed {
            log.error("[EVM] create EVM result: Failed")
            EventTrack.General
                .coaCreation(
                    txId: tid.description,
                    flowAddress: address,
                    message: result.errorMessage
                )
            throw EVMError.createAccount
        } else {
            EventTrack.General
                .coaCreation(
                    txId: tid.description,
                    flowAddress: address,
                    message: ""
                )
        }
    } catch {
        EventTrack.General
            .coaCreation(
                txId: "",
                flowAddress: address,
                message: error.localizedDescription
            )
        throw error
    }
  }
}

//MARK: -  fetch coa asset
struct AssetAmount {
  let address: String
  var flow: Decimal?
  var nft: Int?

  var hasAsset: Bool {
    if let flow, flow > 0 {
      return true
    }
    if let nft, nft > 0 {
      return true
    }
    return false
  }
}

extension WalletManager {
  func fetchCOAAsset(addresses: [String]) async throws -> [AssetAmount] {
    let handler = EVMTokenBalanceProvider(network: currentNetwork)

    // Fetch Flow balances
    let flowResult = try await handler.getAvailableFlowBalance(addresses: addresses)

    // Create initial result dictionary for O(1) lookups
    var resultDict: [String: AssetAmount] = flowResult.mapValues { value in
      AssetAmount(address: "", flow: value)
    }

    // Fetch NFT collections in parallel using TaskGroup
    try await withThrowingTaskGroup(of: (String, Int)?.self) { group in
      for addr in addresses {
        group.addTask {
          guard let fwaddr = FWAddressDector.create(address: addr) else {
            return nil
          }
          let nftResult = try await handler.getNFTCollections(address: fwaddr)
          return (addr, nftResult.count)
        }
      }

      // Collect results and update dictionary
      for try await result in group {
        if let (addr, nftCount) = result {
          if var asset = resultDict[addr] {
            asset.nft = nftCount
            resultDict[addr] = asset
          } else {
            resultDict[addr] = AssetAmount(address: addr, flow: nil, nft: nftCount)
          }
        }
      }
    }

    // Convert dictionary back to array with proper addresses
    return resultDict.map { (key, value) in
      AssetAmount(address: key, flow: value.flow, nft: value.nft)
    }
  }
}
