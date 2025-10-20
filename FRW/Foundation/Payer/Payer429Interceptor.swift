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
    await AlertCenter.shared.presentSurge(data: data)
  }
}
