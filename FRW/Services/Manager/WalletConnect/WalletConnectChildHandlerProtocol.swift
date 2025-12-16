//
//  WalletConnectChildHandlerProtocol.swift
//  FRW
//
//  Created by cat on 2024/4/16.
//

import Flow
import Foundation
import WalletConnectSign

// MARK: - WalletConnectHandlerType

enum WalletConnectHandlerType {
    case flow, evm
}

// MARK: - WalletConnectChildHandlerProtocol

protocol WalletConnectChildHandlerProtocol {
    var type: WalletConnectHandlerType { get }
    var nameTag: String { get }
    func chainId(sessionProposal: Session.Proposal) -> Flow.ChainID?
    func approveProposalNamespace(required: ProposalNamespace?, optional: ProposalNamespace?, EVMAddress: String?) throws
        -> SessionNamespace?
    func handlePersonalSignRequest(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    )
    func handleSendTransactionRequest(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    )
    func handleSignTypedDataV4(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    )
    func handleWatchAsset(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    )
}
