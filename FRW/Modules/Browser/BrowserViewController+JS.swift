//
//  BrowserViewController+JS.swift
//  Flow Wallet
//
//  Created by Selina on 2/9/2022.
//

import TrustWeb3Provider
import UIKit
import WebKit

private let jsListenWindowFCLMessage = """
    window.addEventListener('message', function (event) {
      window.webkit.messageHandlers.message.postMessage(JSON.stringify(event.data))
    })
"""

private let jsListenFlowWalletTransaction = """
    window.addEventListener('FLOW::TX', function (event) {
      window.webkit.messageHandlers.transaction.postMessage(JSON.stringify({type: 'FLOW::TX', ...event.detail}))
    })
"""

private func generateFCLExtensionInject() -> String {
    let js = """
    const service = {
      f_type: "Service",
      f_vsn: "1.0.0",
      type: "authn",
      uid: "Flow Wallet",
      endpoint: "chrome-extension://hpclkefagolihohboafpheddmmgdffjm/popup.html",
      method: "EXT/RPC",
      id: "hpclkefagolihohboafpheddmmgdffjm",
      identity: {
        address: "0x33f75ff0b830dcec",
      },
      provider: {
        address: "0x33f75ff0b830dcec",
        name: "Flow Wallet",
        icon: "https://lilico.app/logo_mobile.png",
        description: "Digital wallet created for everyone.",
      },
    };

    function injectExtService(service) {
      if (service.type === "authn" && service.endpoint != null) {
        if (!Array.isArray(window.fcl_extensions)) {
          window.fcl_extensions = [];
        }
        window.fcl_extensions.push(service);
      } else {
        console.warn("Authn service is required");
      }

      const EIP6963Icon =
        "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjUwIiBoZWlnaHQ9IjI1MCIgdmlld0JveD0iMCAwIDI1MCAyNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxnIGNsaXAtcGF0aD0idXJsKCNjbGlwMF8xMzc2MV8zNTIxKSI+CjxyZWN0IHdpZHRoPSIyNTAiIGhlaWdodD0iMjUwIiByeD0iNDYuODc1IiBmaWxsPSJ3aGl0ZSIvPgo8ZyBjbGlwLXBhdGg9InVybCgjY2xpcDFfMTM3NjFfMzUyMSkiPgo8cmVjdCB3aWR0aD0iMjUwIiBoZWlnaHQ9IjI1MCIgZmlsbD0idXJsKCNwYWludDBfbGluZWFyXzEzNzYxXzM1MjEpIi8+CjxwYXRoIGQ9Ik0xMjUgMjE3LjUyOUMxNzYuMTAyIDIxNy41MjkgMjE3LjUyOSAxNzYuMTAyIDIxNy41MjkgMTI1QzIxNy41MjkgNzMuODk3NSAxNzYuMTAyIDMyLjQ3MDcgMTI1IDMyLjQ3MDdDNzMuODk3NSAzMi40NzA3IDMyLjQ3MDcgNzMuODk3NSAzMi40NzA3IDEyNUMzMi40NzA3IDE3Ni4xMDIgNzMuODk3NSAyMTcuNTI5IDEyNSAyMTcuNTI5WiIgZmlsbD0id2hpdGUiLz4KPHBhdGggZD0iTTE2NS4zODIgMTEwLjQyMkgxMzkuNTg1VjEzNi43OEgxNjUuMzgyVjExMC40MjJaIiBmaWxsPSJibGFjayIvPgo8cGF0aCBkPSJNMTEzLjIyNyAxMzYuNzhIMTM5LjU4NVYxMTAuNDIySDExMy4yMjdWMTM2Ljc4WiIgZmlsbD0iIzQxQ0M1RCIvPgo8L2c+CjwvZz4KPGRlZnM+CjxsaW5lYXJHcmFkaWVudCBpZD0icGFpbnQwX2xpbmVhcl8xMzc2MV8zNTIxIiB4MT0iMCIgeTE9IjAiIHgyPSIyNTAiIHkyPSIyNTAiIGdyYWRpZW50VW5pdHM9InVzZXJTcGFjZU9uVXNlIj4KPHN0b3Agc3RvcC1jb2xvcj0iIzFDRUI4QSIvPgo8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiM0MUNDNUQiLz4KPC9saW5lYXJHcmFkaWVudD4KPGNsaXBQYXRoIGlkPSJjbGlwMF8xMzc2MV8zNTIxIj4KPHJlY3Qgd2lkdGg9IjI1MCIgaGVpZ2h0PSIyNTAiIHJ4PSI0Ni44NzUiIGZpbGw9IndoaXRlIi8+CjwvY2xpcFBhdGg+CjxjbGlwUGF0aCBpZD0iY2xpcDFfMTM3NjFfMzUyMSI+CjxyZWN0IHdpZHRoPSIyNTAiIGhlaWdodD0iMjUwIiBmaWxsPSJ3aGl0ZSIvPgo8L2NsaXBQYXRoPgo8L2RlZnM+Cjwvc3ZnPgo=";

      const info = {
        uuid: crypto.randomUUID(),
        name: "Flow Wallet",
        icon: EIP6963Icon,
        rdns: "com.flowfoundation.wallet",
      };

      const announceEvent = new CustomEvent("eip6963:announceProvider", {
        detail: Object.freeze({ info, provider: window.ethereum }),
      });

      window.dispatchEvent(announceEvent);

      window.addEventListener("eip6963:requestProvider", () => {
        window.dispatchEvent(announceEvent);
      });
    }

    injectExtService(service);

    """

    return js
}

// MARK: - JSListenerType

enum JSListenerType: String {
    case message
    case flowTransaction = "transaction"
}

extension BrowserViewController {
    var listenFCLMessageUserScript: WKUserScript {
        let us = WKUserScript(
            source: jsListenWindowFCLMessage,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        return us
    }

    var listenFlowWalletTransactionUserScript: WKUserScript {
        let us = WKUserScript(
            source: jsListenFlowWalletTransaction,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        return us
    }

    var extensionInjectUserScript: WKUserScript {
        let us = WKUserScript(
            source: generateFCLExtensionInject(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        return us
    }

    func generateWebViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        let ucc = WKUserContentController()
        config.applicationNameForUserAgent = "Chrome/101.0.4951.67"
        ucc.add(jsHandler, name: JSListenerType.message.rawValue)
        ucc.add(jsHandler, name: JSListenerType.flowTransaction.rawValue)
        ucc.addUserScript(listenFCLMessageUserScript)
        ucc.addUserScript(listenFlowWalletTransactionUserScript)
        // Trust Web3
        ucc.add(trustJSHandler, name: TrustWeb3Provider.scriptHandlerName)
        if let provider = trustProvider {
            ucc.addUserScript(provider.providerScript)
            ucc.addUserScript(provider.injectScript)
        }

        ucc.addUserScript(extensionInjectUserScript)
        config.userContentController = ucc
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.allowsInlineMediaPlayback = true

        return config
    }
}

// MARK: - Post

extension BrowserViewController {
    func notifyFinish(callbackID: Int, value: String) {
        let script = "window.ethereum.sendResponse(\(callbackID), \"\(value)\")"
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                log.error("notify finish failed", context: error)
            }
        }
    }

    func postPreAuthzResponse() {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            log.error("primary address is nil")
            return
        }
        let keyIndex = WalletManager.shared.keyIndex
        log.debug("will post pre authz response")
        postMessage(FCLScripts.generatePreAuthzResponse(address: address, keyIndex: keyIndex))
        log.debug("did post pre authz response")
    }

    func postAuthnViewReadyResponse(response: FCLAuthnResponse) async throws {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            log.error("primary address is nil")
            return
        }

        var accountProofSign = ""

        if let nonce = response.body.nonce,
           !nonce.isEmpty,
           let proofSign = response.encodeAccountProof(address: address),
           let sign = WalletManager.shared.signSync(signableData: proofSign)
        {
            accountProofSign = sign.hexValue
        }
        let keyIndex = WalletManager.shared.keyIndex
        let message = try await FCLScripts.generateAuthnResponse(
            accountProofSign: accountProofSign,
            nonce: response.body.nonce ?? "",
            address: address,
            keyId: keyIndex
        )

        DispatchQueue.syncOnMain {
            log.debug("will post authn view ready response")
            self.postMessage(message)
            log.debug("did post authn view ready response")
        }
    }

    func postAuthzPayloadSignResponse(response: FCLAuthzResponse) async throws {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            log.error("primary address is nil")
            throw WalletError.noPrimaryWalletAddress
        }

        let data = Data(hex: response.body.message)
        let signData = try await WalletManager.shared.sign(signableData: data)

        let keyId = WalletManager.shared.keyIndex
        let message = FCLScripts.generateAuthzResponse(
            address: address,
            signature: signData.hexValue,
            keyId: keyId
        )
        DispatchQueue.syncOnMain {
            log.debug("will post authz payload sign response")
            self.postMessage(message)
            log.debug("did post authz payload sign response")
        }
    }

    func rejectRspsonse(reason: String) {
        DispatchQueue.syncOnMain {
            let message = FCLScripts.genertateRejectResponse(reason: reason)
            log.debug("will post reject response")
            self.postMessage(message)
            log.debug("did post reject response")
        }
    }

    func postAuthzEnvelopeSignResponse(sign: FCLVoucher.Signature) {
        let message = FCLScripts.generateAuthzResponse(
            address: sign.address.hex.addHexPrefix(),
            signature: sign.sig,
            keyId: sign.keyId
        )
        log.debug("will post authz envelope response")
        postMessage(message)
        log.debug("did post authz envelope response")
    }

    func postReadyResponse() {
        log.debug("will post ready response")
        postMessage("{type: '\(JSMessageType.ready.rawValue)'}")
        log.debug("did post ready response")
    }

    func postSignMessageResponse(_ response: FCLSignMessageResponse) {
        let keyIndex = WalletManager.shared.keyIndex
        guard let address = WalletManager.shared.getPrimaryWalletAddress(),
              let message = response.body?.message,
              let js = FCLScripts.generateSignMessageResponse(
                  message: message,
                  address: address,
                  keyId: keyIndex
              )
        else {
            log.error("generate js failed")
            return
        }

        log.debug("will post sign message response")
        postMessage(js)
        log.debug("did post sign message response")
    }

    func postMessage(_ message: String) {
        let js = "window && window.postMessage(JSON.parse(JSON.stringify(\(message) || {})), '*')"

        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                log.error("post message error", context: error)
            }
        }
    }
}
