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

    func sign(signableData: Data, transaction: Flow.Transaction?) async throws -> Data {
        guard let transaction else {
            throw WalletError.emptyTransaction
        }
        
        let request = SignBridgePayerRequest(message: .init(payload: signableData.hexValue))
        let signature: FCLVoucher.Signature = try await Network
        .request(FRWWebEndpoint.signAsBridgePayer(request))
        return Data(hex: signature.sig)
    }
}
