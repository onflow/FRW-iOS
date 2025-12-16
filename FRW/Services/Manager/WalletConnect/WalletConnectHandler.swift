//
//  WalletConnectHandler.swift
//  FRW
//
//  Created by cat on 2024/4/16.
//

import Flow
import Foundation
import WalletConnectSign

// MARK: - WalletConnectHandler

// https://github.com/onflow/flow-evm-gateway?tab=readme-ov-file#evm-gateway-endpoints



struct WalletConnectHandler {
    // MARK: Internal
    
    enum HandlerError: Error {
        case chainIdMismatch
    }

    func isAllowedSession(sessionProposal: Session.Proposal) -> Bool {
        let namespaces = namespaceTag(sessionProposal: sessionProposal)
        let result = allowNamespaces.filter { namespaces.contains($0) }
        return !result.isEmpty
    }

    func sessionInfo(sessionProposal: Session.Proposal) -> SessionInfo {
        let appMetadata = sessionProposal.proposer
        let requiredNamespaces = sessionProposal.requiredNamespaces
        let info = SessionInfo(
            name: appMetadata.name,
            descriptionText: appMetadata.description,
            dappURL: appMetadata.url,
            iconURL: appMetadata.icons.first ?? ""
        )
        return info
    }

    func chainId(sessionProposal: Session.Proposal) -> Flow.ChainID? {
        let handlers = current(sessionProposal: sessionProposal)
        
        // Retrieve chain IDs if the corresponding handler exists
        let evmChainId = handlers[EVMHandler.nameTag]?.chainId(sessionProposal: sessionProposal)
        let flowChainId = handlers[flowHandler.nameTag]?.chainId(sessionProposal: sessionProposal)
        
        // If both handlers are present, verify that their chain IDs match.
        if let evmChainId = evmChainId, let flowChainId = flowChainId {
            if evmChainId != flowChainId {
                return nil
            }
            return evmChainId
        }
        
        // If only one handler exists, return its chain ID.
        return evmChainId ?? flowChainId
    }

    func approveSessionNamespaces(
        sessionProposal: Session.Proposal,
        EVMAddress: String? = nil
    ) throws -> [String: SessionNamespace] {
        var approvedNamespaces: [String: SessionNamespace] = [:]
        
        // Process EVM if present in either required or optional namespaces.
        let reqEvm = sessionProposal.requiredNamespaces[EVMHandler.nameTag]
        let optEvm = sessionProposal.optionalNamespaces?[EVMHandler.nameTag]
        if reqEvm != nil || optEvm != nil {
            if let evmNS = try EVMHandler.approveProposalNamespace(required: reqEvm, optional: optEvm, EVMAddress: EVMAddress) {
                approvedNamespaces[EVMHandler.nameTag] = evmNS
            }
        }
        
        // Process FCL if present in either required or optional namespaces.
        let reqFlow = sessionProposal.requiredNamespaces[flowHandler.nameTag]
        let optFlow = sessionProposal.optionalNamespaces?[flowHandler.nameTag]
        if reqFlow != nil || optFlow != nil {
            if let flowNS = try flowHandler.approveProposalNamespace(required: reqFlow, optional: optFlow, EVMAddress: nil) {
                approvedNamespaces[flowHandler.nameTag] = flowNS
            }
        }
        
        return approvedNamespaces
    }

    func currentTypes(sessionProposal: Session.Proposal) -> [WalletConnectHandlerType] {
        return current(sessionProposal: sessionProposal).map { $0.value.type }
    }

    func handlePersonalSignRequest(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        let handle = current(request: request)
        handle.handlePersonalSignRequest(request: request, confirm: confirm, cancel: cancel)
    }

    func handleSendTransactionRequest(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        let handle = current(request: request)
        handle.handleSendTransactionRequest(request: request, confirm: confirm, cancel: cancel)
    }

    func handleSignTypedDataV4(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        let handle = current(request: request)
        handle.handleSignTypedDataV4(request: request, confirm: confirm, cancel: cancel)
    }

    func handleWatchAsset(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        let handle = current(request: request)
        handle.handleWatchAsset(request: request, confirm: confirm, cancel: cancel)
    }

    // MARK: Private

    private let flowHandler = WalletConnectFlowHandler()
    private let EVMHandler = WalletConnectEVMHandler()

    private var allowNamespaces: [String] {
        [
            flowHandler.nameTag,
            EVMHandler.nameTag,
        ]
    }
    
    private func current(request: WalletConnectSign.Request) -> WalletConnectChildHandlerProtocol {
        let chainId = request.chainId
        if chainId.namespace.contains(EVMHandler.nameTag) {
            return EVMHandler
        }
        return flowHandler
    }
    
    private func current(sessionProposal: Session.Proposal) -> [String: WalletConnectChildHandlerProtocol] {
        let namespaces = namespaceTag(sessionProposal: sessionProposal)
        var result: [String: WalletConnectChildHandlerProtocol] = [:]
        if namespaces.contains(EVMHandler.nameTag) {
            result[EVMHandler.nameTag] = EVMHandler
        }
        if namespaces.contains(flowHandler.nameTag) {
            result[flowHandler.nameTag] = flowHandler
        }
        return result
    }
}

extension WalletConnectHandler {
    private func namespaceTag(sessionProposal: Session.Proposal) -> [String] {
        Array(sessionProposal.requiredNamespaces.keys) +
            Array((sessionProposal.optionalNamespaces ?? [:]).keys)
    }
}
