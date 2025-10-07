//
//  Payer429Interceptor.swift
//  FRW
//
//  Created by lmcmz on 2025/10/07.
//

import Flow
import Foundation
import UIKit

final class Payer429Interceptor: FlowTransactionErrorInterceptor {
    func onError(error: Error, context: FlowTxContext) async -> FlowTxDecision? {
        // Only handle HTTP 429-like errors
        if error.moyaCode() == 429 || error.localizedDescription.contains("429") {
            let shouldRetry = await promptRetry()
            if shouldRetry {
                // Retry by switching to self-payer and only user signer
                let overrides = FlowTxOverrides(
                    payer: context.from
                )
                return .retry(overrides)
            } else {
                return .noRetry
            }
        }

        return nil
    }

    private func promptRetry() async -> Bool {
        await withCheckedContinuation { continuation in
            runOnMain {
                let alert = UIAlertController(
                    title: "Service Busy",
                    message: "Free gas service is rate-limited. Retry and pay gas yourself?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                    continuation.resume(returning: false)
                }))
                alert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { _ in
                    continuation.resume(returning: true)
                }))
                Router.topPresentedController().present(alert, animated: true)
            }
        }
    }
}
