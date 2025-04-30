//
//  WalletConnectEVMHandler.swift
//  FRW
//
//  Created by cat on 2024/4/16.
//

import BigInt
import Flow
import Foundation
import ReownRouter
import ReownWalletKit
import WalletConnectSign
import Web3Core
import web3swift

// MARK: - WalletConnectEVMMethod

enum WalletConnectEVMMethod: String, Codable, CaseIterable {
    case personalSign = "personal_sign"
    case sendTransaction = "eth_sendTransaction"
    case requestAccounts = "eth_requestAccounts"
    case signTypedData = "eth_signTypedData"
    case signTypedDataV3 = "eth_signTypedData_v3"
    case signTypedDataV4 = "eth_signTypedData_v4"
    case switchEthereumChain = "wallet_switchEthereumChain"
    case watchAsset = "wallet_watchAsset"
}

extension Flow.ChainID {
    var evmChainID: Int? {
        switch self {
        case .mainnet:
            return 747
        case .testnet:
            return 545
        case .previewnet:
            return 646
        default:
            return nil
        }
    }

    var evmChainIDString: String? {
        evmChainID.map(String.init)
    }
}

// MARK: - WalletConnectEVMHandler

struct WalletConnectEVMHandler: WalletConnectChildHandlerProtocol {
    var supportNetwork: [Flow.ChainID] {
        [currentNetwork.toFlowType()]
    }

    var type: WalletConnectHandlerType {
        .evm
    }

    var nameTag: String {
        "eip155"
    }

    var suppportEVMChainID: [String] {
        supportNetwork.compactMap { $0.evmChainID }.map { String($0) }
    }

    func chainId(sessionProposal: Session.Proposal) -> Flow.ChainID? {
        var reference: String?
        if let chains = sessionProposal.requiredNamespaces[nameTag]?.chains {
            reference = chains.first(where: { $0.namespace == nameTag })?.reference
        }
        if let chains = sessionProposal.optionalNamespaces?[nameTag]?.chains {
            reference = chains
                .filter { $0.namespace == nameTag && suppportEVMChainID.contains($0.reference) }
                .compactMap { $0.reference }.sorted().last
        }
        switch reference {
        case "747":
            return .mainnet
        case "545":
            return .testnet
        default:
            return .unknown
        }
    }

    func approveProposalNamespace(
        required: ProposalNamespace?,
        optional: ProposalNamespace?
    ) throws -> SessionNamespace? {
        // Ensure we have an account available.
        guard let account = EVMAccountManager.shared.accounts.first?.address.addHexPrefix() else {
            return nil
        }

        // Get the supported EVM methods from your enum.
        let supportedMethods = WalletConnectEVMMethod.allCases.map { $0.rawValue }
        // Optionally, if you want to filter methods based on the request, you can do:
        let requestedMethods = (required?.methods ?? Set()).union(optional?.methods ?? Set())
        // Approve only the intersection (i.e. methods we both support and are requested).
        let approvedMethods = requestedMethods.intersection(Set(supportedMethods))

        // For events, we use the union of requested events.
        let approvedEvents = (required?.events ?? Set()).union(optional?.events ?? Set())

        // --- Filtering Supported Chains ---
        // Assume that ProposalNamespace now includes a `chains` property (Set<String>)
        // where each chain is identified in the format "eip155:<chainID>".
        let requestedChains = Set((required?.chains ?? []) + (optional?.chains ?? []))

        // Determine all supported chains based on your supportNetwork collection.
        let allSupportedChains = supportNetwork
            .compactMap { $0.evmChainIDString } // e.g. "1", "137", etc.
            .compactMap { chainID in
                // Create a Blockchain object using the namespace tag and chain reference.
                Blockchain(namespace: nameTag, reference: chainID)
            }

        // Filter the supported chains to only those that match a chain in the proposal.
        // We assume each Blockchain instance can provide an identifier in the form "eip155:<chainID>".
        let filteredChains = allSupportedChains.filter { blockchain in
            requestedChains.contains(blockchain)
        }

        // Map each approved blockchain to an account (using the same account address for all).
        let supportedAccounts = filteredChains.compactMap { chain in
            WalletConnectSign.Account(blockchain: chain, address: account)
        }

        // Build the approved session namespace with the filtered accounts, methods, and events.
        let sessionNamespace = SessionNamespace(
            chains: filteredChains,
            accounts: supportedAccounts,
            methods: approvedMethods,
            events: approvedEvents
        )

        return sessionNamespace
    }

    func handlePersonalSignRequest(
        request: Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        guard let data = message(sessionRequest: request) else {
            cancel()
            return
        }
        let title = request.name ?? ""
        let url = request.dappURL?.absoluteString ?? ""
        let logo = request.logoURL?.absoluteString ?? ""

        let vm = BrowserSignMessageViewModel(
            title: title,
            url: url,
            logo: logo,
            cadence: data.hexString
        ) { result in
            if result {
                guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
                    HUD.error(title: "invalid_address".localized)
                    cancel()
                    return
                }

                let address = Flow.Address(hex: addrStr)
                guard let hashedData = Utilities.hashPersonalMessage(data) else { return }
                let joinData = Flow.DomainTag.user.normalize + hashedData
                guard let sig = signWithMessage(data: joinData) else {
                    HUD.error(title: "sign failed")
                    cancel()
                    return
                }
                let keyIndex = BigUInt(WalletManager.shared.keyIndex)
                let proof = COAOwnershipProof(
                    keyIninces: [keyIndex],
                    address: address.data,
                    capabilityPath: "evm",
                    signatures: [sig]
                )
                guard let encoded = RLP.encode(proof.rlpList) else {
                    cancel()
                    return
                }
                confirm(encoded.hexString.addHexPrefix())
            } else {
                cancel()
            }
        }

        Router.route(to: RouteMap.Explore.signMessage(vm))
    }

    func handleSendTransactionRequest(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        let title = request.name ?? ""
        let url = request.dappURL?.absoluteString ?? ""
        let logo = request.logoURL?.absoluteString ?? ""

        let originCadence = CadenceManager.shared.current.evm?.callContractV2?.toFunc() ?? ""

        do {
            let result = try request.params.get([EVMTransactionReceive].self)
            guard let receiveModel = result.first, let toAddr = receiveModel.toAddress else {
                cancel()
                return
            }

            let args: [Flow.Cadence.FValue] = [
                .string(toAddr),
                .uint256(receiveModel.amount),
                receiveModel.dataValue?.cadenceValue ?? .array([]),
                .uint64(receiveModel.gasIntValue),
            ]

            let vm = BrowserAuthzViewModel(
                title: title,
                url: url,
                logo: logo,
                cadence: originCadence,
                arguments: args.toArguments()
            ) { result in
                if !result {
                    cancel()
                    return
                }
                Task {
                    let txid = try await FlowNetwork.sendTransaction(
                        amount: receiveModel.amount,
                        data: receiveModel.dataValue,
                        toAddress: toAddr,
                        gas: receiveModel.gasIntValue
                    )
                    let holder = TransactionManager.TransactionHolder(id: txid, type: .transferCoin)
                    TransactionManager.shared.newTransaction(holder: holder)

                    let calculateId = try await WalletConnectEVMHandler.calculateTX(
                        receiveModel,
                        txId: txid
                    )

                    log.info("[EVM] calculate TX id: \(calculateId)")
                    await MainActor.run {
                        confirm(calculateId.addHexPrefix())
                    }
                    EventTrack.Transaction
                        .evmSigned(
                            txId: txid.hex,
                            success: true
                        )
                }
            }

            Router.route(to: RouteMap.Explore.authz(vm))
        } catch {
            log.error("[EVM] send transaction failed \(error)", context: error)
            cancel()
        }
    }

    func handleSignTypedDataV4(
        request: WalletConnectSign.Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        let title = request.name ?? ""
        let url = request.dappURL?.absoluteString ?? ""
        let logo = request.logoURL?.absoluteString ?? ""

        do {
            let list = try request.params.get([String].self)
            let evmAddress = EVMAccountManager.shared.accounts.first?.showAddress.lowercased()

            if list.count != 2 {
                cancel()
                return
            }

            var dataStr = ""
            if list[0].lowercased() == evmAddress {
                dataStr = list[1]
            } else {
                dataStr = list[0]
            }

            let vm = BrowserSignTypedMessageViewModel(
                title: title,
                urlString: url,
                logo: logo,
                rawString: dataStr
            ) { result in

                if result {
                    do {
                        guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
                            HUD.error(title: "invalid_address".localized)
                            return
                        }
                        let address = Flow.Address(hex: addrStr)
                        let eip712Payload = try EIP712Parser.parse(dataStr)
                        let data = try eip712Payload.signHash()
                        let joinData = Flow.DomainTag.user.normalize + data
                        guard let sig = signWithMessage(data: joinData) else {
                            HUD.error(title: "sign failed")
                            return
                        }
                        let keyIndex = BigUInt(WalletManager.shared.keyIndex)
                        let proof = COAOwnershipProof(
                            keyIninces: [keyIndex],
                            address: address.data,
                            capabilityPath: "evm",
                            signatures: [sig]
                        )
                        guard let encoded = RLP.encode(proof.rlpList) else {
                            return
                        }
                        confirm(encoded.hexString.addHexPrefix())
                    } catch {
                        cancel()
                    }

                } else {
                    cancel()
                }
            }

            Router.route(to: RouteMap.Explore.signTypedMessage(vm))

        } catch {
            log.error("[EVM] handleSignTypedDataV4 \(error)", context: error)
            cancel()
        }
    }

    func handleWatchAsset(
        request: Request,
        confirm: @escaping (String) -> Void,
        cancel: @escaping () -> Void
    ) {
        guard let model = try? request.params.get(WalletConnectEVMHandler.WatchAsset.self),
              let address = model.options?.address
        else {
            cancel()
            return
        }
        Task {
            HUD.loading()
            let manager = WalletManager.shared.customTokenManager
            guard let token = try await manager.findToken(evmAddress: address) else {
                HUD.dismissLoading()
                DispatchQueue.main.async {
                    confirm("false")
                }
                return
            }
            HUD.dismissLoading()
            let callback: BoolClosure = { result in
                DispatchQueue.main.async {
                    confirm(result ? "true" : "false")
                }
            }
            Router.route(to: RouteMap.Wallet.addTokenSheet(token, callback))
        }
    }
}

extension WalletConnectEVMHandler {
    private func message(sessionRequest: Request) -> Data? {
        let message = try? sessionRequest.params.get([String].self)
        let decryptedMessage = message.map { Data(hex: $0.first ?? "") }
        return decryptedMessage
    }

    private func signWithMessage(data: Data) -> Data? {
        WalletManager.shared.signSync(signableData: data)
    }
}

// MARK: WalletConnectEVMHandler.WatchAsset

extension WalletConnectEVMHandler {
    private struct WatchAsset: Codable {
        struct Info: Codable {
            let address: String?
        }

        let options: WatchAsset.Info?
        let type: String?

        var isERC20: Bool {
            type?.lowercased() == "ERC20".lowercased()
        }
    }
}

// MARK: Decoded Data

extension WalletConnectEVMHandler {
    static func calculateTX(_ model: EVMTransactionReceive, txId: Flow.ID) async throws -> String {
        guard let myCoaAddress = EVMAccountManager.shared.accounts.first?.showAddress else {
            return ""
        }
        var result = await WalletConnectEVMHandler.calculateTXByCadence(model, from: myCoaAddress)
        if result == nil {
            log.warning("[EVM] calculate failed by cadence ")
            result = try await calculateTXByRPC(txid: txId)
        }
        if result == nil {
            log.warning("[EVM] calculate failed by Event")
        }
        return result ?? ""
    }

    private static func calculateTXByCadence(
        _ model: EVMTransactionReceive,
        from address: String
    ) async -> String? {
        guard let toAddress = model.toAddress,
              let toAddr = EthereumAddress(toAddress.addHexPrefix())
        else {
            log.info("[Cadence] empty address")
            return nil
        }
        guard let nonce = try? await FlowNetwork.getNonce(hexAddress: address) else {
            log.info("[Cadence] fetch nonce failed")
            return nil
        }

        let chainId = LocalUserDefaults.shared.flowNetwork.networkID
        let evmGasPrice = 0
        let directCallTxType = 255
        let contractCallSubType = 5

        let tx = CodableTransaction(
            type: .legacy,
            to: toAddr,
            nonce: BigUInt(nonce),
            chainID: BigUInt(chainId),
            value: model.bigAmount,
            data: model.dataValue ?? Data(),
            gasLimit: model.gasValue,
            gasPrice: BigUInt(evmGasPrice),
            v: BigUInt(directCallTxType),
            r: BigUInt(address.stripHexPrefix(), radix: 16)!,
            s: BigUInt(contractCallSubType)
        )
        return tx.hash?.hexValue
    }

    private static func calculateTXByRPC(txid: Flow.ID) async throws -> String? {
        guard let result = try? await txid.onceSealed() else {
            log.info("[Cadence] transation failed.")
            return nil
        }
        if result.isFailed {
            throw CadenceError.transactionFailed
        }
        let model = try? await FlowNetwork.fetchEVMTransactionResult(txid: txid.hex)
        return model?.hashString?.addHexPrefix()
    }
}
