//
//  DefaultPayerRequestInterceptor.swift
//  FRW
//
//  Created by lmcmz on 2025/10/07.
//

import Flow
import Foundation

final class DefaultPayerRequestInterceptor: FlowTransactionRequestInterceptor {
    func onRequest(context: FlowTxContext) async -> FlowTxOverrides? {
        guard context.phase == .request,
              let defaultPayer = context.defaultPayer
        else { return nil }

        let freeGas = RemoteConfigManager.shared.freeGasEnabled
        let needBridgeFee = RemoteConfigManager.shared.coverBridgeFee && context.funcName.lowercased().hasSuffix("withpayer")

        var signers: [FlowSigner] = context.defaultSigners ?? [WalletManager.shared]
        if freeGas { signers.append(RemoteConfigManager.shared) }
        if needBridgeFee { signers.append(BridgeFeePayer()) }

        var authorizers: [Flow.Address] = context.authorizers ?? [context.from]
        if needBridgeFee { authorizers.append(Flow.Address(hex: RemoteConfigManager.shared.bridgeFeePayer)) }

        let payer: Flow.Address = {
            if needBridgeFee { return Flow.Address(hex: RemoteConfigManager.shared.bridgeFeePayer) }
            if freeGas { return Flow.Address(hex: RemoteConfigManager.shared.payer) }
            return defaultPayer
        }()

        return FlowTxOverrides(payer: payer, signers: signers, authorizers: authorizers)
    }
}
