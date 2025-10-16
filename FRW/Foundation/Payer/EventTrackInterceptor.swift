//
//  EventTrackInterceptor.swift
//  FRW
//
//  Created by lmcmz on 2025/10/07.
//

import Foundation
import Flow

final class EventTrackInterceptor: FlowTransactionResponseInterceptor, FlowTransactionErrorInterceptor {
    func onResponse(context: FlowTxContext) {
        guard context.phase == .response,
              let cadence = context.cadenceHash,
              let txId = context.txId?.hex,
              let authorizers = context.authorizers?.map({ $0.hex }),
              let proposer = context.proposer?.hex,
              let payer = context.payer?.hex
        else { return }

        EventTrack.Transaction.flowSigned(
            cadence: cadence,
            txId: txId,
            authorizers: authorizers,
            proposer: proposer,
            payer: payer,
            success: true
        )
    }

    func onError(error: Error, context: FlowTxContext) async -> FlowTxDecision? {
        guard context.phase == .error,
              let cadence = context.cadenceHash,
              let payer = context.payer?.hex,
              let authorizers = context.authorizers?.map({ $0.hex })
        else { return nil }

        EventTrack.General.rpcError(
            error: error.localizedDescription,
            scriptId: context.funcName
        )
        EventTrack.Transaction.flowSigned(
            cadence: cadence,
            txId: "",
            authorizers: authorizers,
            proposer: context.from.hex,
            payer: payer,
            success: false
        )
        return nil
    }
}
