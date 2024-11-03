//
//  EventTrack+Transaction.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation

extension EventTrack.Transaction {
    
    /// cadence decode script ,then SHA256
    static func flowSigned(
        cadence: String,
        txId: String,
        authorizers: [String],
        proposer: String,
        payer: String,
        success: Bool
    ) {
        EventTrack
            .send(event: EventTrack.Transaction.flowSigned, properties: [
                "cadence": cadence,
                "id": txId,
                "authorizers": authorizers,
                "proposer": proposer,
                "payer": payer,
                "success": success
            ])
    }
    
    static func evmSigned(flowAddress: String, evmAddress: String, txId: String, success: Bool) {
        EventTrack
            .send(event: EventTrack.Transaction.flowSigned, properties: [
                "flow_address": flowAddress,
                "evm_address": evmAddress,
                "id": txId,
                "success": success
            ])
    }
    
    static func ftTransfer(
        from: String,
        to: String,
        type: String,
        amount: Double
        , identifier: String) {
            EventTrack
                .send(event: EventTrack.Transaction.FTTransfer, properties: [
                    "from_address": from,
                    "to_address": to,
                    "type": type,
                    "amount": amount,
                    "ft_identifier": identifier
                ])
    }
    
    static func NFTTransfer(
        from: String,
        to: String,
        type: String,
        amount: Double
        , identifier: String) {
            EventTrack
                .send(event: EventTrack.Transaction.FTTransfer, properties: [
                    "from_address": from,
                    "to_address": to,
                    "type": type,
                    "ft_identifier": identifier
                ])
        }
}
