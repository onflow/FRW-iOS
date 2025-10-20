//
//  Payer429Interceptor.swift
//  FRW
//
//  Created by lmcmz on 2025/10/07.
//

import Flow
import Foundation
import SwiftUI

final class Payer429Interceptor: FlowTransactionErrorInterceptor {
  // MARK: Internal

  func onError(error: Error, context: FlowTxContext) async -> FlowTxDecision? {
    // Only handle HTTP 429-like errors
    if error.moyaCode() == 429 || error.localizedDescription.contains("429") {
      if let payerStatusData: PayerStatusData = try? await Network
        .request(FRWWebEndpoint.payerStatus) {
        let shouldRetry = await promptRetry(data: payerStatusData)
        if shouldRetry {
          // Retry by switching to self-payer and only user signer
          let overrides = FlowTxOverrides(
            payer: context.from
          )
          return .retry(overrides)
        } else {
          return .noRetry
        }

      } else {
        return .noRetry
      }
    }

    return nil
  }

  // MARK: Private

  private func promptRetry(data: PayerStatusData) async -> Bool {
    let multiplierValue = data.surge?.multiplier?.doubleValue ?? 0
    let maxFee = data.surge?.maxFee ?? 0
    let amount = maxFee
    let multiDisplay = multiplierValue.truncatingRemainder(dividingBy: 1) == 0
      ? String(Int(multiplierValue))
      : String(format: "%.1f", multiplierValue)
    return await AlertCenter.shared.presentSurgePricingConfirmation(
      feeAmount: String(format: "%.3f", amount),
      networkDescription: "Due to high network activity, transaction fees are elevated, and Flow Wallet is temporarily not paying for your gas. Current network fees are \(multiDisplay)× higher than usual."
    )
  }
}
