//
//  EventTrack+General.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation

extension EventTrack.General {
    
    
    static func rpcError(error: String, scriptId: String) {
        EventTrack.send(event: EventTrack.General.rpcError, properties: [
            "error": error,
            "script_id": scriptId
        ])
    }
    /// StakeAmountViewModel  stake
    static func delegationCreated(
        address: String,
        nodeId: String,
        amount: Double
    ) {
        EventTrack
            .send(event: EventTrack.General.delegationCreated, properties: [
                "address": address,
                "node_id": nodeId,
                "amount": amount
            ])
    }
    ///  BuyProvderView button action
    static func rampClick(source: String) {
        EventTrack
            .send(event: EventTrack.General.rampClicked, properties: [
                "source": source,
            ])
    }
    /// home page buy button clicked
    static func security(type: String) {
        EventTrack
            .send(event: EventTrack.General.securityTool, properties: [
                "type": type,
            ])
    }
}
