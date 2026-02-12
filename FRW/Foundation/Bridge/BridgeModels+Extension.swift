//
//  BridgeModels+Extension.swift
//  FRW
//
//  Created by cat on 2/4/26.
//

extension RNBridge {
  struct TransactionDatas: Codable {
      let addresses: [String]
      let values: [String]
      let datas: [[Int]]
  }

  struct Erc20Asset: Codable {
      let address: String
      let amount: String
  }

  struct Erc721Asset: Codable {
      let address: String
      let id: String
  }

  struct Erc1155Asset: Codable {
      let address: String
      let id: String
      let amount: String
  }

  struct MigrationAssetsData: Codable {
      let erc20: [Erc20Asset]
      let erc721: [Erc721Asset]
      let erc1155: [Erc1155Asset]
  }
}
