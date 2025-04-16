//
//  JSMessageHandler.swift
//  Flow Wallet
//
//  Created by Selina on 5/9/2022.
//

import CryptoKit
import Flow
import TrustWeb3Provider
import UIKit
import WebKit

// MARK: - JSMessageType

enum JSMessageType: String {
    case ready = "FCL:VIEW:READY"
    case response = "FCL:VIEW:READY:RESPONSE"
}

// MARK: - JSMessageHandler

class JSMessageHandler: NSObject {
    // MARK: Internal

    private(set) var processingAuthzTransaction: AuthzTransaction?
    weak var webVC: BrowserViewController?

    // MARK: Private

    private var processingMessage: String?
    private var processingServiceType: FCLServiceType?
    private var processingFCLResponse: FCLResponseProtocol?
    private var readyToSignEnvelope: Bool = false
    private var authzResponse: FCLAuthzResponse?
    private weak var processingLinkAccountViewModel: ChildAccountLinkViewModel?
}

// MARK: WKScriptMessageHandler

extension JSMessageHandler: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        let url = message.frameInfo.request.url ?? webVC?.webView.url

        log.debug("did receive message")

        if message.name == TrustWeb3Provider.scriptHandlerName {
            return
        }

        switch JSListenerType(rawValue: message.name) {
        case .message:
            guard let msgString = message.body as? String else {
                log.error("JSListenerType.message body invalid")
                return
            }

            handleMessage(msgString, url: url)
        case .flowTransaction:
            guard let msgString = message.body as? String else {
                log.error("JSListenerType.flowTransaction body invalid")
                return
            }

            handleTransaction(msgString)
        default:
            log.error("can't handle message", context: message.body)
        }
    }
}

extension JSMessageHandler {
    private func handleTransaction(_ message: String) {
        do {
            guard let msgData = message.data(using: .utf8),
                  let jsonDict = try JSONSerialization.jsonObject(
                      with: msgData,
                      options: .mutableContainers
                  ) as? [String: AnyObject],
                  let tid = jsonDict["txId"] as? String
            else {
                log.error("invalid message")
                return
            }

            if TransactionManager.shared.isExist(tid: tid) {
                log.warning("tid is exist")
                return
            }

            guard let processingAuthzTransaction = processingAuthzTransaction,
                  let data = try? JSONEncoder().encode(processingAuthzTransaction)
            else {
                log.error("no processingAuthzTransaction")
                return
            }

            log.debug("handle transaction", context: message)

            let id = Flow.ID(hex: tid)
            let holder = TransactionManager.TransactionHolder(
                id: id,
                type: .fclTransaction,
                data: data
            )
            TransactionManager.shared.newTransaction(holder: holder)

            if let linkAccountVM = processingLinkAccountViewModel {
                linkAccountVM.onTxID(id)
            }
        } catch {
            log.error("invalid message", context: error)
        }
    }
}

extension JSMessageHandler {
    private func handleMessage(_ message: String, url: URL?) {
        if message.isEmpty || processingMessage == message {
            return
        }

        if WalletManager.shared.getPrimaryWalletAddress() == nil {
            HUD.error(title: "browser_not_login".localized)
            return
        }

        processingMessage = message
        log.debug("handle message", context: message)

        do {
            if let msgData = message.data(using: .utf8),
               let jsonDict = try JSONSerialization.jsonObject(
                   with: msgData,
                   options: .mutableContainers
               ) as? [String: AnyObject]
            {
                if messageIsServce(jsonDict) {
                    log.debug("will handle service")
                    handleService(message)
                } else if jsonDict["type"] as? String == JSMessageType.response.rawValue {
                    log.debug("will handle view ready response")
                    handleViewReadyResponse(message, url: url)
                } else {
                    log.warning("unknown message", context: message)
                }
            } else {
                log.error("decode message failed")
            }
        } catch {
            log.error("invalid message", context: error)
        }
    }

    private func messageIsServce(_ dict: [String: AnyObject]) -> Bool {
        guard dict["type"] == nil else {
            return false
        }

        guard let serviceDict = dict["service"] as? [String: AnyObject] else {
            return false
        }

        if serviceDict["type"] != nil || serviceDict["f_type"] as? String == "Service" {
            return true
        }

        return false
    }

    private func finishService() {
        log.debug("finish service")
        processingServiceType = nil
        processingFCLResponse = nil
    }
}

// MARK: - Service

extension JSMessageHandler {
    private func handleService(_ message: String) {
        do {
            guard let data = message.data(using: .utf8) else {
                log.error("decode failed")
                return
            }

            log.debug("handle service")

            let serviceWrapper = try JSONDecoder().decode(JSFCLServiceModelWrapper.self, from: data)
            processingServiceType = serviceWrapper.service.type

            if processingServiceType == .preAuthz {
                webVC?.postPreAuthzResponse()
            } else {
                webVC?.postReadyResponse()
            }
        } catch {
            log.error("handle service failed", context: error)
        }
    }
}

// MARK: - Response

extension JSMessageHandler {
    private func handleViewReadyResponse(_ message: String, url: URL?) {
        do {
            guard let data = message.data(using: .utf8) else {
                log.error("decode message failed")
                return
            }

            let fcl = try JSONDecoder().decode(FCLSimpleResponse.self, from: data)

            if !fcl.networkIsMatch {
                let current = currentNetwork
                log
                    .warning(
                        "network mismatch, current: \(current), prefer: \(fcl.network ?? "unknown")"
                    )
                finishService()

                if let network = fcl.network,
                   let toNetwork = Flow.ChainID(rawValue: network.lowercased())
                {
                    Router.route(to: RouteMap.Explore.switchNetwork(current, toNetwork, nil))
                }

                return
            }

            if processingServiceType != fcl.serviceType {
                log
                    .error(
                        "service not same (old: \(String(describing: processingServiceType)), new: \(fcl.serviceType))"
                    )
                return
            }

            log.debug("handle view ready response")

            switch fcl.serviceType {
            case .authn:
                log.debug("will handle authn")
                handleAuthn(message, url: url)
            case .authz:
                log.debug("will handle authz")
                handleAuthz(message, url: url)
            case .userSignature:
                log.debug("will handle user signature")
                handleUserSignature(message, url: url)
            default:
                log.error("unsupport service type", context: fcl.serviceType)
            }
        } catch {
            log.error("decode message failed", context: error)
        }
    }

    private func handleAuthn(_ message: String, url: URL?) {
        do {
            guard let data = message.data(using: .utf8) else {
                log.error("decode message failed")
                return
            }

            let authnResponse = try JSONDecoder().decode(FCLAuthnResponse.self, from: data)

            if authnResponse.uniqueId() == processingFCLResponse?.uniqueId() {
                log.error("handle authn is processing: \(authnResponse.uniqueId())")
                return
            }

            log.debug("handle authn")

            processingFCLResponse = authnResponse

            let title = authnResponse.config?.app?.title ?? webVC?.webView.title ?? "unknown"
            let network = authnResponse.config?.client?.network ?? ""
            let chainID = Flow.ChainID(name: network)
            let vm = BrowserAuthnViewModel(
                title: title,
                url: url?.host ?? "unknown",
                logo: authnResponse.config?.app?.icon,
                walletAddress: WalletManager.shared
                    .getPrimaryWalletAddress(),
                network: chainID
            ) { [weak self] result in
                guard let self = self else {
                    return
                }

                if result {
                    self.didConfirmAuthn(response: authnResponse)
                } else {
                    log.debug("handle authn cancelled")
                    self.rejectRequest()
                }

                self.finishService()
            }

            Router.route(to: RouteMap.Explore.authn(vm))
        } catch {
            log.error("decode message failed", context: error)
        }
    }

    private func didConfirmAuthn(response: FCLAuthnResponse) {
        Task {
            do {
                try await self.webVC?.postAuthnViewReadyResponse(response: response)
                log.debug("did confirm authn")
            } catch {
                log.error("confirm authn failed", context: error)
                HUD.error(title: "browser_request_failed".localized)
            }
        }
    }

    private func handleAuthz(_ message: String, url: URL?) {
        do {
            guard let data = message.data(using: .utf8) else {
                log.error("decode message failed")
                return
            }

            let authzResponse = try JSONDecoder().decode(FCLAuthzResponse.self, from: data)

            if authzResponse.uniqueId() == processingFCLResponse?.uniqueId() {
                log.error("handle authz is processing: \(authzResponse.uniqueId())")
                return
            }

            log.debug("handle authz")
            processingFCLResponse = authzResponse
            self.authzResponse = authzResponse
            if readyToSignEnvelope, authzResponse.isSignEnvelope {
                log.debug("will sign envelope")
                signEnvelope(authzResponse, url: url)
                return
            }

            if authzResponse.isLinkAccount {
                log.debug("will link account")
                linkAccount(authzResponse, url: url)
                return
            }

            if authzResponse.body.f_type == "Signable" {
                log.debug("roles: \(authzResponse.body.roles.value)")
            }

            if authzResponse.isSignAuthz {
                log.debug("will sign authz")
                signAuthz(authzResponse, url: url)
                return
            }

            if authzResponse.isSignPayload {
                log.debug("will sign payload")
                signPayload(authzResponse, url: url)
                return
            }

            log.error("unknown authz")
        } catch {
            log.error("decode message failed", context: error)
        }
    }

    private func handleUserSignature(_ message: String, url: URL?) {
        do {
            guard let data = message.data(using: .utf8) else {
                log.error("decode message failed")
                return
            }

            let response = try JSONDecoder().decode(FCLSignMessageResponse.self, from: data)

            if response.uniqueId() == processingFCLResponse?.uniqueId() {
                log.error("handle user signature, is processing: \(response.uniqueId())")
                return
            }

            processingFCLResponse = response
            log.debug("handle user signature, uid: \(response.uniqueId())")

            let title = response.config?.app?.title ?? webVC?.webView.title ?? "unknown"
            let url = url?.host ?? "unknown"
            let vm = BrowserSignMessageViewModel(
                title: title,
                url: url,
                logo: response.config?.app?.icon,
                cadence: response.body?.message ?? ""
            ) { [weak self] result in
                guard let self = self else {
                    return
                }

                if result {
                    self.webVC?.postSignMessageResponse(response)
                } else {
                    self.rejectRequest()
                }

                self.finishService()
            }

            Router.route(to: RouteMap.Explore.signMessage(vm))
        } catch {
            log.error("decode message failed", context: error)
        }
    }
}

extension JSMessageHandler {
    private func signAuthz(_ authzResponse: FCLAuthzResponse, url: URL?) {
        let title = authzResponse.config?.app?.title ?? webVC?.webView.title ?? "unknown"
        let urlHost = url?.host ?? "unknown"
        let vm = BrowserAuthzViewModel(
            title: title,
            url: urlHost,
            logo: authzResponse.config?.app?.icon,
            cadence: authzResponse.body.cadence,
            arguments: authzResponse.body.voucher.arguments
        ) { [weak self] result in
            guard let self = self else {
                return
            }

            DispatchQueue.main.async {
                if result {
                    self.processingAuthzTransaction = AuthzTransaction(
                        url: url?.absoluteString,
                        title: self.webVC?.webView.title,
                        voucher: authzResponse.body.voucher
                    )
                    self.didConfirmSignPayload(authzResponse)
                } else {
                    self.rejectRequest()
                }
            }

            self.finishService()
        }
        Router.route(to: RouteMap.Explore.authz(vm))
    }

    private func linkAccount(_ authzResponse: FCLAuthzResponse, url: URL?) {
        let title = authzResponse.config?.app?.title ?? webVC?.webView.title ?? "unknown"
        let url = url?.host ?? "unknown"
        let logo = authzResponse.config?.app?.icon ?? ""

        let vm = ChildAccountLinkViewModel(
            fromTitle: title,
            url: url,
            logo: logo
        ) { [weak self] result in
            guard let self = self else {
                return
            }

            self.readyToSignEnvelope = result
            if result {
                self.didConfirmSignPayload(authzResponse)
            } else {
                self.rejectRequest()
            }
            self.finishService()
        }

        processingLinkAccountViewModel = vm
        Router.route(to: RouteMap.Explore.linkChildAccount(vm))
    }

    private func signPayload(_ authzResponse: FCLAuthzResponse, url: URL?) {
        let title = authzResponse.config?.app?.title ?? webVC?.webView.title ?? "unknown"
        let url = url?.host ?? "unknown"
        let vm = BrowserAuthzViewModel(
            title: title,
            url: url,
            logo: authzResponse.config?.app?.icon,
            cadence: authzResponse.body.cadence,
            arguments: authzResponse.body.voucher.arguments
        ) { [weak self] result in
            guard let self = self else {
                return
            }

            self.readyToSignEnvelope = result
            if result {
                self.didConfirmSignPayload(authzResponse)
            } else {
                self.rejectRequest()
            }

            self.finishService()
        }

        Router.route(to: RouteMap.Explore.authz(vm))
    }

    private func didConfirmSignPayload(_ response: FCLAuthzResponse) {
        Task {
            do {
                try await self.webVC?.postAuthzPayloadSignResponse(response: response)
                log.debug("did confirm sign payload")
            } catch {
                log.error("did confirm sign payload failed", context: error)
                HUD.error(title: "browser_request_failed".localized)
            }
        }
    }

    private func rejectRequest(reason: String = "User reject request") {
        webVC?.rejectRspsonse(reason: reason)
    }

    private func signEnvelope(_ authzResponse: FCLAuthzResponse, url: URL?) {
        let title = webVC?.webView.title

        Task {
            let request = SignPayerRequest(
                transaction: authzResponse.body.voucher.toFCLVoucher(),
                message: .init(envelopeMessage: authzResponse.body.message)
            )
            let signature: SignPayerResponse = try await Network
                .requestWithRawModel(FirebaseAPI.signAsPayer(request))
            let sign = signature.envelopeSigs

            DispatchQueue.main.async {
                self.webVC?.postAuthzEnvelopeSignResponse(sign: sign)

                let authzTransaction = AuthzTransaction(
                    url: url?.absoluteString,
                    title: title,
                    voucher: authzResponse.body.voucher
                )
                self.processingAuthzTransaction = authzTransaction

                self.readyToSignEnvelope = false
                self.finishService()
            }
        }
    }
}
