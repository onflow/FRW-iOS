//
//  TokenModel+Action.swift
//  FRW
//
//  Created by cat on 12/22/25.
//

import Foundation

extension TokenModel {
  func swapUrl() -> String {
    guard isFlowCoin else {
      return EVMSwapUrl()
    }
    return FlowSwapUrl()
  }

  private func EVMSwapUrl() -> String {
    guard let contractAddress else {
      return "https://swap.flow.com"
    }
    return "https://swap.flow.com/aggregator?chain=flow&inputCurrency=\(contractAddress)&outputCurrency=NATIVE"
  }

  private func FlowSwapUrl() -> String {
    guard let identifier else {
      return "https://app.increment.fi/swap"
    }
    return "https://app.increment.fi/swap?in=\(identifier)&out="
  }
}
