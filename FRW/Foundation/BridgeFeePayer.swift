//
//  BridgeFeePayer.swift
//  FRW
//
//  Created by cat on 4/8/25.
//

import Flow
import Foundation

class BridgeFeePayer: FlowSigner {
    var address: Flow.Address {
        .init(hex: RemoteConfigManager.shared.bridgeFeePayer)
    }

    var hashAlgo: Flow.HashAlgorithm {
        .SHA2_256
    }

    var signatureAlgo: Flow.SignatureAlgorithm {
        .ECDSA_P256
    }

    var keyIndex: Int {
        RemoteConfigManager.shared.bridgeFeePayerId
    }

    func sign(transaction: Flow.Transaction, signableData: Data) async throws -> Data {
        let request = SignPayerRequest(
            transaction: transaction.voucher,
            message: .init(envelopeMessage: signableData.hexValue)
        )
        let signature: SignPayerResponse = try await Network
            .requestWithRawModel(FRWAPI.Cadence.signAsBridgeFeePayer(request))
        return Data(hex: signature.envelopeSigs.sig)
    }
}
