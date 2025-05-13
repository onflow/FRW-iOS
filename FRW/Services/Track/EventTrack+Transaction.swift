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
                "tx_id": txId,
                "authorizers": authorizers,
                "proposer": proposer,
                "payer": payer,
                "success": success,
            ])
    }

    static func evmSigned(txId: String, success: Bool) {
        guard let primaryAddress = WalletManager.shared.getPrimaryWalletAddress(),
              let evmAddress = WalletManager.shared.coa?.address.addHexPrefix()
        else {
            return
        }
        EventTrack
            .send(event: EventTrack.Transaction.evmSigned, properties: [
                "flow_address": primaryAddress,
                "evm_address": evmAddress,
                "tx_id": txId,
                "success": success,
            ])
    }

    static func ftTransfer(
        from: String,
        to: String,
        type: String,
        amount: Double,
        identifier: String
    ) {
        EventTrack
            .send(event: EventTrack.Transaction.FTTransfer, properties: [
                "from_address": from,
                "to_address": to,
                "type": type,
                "amount": amount,
                "ft_identifier": identifier,
            ])
    }

    static func NFTTransfer(
        from: String,
        to: String,
        identifier: String,
        txId: String,
        fromType: String,
        toType: String,
        isMove: Bool
    ) {
        EventTrack
            .send(event: EventTrack.Transaction.NFTTransfer, properties: [
                "from_address": from,
                "to_address": to,
                "nft_identifier": identifier,
                "tx_id": txId,
                "from_type": fromType,
                "to_type": toType,
                "isMove": isMove,
            ])
    }

    static func transactionResult(txId: String, successful: Bool, message: String? = nil) {
        EventTrack
            .send(event: EventTrack.Transaction.result, properties: [
                "tx_id": txId,
                "is_successful": successful,
                "error_message": message ?? "",
            ])
    }
}
