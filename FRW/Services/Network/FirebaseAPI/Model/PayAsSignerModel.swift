//
//  PayAsSignerModel.swift
//  Flow Wallet
//
//  Created by Hao Fu on 8/9/2022.
//

import Flow
import Foundation

// MARK: - FCLVoucher

struct FCLVoucher: Codable {
    struct ProposalKey: Codable {
        let address: Flow.Address
        let keyId: Int
        let sequenceNum: UInt64
    }

    struct Signature: Codable {
        let address: Flow.Address
        let keyId: Int
        let sig: String
    }

    let cadence: Flow.Script
    let payer: Flow.Address
    let refBlock: Flow.ID
    let arguments: [Flow.Argument]
    let proposalKey: ProposalKey
    let computeLimit: UInt64
    let authorizers: [Flow.Address]
    let payloadSigs: [Signature]
}

// MARK: - SignPayerResponse

struct SignPayerResponse: Codable {
    let envelopeSigs: FCLVoucher.Signature
}

// MARK: - SignPayerRequest

struct SignPayerRequest: Codable {
    let message: PayerMessage
}

struct SignBridgePayerRequest: Codable {
    let message: PayerPayload
}

struct PayerPayload: Codable {
    let payload: String
}

// MARK: - PayerMessage

struct PayerMessage: Codable {
    let envelopeMessage: String
}

extension Flow.Transaction {
    var voucher: FCLVoucher {
        FCLVoucher(
            cadence: script,
            payer: payer,
            refBlock: referenceBlockId,
            arguments: arguments,
            proposalKey: FCLVoucher.ProposalKey(
                address: proposalKey.address,
                keyId: proposalKey.keyIndex,
                sequenceNum: UInt64(
                    proposalKey
                        .sequenceNumber
                )
            ),
            computeLimit: UInt64(gasLimit),
            authorizers: authorizers,
            payloadSigs: payloadSignatures.compactMap {
                FCLVoucher.Signature(
                    address: $0.address,
                    keyId: $0.keyIndex,
                    sig: $0.signature.hexValue
                )
            }
        )
    }
}
