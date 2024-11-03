//
//  WalletConnectEVMHandler.swift
//  FRW
//
//  Created by cat on 2024/4/16.
//

import BigInt
import Flow
import Foundation
import WalletConnectRouter
import WalletConnectSign
import Web3Core
import web3swift
import Web3Wallet

enum WalletConnectEVMMethod: String, Codable, CaseIterable {
    case personalSign = "personal_sign"
    case sendTransaction = "eth_sendTransaction"
    case requestAccounts = "eth_requestAccounts"
    case signTypedData = "eth_signTypedData"
    case signTypedDataV3 = "eth_signTypedData_v3"
    case signTypedDataV4 = "eth_signTypedData_v4"
    case switchEthereumChain = "wallet_switchEthereumChain"
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

struct WalletConnectEVMHandler: WalletConnectChildHandlerProtocol {
    var type: WalletConnectHandlerType {
        return .evm
    }

    var nameTag: String {
        return "eip155"
    }

    let supportNetwork: [Flow.ChainID] = [.mainnet, .testnet]

    var suppportEVMChainID: [String] {
        supportNetwork.compactMap { $0.evmChainID }.map { String($0) }
    }

    func chainId(sessionProposal: Session.Proposal) -> Flow.ChainID? {
        var reference: String?
        if let chains = sessionProposal.requiredNamespaces[nameTag]?.chains {
            reference = chains.first(where: { $0.namespace == nameTag })?.reference
        }
        if let chains = sessionProposal.optionalNamespaces?[nameTag]?.chains {
            reference = chains.filter { $0.namespace == nameTag && suppportEVMChainID.contains($0.reference) }.compactMap { $0.reference }.sorted().last
        }
        switch reference {
        case "646":
            return .previewnet
        case "747":
            return .mainnet
        case "545":
            return .testnet
        default:
            return .unknown
        }
    }

    func approveSessionNamespaces(sessionProposal: Session.Proposal) throws -> [String: SessionNamespace] {
        guard let account = EVMAccountManager.shared.accounts.first?.address.addHexPrefix() else {
            return [:]
        }
        // Following properties are used to support all the required and optional namespaces for the testing purposes
        let supportedMethods = WalletConnectEVMMethod.allCases.map(\.rawValue)
        let supportedEvents = Set(sessionProposal.requiredNamespaces.flatMap { $0.value.events } + (sessionProposal.optionalNamespaces?.flatMap { $0.value.events } ?? []))

        let supportedChains = supportNetwork.compactMap(\.evmChainIDString).compactMap { Blockchain(namespace: nameTag, reference: $0) }

        let supportedAccounts = Array(supportedChains).map { WalletConnectSign.Account(blockchain: $0, address: account)! }

        let sessionNamespaces: [String: SessionNamespace] = try AutoNamespaces.build(
            sessionProposal: sessionProposal,
            chains: Array(supportedChains),
            methods: supportedMethods,
            events: Array(supportedEvents),
            accounts: supportedAccounts
        )
        return sessionNamespaces
    }

    func handlePersonalSignRequest(request: Request, confirm: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        guard let data = message(sessionRequest: request) else {
            cancel()
            return
        }
        let pair = try? Pair.instance.getPairing(for: request.topic)
        let title = pair?.peer?.name ?? "unknown"
        let url = pair?.peer?.url ?? "unknown"
        let logo = pair?.peer?.icons.first
        let vm = BrowserSignMessageViewModel(title: title,
                                             url: url,
                                             logo: logo,
                                             cadence: data.hexString) { result in
            if result {
                guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
                    HUD.error(title: "invalid_address".localized)
                    return
                }

                let address = Flow.Address(hex: addrStr)
                guard let hashedData = Utilities.hashPersonalMessage(data) else { return }
                let joinData = Flow.DomainTag.user.normalize + hashedData
                guard let sig = signWithMessage(data: joinData) else {
                    HUD.error(title: "sign failed")
                    return
                }
                let keyIndex = BigUInt(WalletManager.shared.keyIndex)
                let proof = COAOwnershipProof(keyIninces: [keyIndex], address: address.data, capabilityPath: "evm", signatures: [sig])
                guard let encoded = RLP.encode(proof.rlpList) else {
                    return
                }
                confirm(encoded.hexString.addHexPrefix())
            } else {
                cancel()
            }
        }

        Router.route(to: RouteMap.Explore.signMessage(vm))
    }

    func handleSendTransactionRequest(request: WalletConnectSign.Request, confirm: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        let pair = try? Pair.instance.getPairing(for: request.topic)
        let title = pair?.peer?.name ?? "unknown"
        let url = pair?.peer?.url ?? "unknown"
        let logo = pair?.peer?.icons.first

        let originCadence = CadenceManager.shared.current.evm?.callContract?.toFunc() ?? ""

        do {
            let result = try request.params.get([EVMTransactionReceive].self)
            guard let receiveModel = result.first, let toAddr = receiveModel.toAddress else {
                cancel()
                return
            }

            let args: [Flow.Cadence.FValue] = [
                .string(toAddr),
                .ufix64(Decimal(string: receiveModel.amount) ?? .nan),
                receiveModel.dataValue?.cadenceValue ?? .array([]),
                .uint64(receiveModel.gasValue),
            ]

            let vm = BrowserAuthzViewModel(title: title,
                                           url: url,
                                           logo: logo,
                                           cadence: originCadence,
                                           arguments: args.toArguments()) { result in
                Task {
                    if !result {
                        cancel()
                    }

                    let txid = try await FlowNetwork.sendTransaction(amount: receiveModel.amount, data: receiveModel.dataValue, toAddress: toAddr, gas: receiveModel.gasValue)
                    let holder = TransactionManager.TransactionHolder(id: txid, type: .transferCoin)
                    TransactionManager.shared.newTransaction(holder: holder)
                    let tixResult = try await txid.onceSealed()
                    if tixResult.isFailed {
                        HUD.error(title: "transaction failed")
                        cancel()
                        return
                    }
                    let model = try await FlowNetwork.fetchEVMTransactionResult(txid: txid.hex)
                    DispatchQueue.main.async {
                        confirm(model.hashString?.addHexPrefix() ?? "")
                    }
                }
            }

            Router.route(to: RouteMap.Explore.authz(vm))
        } catch {
            log.error("[EVM] send transaction failed \(error)", context: error)
            cancel()
        }
    }
    
    func handleSignTypedDataV4(request: WalletConnectSign.Request, confirm: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        let pair = try? Pair.instance.getPairing(for: request.topic)
        let title = pair?.peer?.name ?? "unknown"
        let url = pair?.peer?.url ?? "unknown"
        let logo = pair?.peer?.icons.first
        
        do {
            let list = try request.params.get([String].self)
            let evmAddress = EVMAccountManager.shared.accounts.first?.showAddress.lowercased()
            
            if list.count != 2 {
                cancel()
                return
            }
            
            var dataStr: String = ""
            if list[0].lowercased() == evmAddress {
                dataStr = list[1]
            }else {
                dataStr = list[0]
            }
            
            let vm = BrowserSignTypedMessageViewModel(title: title, urlString: url, logo: logo, rawString: dataStr) { result in

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
                        let proof = COAOwnershipProof(keyIninces: [keyIndex], address: address.data, capabilityPath: "evm", signatures: [sig])
                        guard let encoded = RLP.encode(proof.rlpList) else {
                            return
                        }
                         confirm(encoded.hexString.addHexPrefix())
                    }catch {
                        cancel()
                    }
                    
                } else {
                    cancel()
                }
            }

            Router.route(to: RouteMap.Explore.signTypedMessage(vm))
            
        }catch {
            log.error("[EVM] handleSignTypedDataV4 \(error)", context: error)
            cancel()
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
        return WalletManager.shared.signSync(signableData: data)
    }
}
