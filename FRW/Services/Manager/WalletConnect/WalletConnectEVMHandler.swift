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
import WalletCore
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
//    case switchEthereumChain = "wallet_switchEthereumChain"
    case watchAsset = "wallet_watchAsset"
    case personalECRecover = "personal_ecRecover"
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
        [currentNetwork]
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
  
    private func currentIsCOA(address: String?) -> Bool {
      guard let address else {
        return true
      }
      return WalletManager.shared.coa?.address.lowercased() == address.lowercased()
    }

    func approveProposalNamespace(
        required: ProposalNamespace?,
        optional: ProposalNamespace?,
        EVMAddress: String? = nil
    ) throws -> SessionNamespace? {
        guard let account = EVMAddress else {
            log.error("[EVM] Cannot approve proposal without an EVM address.")
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
        let fromAddress = address(sessionRequest: request)
        let title = request.name ?? ""
        let url = request.dappURL?.absoluteString ?? ""
        let logo = request.logoURL?.absoluteString ?? ""

        let vm = BrowserSignMessageViewModel(
            title: title,
            url: url,
            logo: logo,
            cadence: data.hexString
        ) { result in
            Task {
                if result {
                  if currentIsCOA(address: fromAddress) {
                    guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
                        HUD.error(title: "invalid_address".localized)
                        cancel()
                        return
                    }
                    
                    let address = Flow.Address(hex: addrStr)
                    guard let hashedData = Utilities.hashPersonalMessage(data) else { return }
                    let joinData = Flow.DomainTag.user.normalize + hashedData
                    guard let sig = try? await signWithMessage(data: joinData) else {
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
                    guard let sig = try? await WalletManager.shared.walletEntity?.ethSignPersonalMessage(data) else {
                      log.error("[SOA] sign for data is error")
                      cancel()
                      return
                    }
                    confirm(sig.hexString.addHexPrefix())
                  }
                    
                } else {
                    cancel()
                }
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
        let chainId = Int(request.chainId.reference) ?? 747
        let originCadence = CadenceManager.shared.current.evm?.callContractV2?.toFunc() ?? ""
      let fromAddress = address(sessionRequest: request)
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
                  if currentIsCOA(address: fromAddress) {
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
                  } else {
                    guard let web3 = try? await web3() else {
                      log.error("[SOA] Invalid RPC URL for sending transaction")
                      cancel()
                      return
                    }
                    guard let amount = receiveModel.value
                    else {
                      cancel()
                      return
                    }
                    let defaultGas = await WalletManager.defaultGas
                    // Normalize all hex strings using the helper function
                    let chainIdHex = self.normalizeHexString(String(format: "%x", chainId))
                    let gasValue = self.normalizeHexString(receiveModel.gas ?? String(format: "%x", defaultGas))

                    //MARK: get nonce
                    let address = evmAddress()
                    let nonce = try await self.getTransactionNonce(for: address)
                    let nonceHex = self.normalizeHexString(String(nonce, radix: 16))

                    // Prepare transaction input
                    var input = EthereumSigningInput()

                    guard let chainIdData = Data(hexString: chainIdHex),
                          let nonceData = Data(hexString: nonceHex),
                          let gasLimitData = Data(hexString: gasValue)
                    else {
                      log.error("[SOA] Invalid hex data for transaction parameters")
                      log.error("[SOA] chainIdHex: \(chainIdHex), nonceHex: \(nonceHex), gasValue: \(gasValue)")
                      cancel()
                      return
                    }

                    input.chainID = chainIdData
                    input.nonce = nonceData
                    input.gasLimit = gasLimitData
                    input.toAddress = toAddr.addHexPrefix()

                    if let maxFeePerGas = receiveModel.maxFeePerGas,
                       let maxPriorityFeePerGas = receiveModel.maxPriorityFeePerGas {
                        
                        let maxFeeHex = self.normalizeHexString(maxFeePerGas)
                        let maxPriorityHex = self.normalizeHexString(maxPriorityFeePerGas)
                        
                        guard let maxFeeData = Data(hexString: maxFeeHex),
                              let maxPriorityData = Data(hexString: maxPriorityHex) else {
                            log.error("[SOA] Invalid EIP-1559 fee data")
                            HUD.error(title: "Invalid EIP-1559 fee data")
                            cancel()
                            return
                        }
                        // Validate EIP-1559 fee relationship
                        guard let maxFeeVal = BigUInt(maxFeeHex, radix: 16),
                              let maxPriorityVal = BigUInt(maxPriorityHex, radix: 16),
                              maxFeeVal >= maxPriorityVal else {
                            log.error("[SOA] maxFeePerGas must be >= maxPriorityFeePerGas")
                            HUD.error(title: "Error", message: "maxFeePerGas must be >= maxPriorityFeePerGas")
                            cancel()
                            return
                        }

                        input.txMode = .enveloped
                        input.maxFeePerGas = maxFeeData
                        input.maxInclusionFeePerGas = maxPriorityData
                        log.info("[SOA] EIP-1559 Transaction - maxFee: \(maxFeeHex), maxPriority: \(maxPriorityHex)")
                        
                    } else {
                        //MARK: Get current gas price from network
                        let gasPrice = try await web3.eth.gasPrice()
                        let gasPriceHex = self.normalizeHexString(String(gasPrice, radix: 16))
                        
                        guard let gasPriceData = Data(hexString: gasPriceHex) else {
                            log.error("[SOA] Invalid gas price data")
                            HUD.error(title: "Invalid gas price data")
                            cancel()
                            return
                        }
                        
                        input.txMode = .legacy
                        input.gasPrice = gasPriceData
                        log.info("[SOA] Legacy Transaction - gasPrice: \(gasPriceHex)")
                    }

                    // Handle both transfer and contract call transactions
                    let normalizedAmount = self.normalizeHexString(amount)
                    guard let amountData = Data(hexString: normalizedAmount) else {
                      log.error("[SOA] Invalid amount data: \(normalizedAmount)")
                      HUD.error(title: "Invalid amount data")
                      cancel()
                      return
                    }

                    // Check if this is a contract call (has data) or simple transfer
                    if let dataString = receiveModel.data, !dataString.isEmpty, dataString != "0x" {
                      // Contract call transaction
                      let normalizedData = self.normalizeHexString(dataString)
                      guard let callData = Data(hexString: normalizedData) else {
                        log.error("[SOA] Invalid contract call data: \(normalizedData)")
                        cancel()
                        return
                      }
                      input.transaction = EthereumTransaction.with {
                        $0.contractGeneric = EthereumTransaction.ContractGeneric.with {
                          $0.amount = amountData
                          $0.data = callData
                        }
                      }
                    } else {
                      // Simple transfer transaction
                      input.transaction = EthereumTransaction.with {
                        $0.transfer = EthereumTransaction.Transfer.with {
                          $0.amount = amountData
                        }
                      }
                    }

                    // Sign the transaction
                    guard let signedTransaction = try await WalletManager.shared.walletEntity?.ethSignTransaction(input) else {
                      log.error("[SOA] Failed to sign transaction")
                      HUD.error(title: "Failed to sign transaction")
                      cancel()
                      return
                    }

                    // Send raw transaction to the network
                    let txHash = try await web3.eth.send(raw: signedTransaction.encoded)
                    let receipt = try? await web3.eth.transactionReceipt(txHash.hash.data(using: .utf8)!)
                    if let receipt = receipt {
                        print("Status:", receipt.status)
                    }
                    let txid = Hash.keccak256(data: signedTransaction.encoded)
                    log.info("[SOA] Transaction sent successfully with hash: \(txHash.hash)")
                    log.info("txid: \(txid)")
                    await MainActor.run {
                        confirm(txHash.hash.addHexPrefix())
                    }
                    EventTrack.Transaction
                        .evmSigned(
                            txId: txHash.hash.addHexPrefix(),
                            success: true
                        )
                  }
                    
                }
            }

            Router.route(to: RouteMap.Explore.authz(vm))
        } catch {
            HUD.error(title: "\(error.localizedDescription)")
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
            let fromAddress = address(sessionRequest: request)
            if list.count != 2 {
                cancel()
                return
            }

            var dataStr = ""
            if list[0].lowercased() == fromAddress?.lowercased() {
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
                Task {
                    if result {
                        do {
                          if currentIsCOA(address: fromAddress) {
                            guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
                                HUD.error(title: "invalid_address".localized)
                                return
                            }
                            let address = Flow.Address(hex: addrStr)
                            let eip712Payload = try EIP712Parser.parse(dataStr)
                            let data = try eip712Payload.signHash()
                            let joinData = Flow.DomainTag.user.normalize + data
                            guard let sig = try? await signWithMessage(data: joinData) else {
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
                                cancel()
                                return
                            }
                            confirm(encoded.hexString.addHexPrefix())
                          } else {
                            let raw: String = dataStr
                            guard let signature = try? await WalletManager.shared.walletEntity?.ethSignTypedData(json: raw) else {
                              cancel()
                              return
                            }
                            confirm(signature.hexString.addHexPrefix())
                          }
                            
                        } catch {
                            cancel()
                        }
                        
                    } else {
                        cancel()
                    }
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

    private func signWithMessage(data: Data) async throws -> Data? {
        try await WalletManager.shared.sign(signableData: data)
    }
  
  private func address(sessionRequest: Request) -> String? {
    
    if let list = try? sessionRequest.params.get([String].self), list.count == 2 {
      if (EthereumAddress.toChecksumAddress(list[0]) != nil) {
        return list[0]
      }
      return list[1]
    }
    if let list = try? sessionRequest.params.get([[String: String]].self),
       let dic = list.first,
       let from = dic["from"]
    {
      return from
    }
    return nil
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
        guard let myCoaAddress = WalletManager.shared.coa?.address else {
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

        let chainId = currentNetwork.networkID
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

// MARK: EOA
extension WalletConnectEVMHandler {
  private func web3() async throws -> Web3 {
    let url = currentNetwork.evmURL.absoluteString
    guard let rpcURL = URL(string: url) else {
        throw NSError(domain: "InvalidRPC", code: -1)
    }
    let web3 = try await Web3.new(rpcURL)
    return web3
  }
  
  private func normalizeHexString(_ hex: String) -> String {
      // Remove "0x" prefix if present
      var normalizedHex = hex.hasPrefix("0x") || hex.hasPrefix("0X")
          ? String(hex.dropFirst(2))
          : hex

      // Ensure even length by padding with leading zero
      if normalizedHex.count % 2 != 0 {
          normalizedHex = "0" + normalizedHex
      }

      return normalizedHex
  }
  
  private func evmAddress() -> String {
    let address = LocalUserDefaults.shared.EVMDefaultAddress ?? WalletManager.shared.EOAs?.first?.address ?? WalletManager.shared.coa?.address
    return address ?? ""
  }
  
  private func getTransactionNonce(for address: String) async throws -> BigUInt {

      guard let web3 = try? await web3() else {
        throw NSError(domain: "InvalidRPC", code: -1)
      }
      guard let ethAddress = EthereumAddress(address) else {
          throw NSError(domain: "InvalidAddress", code: -2)
      }
      let nonce = try await web3.eth.getTransactionCount(
          for: ethAddress,
          onBlock: .latest
      )
      return nonce
  }
}
