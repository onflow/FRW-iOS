//
//  WalletConnectFlowHandler.swift
//  FRW
//
//  Created by cat on 2024/4/16.
//

import Flow
import Foundation
import WalletConnectSign

struct WalletConnectFlowHandler: WalletConnectChildHandlerProtocol {
    var type: WalletConnectHandlerType {
        .flow
    }

    var nameTag: String {
        "flow"
    }

    func chainId(sessionProposal: Session.Proposal) -> Flow.ChainID? {
        let requiredChains = sessionProposal.requiredNamespaces[nameTag]?.chains ?? []
        let optionalChains = sessionProposal.optionalNamespaces?[nameTag]?.chains ?? []
        let chains = requiredChains + optionalChains
        guard let reference = chains.first(where: { $0.namespace == nameTag })?.reference
        else {
            return nil
        }
        return Flow.ChainID(name: reference.lowercased())
    }

    func approveProposalNamespace(
        required: ProposalNamespace?,
        optional: ProposalNamespace?
    ) throws -> SessionNamespace? {
        guard let account = WalletManager.shared.getPrimaryWalletAddress() else {
            return nil
        }
        
        var sessionNamespace: SessionNamespace?
        
        // Combine non-nil proposals
        let proposals = [required, optional].compactMap { $0 }
        
        proposals.forEach { proposal in
            guard let chains = proposal.chains else { return }
            
            let proposalMethods = proposal.methods
            let proposalEvents = proposal.events
            
            chains.forEach { chain in
                let accountString = "\(chain.absoluteString):\(account)"
                guard let accountObj = WalletConnectSign.Account(accountString) else { return }
                
                if var ns = sessionNamespace {
                    // Append new account and chain, and intersect the methods and events.
                    ns.accounts.append(accountObj)
                    ns.chains = (ns.chains ?? []) + [chain]
                    ns.methods = ns.methods.intersection(proposalMethods)
                    ns.events = ns.events.intersection(proposalEvents)
                    sessionNamespace = ns
                } else {
                    // Create the namespace if it doesn't exist yet.
                    sessionNamespace = SessionNamespace(
                        chains: [chain],
                        accounts: [accountObj],
                        methods: proposalMethods,
                        events: proposalEvents
                    )
                }
            }
        }
        
        return sessionNamespace
    }

    func handlePersonalSignRequest(
        request _: Request,
        confirm _: @escaping (String) -> Void,
        cancel _: @escaping () -> Void
    ) {}

    func handleSendTransactionRequest(
        request _: WalletConnectSign.Request,
        confirm _: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        cancel()
    }

    func handleSignTypedDataV4(
        request _: Request,
        confirm _: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        cancel()
    }

    func handleWatchAsset(
        request _: Request,
        confirm _: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        cancel()
    }
}
