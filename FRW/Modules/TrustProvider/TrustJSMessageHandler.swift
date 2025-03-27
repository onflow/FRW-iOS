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

// MARK: - TrustJSMessageHandler

class TrustJSMessageHandler: NSObject {
    weak var webVC: BrowserViewController?

    var supportChainID: [Int: Flow.ChainID] = [
        FlowNetworkType.mainnet.networkID: .mainnet,
        FlowNetworkType.testnet.networkID: .testnet,
    ]
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
        let callback = { [weak self] in
            guard let self = self else {
                return
            }

            let address = webVC?.trustProvider?.config.ethereum.address ?? ""

            let title = webVC?.webView.title ?? "unknown"
            let chainID = LocalUserDefaults.shared.flowNetwork.toFlowType()
            let vm = BrowserAuthnViewModel(
                title: title,
                url: url?.host ?? "unknown",
                logo: url?.absoluteString.toFavIcon()?.absoluteString,
                walletAddress: address,
                network: chainID
            ) { [weak self] result in
                guard let self = self else {
                    return
                }

                if result {
                    switch network {
                    case .ethereum:
                        webVC?.webView.tw.set(network: network.rawValue, address: address)
                        webVC?.webView.tw.send(network: network, results: [address], to: id)
                    default:
                        print("not support")
                    }
                } else {
                    webVC?.webView.tw.send(network: network, error: "Canceled", to: id)
                    log.debug("handle authn cancelled")
                }
            }

            Router.route(to: RouteMap.Explore.authn(vm))
        }

        MoveAssetsAction.shared.startBrowserWithMoveAssets(
            appName: webVC?.webView.title,
            callback: callback
        )
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

                let address = Flow.Address(hex: addrStr)
                guard let hashedData = Utilities.hashPersonalMessage(data) else { return }
                let joinData = Flow.DomainTag.user.normalize + hashedData
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
                webVC?.webView.tw.send(
                    network: .ethereum,
                    result: encoded.hexString.addHexPrefix(),
                    to: id
                )
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
                let address = Flow.Address(hex: addrStr)
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
                webVC?.webView.tw.send(
                    network: .ethereum,
                    result: encoded.hexString.addHexPrefix(),
                    to: id
                )
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

        let currentChainId = LocalUserDefaults.shared.flowNetwork.toFlowType()

        if targetID == currentChainId {
            log.info("No need to switch, already on chain \(chainId)")
            webVC?.webView.tw.sendNull(network: .ethereum, id: id)
        } else {
            guard let fromId = currentChainId.networkType, let toId = targetID.networkType else {
                log.error("Unknown chain id: \(chainId)")
                HUD.error(title: "Unsupported ChainId: \(chainId)")
                webVC?.webView.tw.send(network: .ethereum, error: "Unknown chain id", to: id)
                return
            }
            let callback: SwitchNetworkClosure = { [weak self] curId in
                if curId.toFlowType() == targetID {
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
            Router.route(to: RouteMap.Explore.switchNetwork(fromId, toId, callback))
        }
    }

    private func signWithMessage(data: Data) -> Data? {
        WalletManager.shared.signSync(signableData: data)
    }

    private func cancel(id: Int64) {
        DispatchQueue.main.async {
            self.webVC?.webView.tw.send(network: .ethereum, error: "Canceled", to: id)
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
