//
//  TokenModel+Action.swift
//  FRW
//
//  Created by cat on 12/22/25.
//

import Foundation


extension TokenModel {
  func swapUrl() -> String {
    if typeValue == .cadence {
      return FlowSwapUrl()
    } else {
      return EVMSwapUrl()
    }
  }

  private func EVMSwapUrl() -> String {
    guard let contractAddress else {
      return AppUrl.evmSwapUrl
    }
    return "https://swap.flow.com/aggregator?chain=flow&inputCurrency=\(contractAddress)&outputCurrency=NATIVE"
  }

  private func FlowSwapUrl() -> String {
    guard let identifier else {
      return AppUrl.cadenceSwapUrl
    }
    return "https://app.increment.fi/swap?in=\(identifier)&out="
  }
}
