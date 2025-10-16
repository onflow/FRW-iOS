//
//  FlowTxInterception.swift
//  FRW
//
//  Created by lmcmz on 2025/10/07.
//

import Flow
import Foundation

// MARK: - Interceptor Protocols (Unified Context)

protocol FlowTransactionRequestInterceptor {
    func onRequest(context: FlowTxContext) async -> FlowTxOverrides?
}

protocol FlowTransactionResponseInterceptor {
    func onResponse(context: FlowTxContext)
}

protocol FlowTransactionErrorInterceptor {
    /// Return a decision for a given error and context. Return nil to ignore.
    func onError(error: Error, context: FlowTxContext) async -> FlowTxDecision?
}

// MARK: - FlowTxInterceptorCenter

final class FlowTxInterceptorCenter {
    static let shared = FlowTxInterceptorCenter()
    private init() {}

    var requestInterceptors: [FlowTransactionRequestInterceptor] = [
        DefaultPayerRequestInterceptor()
    ]
    var responseInterceptors: [FlowTransactionResponseInterceptor] = [
        EventTrackInterceptor()
    ]
    var errorInterceptors: [FlowTransactionErrorInterceptor] = [
        Payer429Interceptor(),
        EventTrackInterceptor()
    ]
}
