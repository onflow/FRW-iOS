//
//  WalletManager+EOA.swift
//  FRW
//
//  Created by cat on 10/27/25.
//

import Foundation
import Flow
import WalletCore

struct EOA {
  public var id: String {
      address
  }
  
  public var chainID: Flow.ChainID {
      network
  }
  
  public var address: String {
      hexAddr
  }
  
  private(set) var hexAddr: String
  private(set) var network: Flow.ChainID
  
  init?(_ address: String, network: Flow.ChainID = .mainnet) {
      guard let addr = AnyAddress(string: address.addHexPrefix(), coin: .ethereum) else {
          return nil
      }
      self.hexAddr = addr.description
      self.network = network
  }
}
