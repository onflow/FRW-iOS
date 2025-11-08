//
//  TrustJSMessageHandler.swift
//  FRW
//
//  Created by cat on 2024/3/4.
//

import BigInt
import Combine
import CryptoKit
import Flow
import Foundation
import ReownWalletKit
import TrustWeb3Provider
import WalletCore
import Web3Core
import web3swift
import WebKit
import FlowWalletKit

// MARK: - TrustJSMessageHandler

class TrustJSMessageHandler: NSObject {
    weak var webVC: BrowserViewController?

    var supportChainID: [Int: Flow.ChainID] = [
        Flow.ChainID.mainnet.networkID: .mainnet,
        Flow.ChainID.testnet.networkID: .testnet,
    ]
    
    func web3() async throws ->  Web3? {
        guard let url = TrustWeb3Provider.flowConfig()?.config.ethereum.rpcUrl,
            let rpcURL = URL(string: url) else {
            throw NSError(domain: "InvalidRPC", code: -1)
        }
        let web3 = try await Web3.new(rpcURL)
        return web3
    }

    // Helper function to normalize hex strings for Data conversion
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
}

// MARK: - helper

extension TrustJSMessageHandler {
    private func extractMethod(json: [String: Any]) -> TrustAppMethod? {
        guard let name = json["name"] as? String
        else {
            return nil
        }
        return TrustAppMethod(rawValue: name)
    }

    private func extractNetwork(json: [String: Any]) -> ProviderNetwork? {
        guard let network = json["network"] as? String
        else {
            return nil
        }
        return ProviderNetwork(rawValue: network)
    }

    private func extractMessage(json: [String: Any]) -> Data? {
        guard let params = json["object"] as? [String: Any],
              let string = params["data"] as? String,
              let data = Data(hexString: string)
        else {
            return nil
        }
        return data
    }

    private func extractRaw(json: [String: Any]) -> String? {
        guard let params = json["object"] as? [String: Any],
              let raw = params["raw"] as? String
        else {
            return nil
        }
        return raw
    }

    private func extractObject(json: [String: Any]) -> [String: Any]? {
        guard let obj = json["object"] as? [String: Any] else {
            return nil
        }
        return obj
    }

    private func extractEthereumChainId(json: [String: Any]) -> Int? {
        guard let params = json["object"] as? [String: Any],
              let string = params["chainId"] as? String,
              let chainId = Int(String(string.dropFirst(2)), radix: 16),
              chainId > 0
        else {
            return nil
        }
        return chainId
    }
}

// MARK: WKScriptMessageHandler

extension TrustJSMessageHandler: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        let json = message.json
        let url = message.frameInfo.request.url ?? webVC?.webView.url

        guard let method = extractMethod(json: json),
              let id = json["id"] as? Int64,
              let network = extractNetwork(json: json)
        else {
            log.error("[Trust] json:\(json)")
            return
        }
        log.info("[Trust]  method: \(method)")
        switch method {
        case .requestAccounts:
            log.info("[Trust] requestAccounts")
            handleRequestAccounts(url: url, network: network, id: id)
        case .signRawTransaction:
            log.info("[Trust] signRawTransaction")
        case .signTransaction:
            log.info("[Trust] signTransaction")
            guard let obj = extractObject(json: json)
            else {
                log.info("[Trust] data is missing")
                return
            }
            handleSendTransaction(url: url, network: network, id: id, info: obj)
        case .signMessage:
            log.info("[Trust] signMessage")
        case .signTypedMessage:
            guard let data = extractMessage(json: json),
                  let raw = extractRaw(json: json)
            else {
                print("data is missing")
                return
            }
            handleSignTypedMessage(url: url, id: id, data: data, raw: raw)
        case .signPersonalMessage:
            guard let data = extractMessage(json: json) else {
                log.info("[Trust] data is missing")
                return
            }
            handleSignPersonal(url: url, network: network, id: id, data: data, addPrefix: true)
        case .sendTransaction:
            log.info("[Trust] sendTransaction")
        case .ecRecover:
            log.info("[Trust] ecRecover")
          guard let obj = extractObject(json: json)
          else {
              log.info("[Trust] data is missing\(method)")
              return
          }
          handleECRecover(network: network, id: id, json: obj)
        case .watchAsset:
            print("[Trust] watchAsset")
            guard let obj = extractObject(json: json)
            else {
                log.info("[Trust] data is missing\(method)")
                return
            }
            handleWatchAsset(network: network, id: id, json: obj)
        case .addEthereumChain:
            log.info("[Trust] addEthereumChain")
        case .switchEthereumChain:
            log.info("[Trust] switchEthereumChain")
            switch network {
            case .ethereum:
                guard let chainId = extractEthereumChainId(json: json)
                else {
                    print("chain id is invalid")
                    return
                }
                handleSwitchEthereumChain(id: id, chainId: chainId)
            }
        case .switchChain:
            log.info("[Trust] switchChain")
        }
    }
}

extension TrustJSMessageHandler {
    private func handleRequestAccounts(url: URL?, network: ProviderNetwork, id: Int64) {
      let address = webVC?.trustProvider?.config.ethereum.address ?? ""
      
      let provider = AuthnDataProvider(title: webVC?.webView.title ?? "unknown",
                                       url: url?.host() ?? "unknown",
                                       address: address,
                                       logo: url?.absoluteString.toFavIcon()?.absoluteString
      )
      let viewModel = AuthnViewModel(provider: provider) { [weak self] result in
        guard let self = self else {
            return
        }
        
        if let address =  result {
          webVC?.webView.tw.set(network: network.rawValue, address: address)
          webVC?.webView.tw.send(network: network, results: [address], to: id)
        } else {
            webVC?.webView.tw.send(network: network, error: "Canceled", to: id)
            log.debug("handle authn cancelled")
        }
      }
      Router.route(to: RouteMap.Explore.authnV2(viewModel))
    }

    private func handleSignPersonal(
        url: URL?,
        network: ProviderNetwork,
        id: Int64,
        data: Data,
        addPrefix _: Bool
    ) {
        Task {
            await TrustJSMessageHandler.checkCoa()
        }
        var title = webVC?.webView.title ?? "unknown"
        if title.isEmpty {
            title = "unknown"
        }

        let vm = BrowserSignMessageViewModel(
            title: title,
            url: url?.absoluteString ?? "unknown",
            logo: url?.absoluteString.toFavIcon()?.absoluteString,
            cadence: data.hexString
        ) { [weak self] result in
            guard let self = self else {
                return
            }

            if result {
                guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
                    HUD.error(title: "invalid_address".localized)
                    return
                }

                Task {
                  if self.currentIsCoa() {
                    guard let hashedData = Utilities.hashPersonalMessage(data) else { return }
                    let joinData = Flow.DomainTag.user.normalize + hashedData
                    let address = Flow.Address(hex: addrStr)
                    guard let sig = try? await self.signWithMessage(data: joinData) else {
                        HUD.error(title: "sign failed")
                        await self.webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
                        return
                    }
                    let keyIndex = await BigUInt(WalletManager.shared.keyIndex)
                    let proof = COAOwnershipProof(
                        keyIninces: [keyIndex],
                        address: address.data,
                        capabilityPath: "evm",
                        signatures: [sig]
                    )
                    guard let encoded = RLP.encode(proof.rlpList) else {
                        await self.webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
                        return
                    }
                    
                    await self.webVC?.webView.tw.send(
                        network: .ethereum,
                        result: encoded.hexString.addHexPrefix(),
                        to: id
                    )
                  } else {
                    
                    guard let sig = try? await WalletManager.shared.walletEntity?.ethSignPersonalMessage(data) else {
                      log.error("[SOA] sign for data is error")
                      await self.webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
                      return
                    }
                    await self.webVC?.webView.tw.send(network: .ethereum, result: sig.hexString.addHexPrefix(), to: id)
                  }
                }
            } else {
                webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
            }
        }

        Router.route(to: RouteMap.Explore.signMessage(vm))
    }

    func handleSignTypedMessage(url: URL?, id: Int64, data: Data, raw: String) {
        Task {
            await TrustJSMessageHandler.checkCoa()
        }
        var title = webVC?.webView.title ?? "unknown"
        if title.isEmpty {
            title = "unknown"
        }

        let vm = BrowserSignTypedMessageViewModel(
            title: title,
            urlString: url?.absoluteString ?? "unknown",
            logo: url?.absoluteString.toFavIcon()?.absoluteString,
            rawString: raw
        ) { [weak self] result in
            guard let self = self else {
                return
            }

            if result {
                guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
                    HUD.error(title: "invalid_address".localized)
                    return
                }
                
                Task {
                  if self.currentIsCoa() {
                    let address = Flow.Address(hex: addrStr)
                    let joinData = Flow.DomainTag.user.normalize + data
                    guard let sig = try? await self.signWithMessage(data: joinData) else {
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
                    await self.webVC?.webView.tw.send(
                        network: .ethereum,
                        result: encoded.hexString.addHexPrefix(),
                        to: id
                    )
                  } else {
                    guard let signature = try? await WalletManager.shared.walletEntity?.ethSignTypedData(json: raw) else {
                      return
                    }
                    await self.webVC?.webView.tw.send(
                        network: .ethereum,
                        result: signature.hexString.addHexPrefix(),
                        to: id
                    )
                  }
                    
                }
            } else {
                webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
            }
        }

        Router.route(to: RouteMap.Explore.signTypedMessage(vm))
    }

    private func handleSendTransaction(
        url: URL?,
        network _: ProviderNetwork,
        id: Int64,
        info: [String: Any]
    ) {
        var title = webVC?.webView.title ?? "unknown"
        if title.isEmpty {
            title = "unknown"
        }

        let originCadence = CadenceManager.shared.current.evm?.callContractV2?.toFunc() ?? ""

        guard let data = info.jsonData,
              let receiveModel = try? JSONDecoder().decode(EVMTransactionReceive.self, from: data),
              let toAddr = receiveModel.toAddress
        else {
            cancel(id: id)
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
            url: url?.absoluteString ?? "unknown",
            logo: url?.absoluteString.toFavIcon()?.absoluteString,
            cadence: originCadence,
            arguments: args.toArguments(),
            toAddress: toAddr.addHexPrefix(),
            data: receiveModel.data,
            amount: receiveModel.amountValue
        ) { [weak self] result in

            guard let self = self else {
                self?.webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
                return
            }

            if !result {
                self.webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
                return
            }

            Task {
                do {
                  if self.currentIsCoa() {
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
                        self.webVC?.webView.tw.send(
                            network: .ethereum,
                            result: calculateId.addHexPrefix(),
                            to: id
                        )
                    }
                  } else {
                    // Send the signed transaction to the network
                    guard let web3 = try await self.web3() else {
                      log.error("[SOA] Invalid RPC URL for sending transaction")
                      self.cancel(id: id)
                      return
                    }
                    
                    guard let chainId = await self.webVC?.trustProvider?.config.ethereum.chainId,
                          let amount = receiveModel.value
                    else {
                      self.cancel(id: id)
                      return
                    }
                    let defaultGas = await WalletManager.defaultGas
                    // Normalize all hex strings using the helper function
                    let chainIdHex = self.normalizeHexString(String(format: "%x", chainId))
                    let gasValue = self.normalizeHexString(receiveModel.gas ?? String(format: "%x", defaultGas))

                    //MARK: get nonce
                    let address = await self.webVC?.trustProvider?.config.ethereum.address ?? ""
                    let nonce = try await self.getTransactionNonce(for: address)
                    let nonceHex = self.normalizeHexString(String(nonce, radix: 16))

                    //MARK: Get current gas price from network
                    let gasPrice = try await web3.eth.gasPrice()
                    let gasPriceHex = self.normalizeHexString(String(gasPrice, radix: 16))

                    // Prepare transaction input
                    var input = EthereumSigningInput()

                    // Debug logging for hex values
                    log.info("[SOA] Transaction hex values - chainId: \(chainIdHex), nonce: \(nonceHex), gasPrice: \(gasPriceHex), gasLimit: \(gasValue)")

                    guard let chainIdData = Data(hexString: chainIdHex),
                          let nonceData = Data(hexString: nonceHex),
                          let gasPriceData = Data(hexString: gasPriceHex),
                          let gasLimitData = Data(hexString: gasValue)
                    else {
                      log.error("[SOA] Invalid hex data for transaction parameters")
                      log.error("[SOA] chainIdHex: \(chainIdHex), nonceHex: \(nonceHex), gasPriceHex: \(gasPriceHex), gasValue: \(gasValue)")
                      self.cancel(id: id)
                      return
                    }

                    input.chainID = chainIdData
                    input.nonce = nonceData
                    input.gasPrice = gasPriceData
                    input.gasLimit = gasLimitData
                    input.toAddress = toAddr.addHexPrefix()

                    // Handle both transfer and contract call transactions
                    let normalizedAmount = self.normalizeHexString(amount)
                    guard let amountData = Data(hexString: normalizedAmount) else {
                      log.error("[SOA] Invalid amount data: \(normalizedAmount)")
                      self.cancel(id: id)
                      return
                    }

                    // Check if this is a contract call (has data) or simple transfer
                    if let dataString = receiveModel.data, !dataString.isEmpty, dataString != "0x" {
                      // Contract call transaction
                      let normalizedData = self.normalizeHexString(dataString)
                      guard let callData = Data(hexString: normalizedData) else {
                        log.error("[SOA] Invalid contract call data: \(normalizedData)")
                        self.cancel(id: id)
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
                      self.cancel(id: id)
                      return
                    }

                    // Send raw transaction to the network
                    let txHash = try await web3.eth.send(raw: signedTransaction.encoded)
                    log.info("[SOA] Transaction sent successfully with hash: \(txHash.hash)")

                    // Return the transaction hash to frontend
                    await MainActor.run {
                      self.webVC?.webView.tw.send(
                          network: .ethereum,
                          result: txHash.hash.addHexPrefix(),
                          to: id
                      )
                    }
                  }
                    
                } catch {
                    log.error("\(error)")
                    self.cancel(id: id)
                }
            }
        }

        Router.route(to: RouteMap.Explore.authz(vm))
    }

    private func handleSwitchEthereumChain(id: Int64, chainId: Int) {
        guard let targetID = supportChainID[chainId] else {
            log.error("Unknown chain id: \(chainId)")
            HUD.error(title: "Unsupported ChainId: \(chainId)")
            webVC?.webView.tw.send(network: .ethereum, error: "Unknown chain id", to: id)
            return
        }

        let currentChainId = currentNetwork

        if targetID == currentChainId {
            log.info("No need to switch, already on chain \(chainId)")
            webVC?.webView.tw.sendNull(network: .ethereum, id: id)
        } else {
            let toId = targetID
            let callback: SwitchNetworkClosure = { [weak self] curId in
                if curId == targetID {
                    log.info("Switch to \(chainId)")
                    self?.webVC?.webView.tw.sendNull(network: .ethereum, id: id)
                } else {
                    log.error("Unknown chain id: \(chainId)")
                    self?.webVC?.webView.tw.send(
                        network: .ethereum,
                        error: "Unknown chain id",
                        to: id
                    )
                }
            }
            Router.route(to: RouteMap.Explore.switchNetwork(currentChainId, toId, callback))
        }
    }

    private func signWithMessage(data: Data) async throws -> Data? {
        return try await WalletManager.shared.sign(signableData: data)
    }

    private func cancel(id: Int64) {
        DispatchQueue.main.async {
            self.webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
        }
    }
  
    private func handleECRecover(network: ProviderNetwork, id: Int64, json: [String: Any]) {
      guard let message = json["message"] as? String, let signature = json["signature"] as? String else {
          log.error("[Trust] message or signature is nil")
          cancel(id: id)
          return
      }
      guard let signatureData = Data(hexString: signature) else {
        log.error("[Trust] signature decode failed")
        cancel(id: id)
        return
      }
      let messageData = Data(message.utf8)
      let recovered = try? FlowWalletKit.Wallet.ethRecoverAddress(signature: signatureData, message: messageData)
      if let result = recovered {
        self.webVC?.webView.tw.send(network: .ethereum, result: result, to: id)
      } else {
        self.webVC?.webView.tw.send(network: .ethereum, error: "Invalid signature v value", to: id)
      }
    }
  
    private func handleWatchAsset(network: ProviderNetwork, id: Int64, json: [String: Any]) {
        let manager = WalletManager.shared.customTokenManager
        guard let contract = json["contract"] as? String else {
            cancel(id: id)
            return
        }
        Task {
            HUD.loading()
            guard let token = try await manager.findToken(evmAddress: contract) else {
                HUD.dismissLoading()
                DispatchQueue.main.async {
                    self.webVC?.webView.tw
                        .send(network: .ethereum, result: "false", to: id)
                }
                return
            }
            HUD.dismissLoading()
            let callback: BoolClosure = { result in
                DispatchQueue.main.async {
                    self.webVC?.webView.tw
                        .send(network: .ethereum, result: result ? "true" : "false", to: id)
                }
            }
            Router.route(to: RouteMap.Wallet.addTokenSheet(token, callback))
        }
    }
}

extension TrustJSMessageHandler {
  func currentIsCoa() -> Bool {
    guard let webAddress = webVC?.trustProvider?.config.ethereum.address else {
      return false
    }
    guard let coaAddress = WalletManager.shared.coa?.address else {
      return false
    }
    return coaAddress == webAddress
  }
}

extension TrustJSMessageHandler {
    static func checkCoa() async {
        guard let addrStr = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }
        var list = LocalUserDefaults.shared.checkCoa
        if list.contains(addrStr) {
            return
        }
        do {
            HUD.loading()
            let result = try await FlowNetwork.checkCoaLink(address: addrStr)
            if result != nil, result == false {
                let txid = try await FlowNetwork.coaLink()
                let result = try await txid.onceSealed()
                if !result.isFailed {
                    list.append(addrStr)
                }
            } else {
                list.append(addrStr)
            }
            LocalUserDefaults.shared.checkCoa = list
            HUD.dismissLoading()
        } catch {
            HUD.dismissLoading()
        }
    }
}

extension TrustJSMessageHandler {
    
  
    private func getTransactionNonce(for address: String) async throws -> BigUInt {

        guard let web3 = try await web3() else {
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
