//
//  WalletConnectManager.swift
//  Flow Wallet
//
//  Created by Hao Fu on 30/7/2022.
//

import Combine
import Flow
import Foundation
import Gzip
import ReownRouter
import ReownWalletKit
import Starscream
import UIKit
import WalletConnectNetworking
import WalletConnectNotify
import WalletConnectPairing
import WalletConnectRelay
import WalletConnectSign
import WalletConnectUtils
import WalletCore

// MARK: - WalletConnectManager

class WalletConnectManager: ObservableObject {
    // MARK: Lifecycle

    init() {
        let redirect = try! AppMetadata.Redirect(
            native: "frw://",
            universal: "https://frw-link.lilico.app"
        )
        let metadata = AppMetadata(
            name: "Flow Wallet",
            description: "Digital wallet created for everyone.",
            url: "https://frw-link.lilico.app",
            icons: ["https://frw-link.lilico.app/logo.png"],
            redirect: redirect
        )
        Networking.configure(
            groupIdentifier: AppGroupName,
            projectId: LocalEnvManager.shared.walletConnectProjectID,
            socketFactory: SocketFactory()
        )
        Pair.configure(metadata: metadata)
        Sign.configure(crypto: DefaultCryptoProvider())

        WalletKit.configure(metadata: metadata, crypto: DefaultCryptoProvider())

        Notify.configure(environment: .production, crypto: DefaultCryptoProvider())
        Notify.instance.setLogging(level: .debug)

        reloadActiveSessions()
        reloadPairing()
        setUpAuthSubscribing()

        //        #if DEBUG
        //        try? Sign.instance.cleanup()
        //        #endif

        UserManager.shared.$activatedUID
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { activatedUID in
                if activatedUID != nil {
                    self.startPendingRequestCheckTimer()
                } else {
                    self.stopPendingRequestCheckTimer()
                    self.pendingRequests = []
                }
            }.store(in: &publishers)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadPendingRequests),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: Internal

    static let shared = WalletConnectManager()

    @Published
    var activeSessions: [Session] = []

    @Published
    var activePairings: [Pairing] = []

    @Published
    var pendingRequests: [WalletConnectSign.Request] = []

    var onClientConnected: (() -> Void)?

    var currentProposal: Session.Proposal?
    var currentRequest: WalletConnectSign.Request?
    var currentSessionInfo: SessionInfo?
    var currentRequestInfo: RequestInfo?
    var currentMessageInfo: RequestMessageInfo?

    @Published
    var setSessions: [Session] = []

    func connect(link: String) {
        debugPrint("WalletConnectManager -> connect(), Thread: \(Thread.isMainThread)")
        print("[RESPONDER] Pairing to: \(link)")
        Task {
            do {
                if let removedLink = link.removingPercentEncoding {
                    let uri = try WalletConnectURI(uriString: removedLink)
                    #if DEBUG
//                    if Pair.instance.getPairings().contains(where: { $0.topic == uri.topic }) {
//                        try await Pair.instance.disconnect(topic: uri.topic)
//                    }
                    #endif
                    try await Pair.instance.pair(uri: uri)
                }
            } catch {
                print("[PROPOSER] Pairing connect error: \(error)")
                HUD.error(title: "Connect failed")
            }
        }
        onClientConnected = nil
    }

    func reloadActiveSessions() {
        let settledSessions = Sign.instance.getSessions()
        DispatchQueue.main.async {
            self.activeSessions = settledSessions
        }
    }

    func disconnect(topic: String) async {
        do {
            try await Sign.instance.disconnect(topic: topic)
            reloadActiveSessions()
        } catch {
            print(error)
            HUD.error(title: "Disconnect failed")
        }
    }

    func reloadPairing() {
        let activePairings: [Pairing] = Pair.instance.getPairings()
        self.activePairings = activePairings
    }

    func encodeAccountProof(
        address: String,
        nonce: String,
        appIdentifier: String,
        includeDomaintag: Bool = true
    ) -> Data? {
        let list: [Any] = [
            appIdentifier.data(using: .utf8) ?? Data(),
            Data(hex: address),
            Data(hex: nonce),
        ]
        guard let rlp = RLP.encode(list) else {
            return nil
        }

        let accountProofTag = Flow.DomainTag.custom("FCL-ACCOUNT-PROOF-V0.0").normalize

        if includeDomaintag {
            return accountProofTag + rlp
        } else {
            return rlp
        }
    }

    func setUpAuthSubscribing() {
        Sign.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    self?.onClientConnected?()
                    print("[RESPONDER] Client connected")
                }
            }.store(in: &publishers)

        Sign.instance.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] (sessions: [Session]) in
                // reload UI
                print("[RESPONDER] WC: Did session")
                self.setSessions = sessions
            }.store(in: &publishers)

        // TODO: Adapt proposal data to be used on the view
        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] context in
                print("[RESPONDER] WC: Did receive session proposal")
                self?.currentProposal = context.proposal
                let sessionProposal = context.proposal
                self?.handleSessionProposal(sessionProposal)
            }.store(in: &publishers)

        Sign.instance.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.reloadActiveSessions()
                self?.sendSyncAccount(in: session)
            }.store(in: &publishers)

        Sign.instance.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                log.info("[RESPONDER] WC: Did receive session response")
                log.info("[Session] response top:\(data.topic) ")
                self?.handleResponse(data)
                print(data)
            }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                print("[RESPONDER] WC: Did receive session request")
                log.info("[Session] request top:\(data.request.topic) ")
                if !SecurityManager.shared.isLocked {
                    self?.handleRequest(data.request)
                }
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadActiveSessions()
            }.store(in: &publishers)

        Sign.instance.sessionExtendPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[RESPONDER] WC: sessionExtendPublisher")
            }.store(in: &publishers)

        Sign.instance.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[RESPONDER] WC: sessionEventPublisher")
                //                self?.showSessionRequest(sessionRequest)
            }.store(in: &publishers)

        Sign.instance.sessionUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("[RESPONDER] WC: sessionUpdatePublisher")
                //                self?.showSessionRequest(sessionRequest)
            }.store(in: &publishers)
    }

    // MARK: Private

    private var publishers = [AnyCancellable]()
    private var pendingRequestCheckTimer: Timer?
    private var handler = WalletConnectHandler()

    private var syncAccountFlag: Bool = false

    private var cacheReqeust: [String] = []

    private func navigateBackTodApp(topic: String) {
        guard let session = findSession(topic: topic), let url = session.peer.redirect?.native else {
            return
        }
        ReownRouter.goBack(uri: url)
    }
}

// MARK: - Pending Request

extension WalletConnectManager {
    private func startPendingRequestCheckTimer() {
        stopPendingRequestCheckTimer()

        let timer = Timer.scheduledTimer(
            timeInterval: 3,
            target: self,
            selector: #selector(reloadPendingRequests),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)

        pendingRequestCheckTimer = timer
    }

    private func stopPendingRequestCheckTimer() {
        if let timer = pendingRequestCheckTimer {
            timer.invalidate()
            pendingRequestCheckTimer = nil
        }
    }

    @objc
    func reloadPendingRequests() {
        if UserManager.shared.isLoggedIn {
            pendingRequests = Sign.instance.getPendingRequests().map { (
                request: Request,
                _: VerifyContext?
            ) in
                request
            }

            WalletNewsHandler.shared
                .refreshWalletConnectNews(pendingRequests.map { $0.toLocalNews() })
            if let request = pendingRequests.last {
                guard !pendingBlackList().contains(request.method) else {
                    log.info("[wc] handle request from pending block:in black list.")
                    return
                }
                handleRequest(request)
            }
        }
    }

    func pendingBlackList() -> [String] {
        [
            FCLWalletConnectMethod.addDeviceInfo.rawValue,
            FCLWalletConnectMethod.accountInfo.rawValue,
            FCLWalletConnectMethod.addMultiAccount.rawValue,
        ]
    }
}

// MARK: - Handle

extension WalletConnectManager {
    private func handleSessionProposal(_ sessionProposal: Session.Proposal) {
        let pairings = Pair.instance.getPairings()

        guard let network = handler.chainId(sessionProposal: sessionProposal) else {
            rejectSession(proposal: sessionProposal)
            return
        }
        guard network == currentNetwork else {
            rejectSession(proposal: sessionProposal)
            let current = currentNetwork
            Router.route(to: RouteMap.Explore.switchNetwork(current, currentNetwork, nil))
            return
        }

        if pairings
            .contains(where: { $0.topic == sessionProposal.pairingTopic })
        {
            approveSession(proposal: sessionProposal)
            return
        }

        let info = handler.sessionInfo(sessionProposal: sessionProposal)
        var address = WalletManager.shared.getPrimaryWalletAddress()
        if handler.currentTypes(sessionProposal: sessionProposal).contains(.evm) {
            // TODO: if evm not enable
            address = EVMAccountManager.shared.accounts.first?.showAddress ?? ""
        }
        currentSessionInfo = info
        let authnVM = BrowserAuthnViewModel(
            title: info.name,
            url: info.dappURL,
            logo: info.iconURL,
            walletAddress: address,
            network: network
        ) { result in
            if result {
                self.approveSession(proposal: sessionProposal)
            } else {
                self.rejectSession(proposal: sessionProposal)
            }
        }

        Router.route(to: RouteMap.Explore.authn(authnVM))
    }

    func handleRequest(_ sessionRequest: WalletConnectSign.Request) {
        let address = WalletManager.shared.address.hex.addHexPrefix()
        let keyId = WalletManager.shared.keyIndex

        if cacheReqeust.contains(sessionRequest.id.string) {
            return
        }
        cacheReqeust.append(sessionRequest.id.string)

        switch sessionRequest.method {
        case FCLWalletConnectMethod.authn.rawValue:

            Task {
                do {
                    let jsonString = try sessionRequest.params.get([String].self)
                    let data = jsonString[0].data(using: .utf8)!

                    var services = [
                        // Since fcl-js is not implement pre-authz, hence we disable it for now
                        serviceDefinition(
                            address: RemoteConfigManager.shared.payer,
                            keyId: RemoteConfigManager.shared.keyIndex,
                            type: .preAuthz
                        ),
                        serviceDefinition(address: address, keyId: keyId, type: .authn),
                        serviceDefinition(address: address, keyId: keyId, type: .authz),
                        serviceDefinition(address: address, keyId: keyId, type: .userSignature),
                    ]

                    SecurityManager.shared.openIgnoreOnce()
                    if let model = try? JSONDecoder().decode(BaseConfigRequest.self, from: data),
                       let nonce = model.accountProofNonce ?? model.nonce,
                       let appIdentifier = model.appIdentifier,
                       let data = self.encodeAccountProof(
                           address: address,
                           nonce: nonce,
                           appIdentifier: appIdentifier
                       ),
                       let signedData = try? await WalletManager.shared.sign(signableData: data)
                    {
                        services.append(accountProofServiceDefinition(
                            address: address,
                            keyId: keyId,
                            nonce: nonce,
                            signature: signedData.hexValue
                        ))
                    }

                    let result = AuthnResponse(
                        fType: "PollingResponse",
                        fVsn: "1.0.0",
                        status: .approved,
                        data: AuthnData(
                            addr: address,
                            fType: "AuthnResponse",
                            fVsn: "1.0.0",
                            services: services
                        ),
                        reason: nil,
                        compositeSignature: nil
                    )
                    try await Sign.instance.respond(
                        topic: sessionRequest.topic,
                        requestId: sessionRequest.id,
                        response: .response(AnyCodable(result))
                    )
                    self.navigateBackTodApp(topic: sessionRequest.topic)
                } catch {
                    print("[WALLET] Respond Error: \(error.localizedDescription)")
                    rejectRequest(request: sessionRequest)
                }
            }
        case FCLWalletConnectMethod.preAuthz.rawValue:

            let result = AuthnResponse(
                fType: "PollingResponse",
                fVsn: "1.0.0",
                status: .approved,
                data: AuthnData(
                    addr: address,
                    fType: "AuthnResponse",
                    fVsn: "1.0.0",
                    services: nil,
                    proposer: serviceDefinition(
                        address: address,
                        keyId: keyId,
                        type: .authz
                    ),
                    payer:
                    [serviceDefinition(
                        address: RemoteConfigManager.shared
                            .payer,
                        keyId: RemoteConfigManager.shared
                            .keyIndex,
                        type: .authz
                    )],
                    authorization: [serviceDefinition(
                        address: address,
                        keyId: keyId,
                        type: .authz
                    )]
                ),
                reason: nil,
                compositeSignature: nil
            )

            Task {
                do {
                    try await Sign.instance.respond(
                        topic: sessionRequest.topic,
                        requestId: sessionRequest.id,
                        response: .response(AnyCodable(result))
                    )
                } catch {
                    print("[WALLET] Respond Error: \(error.localizedDescription)")
                    rejectRequest(request: sessionRequest)
                }
            }
        case FCLWalletConnectMethod.authz.rawValue:

            do {
                if sessionRequest.id == currentRequest?.id {
                    return
                }
                currentRequest = sessionRequest
                let jsonString = try sessionRequest.params.get([String].self)

                guard let json = jsonString.first else {
                    throw LLError.decodeFailed
                }

                var model: Signable?
                if let data = Data(base64Encoded: json),
                   data.isGzipped,
                   let uncompressData = try? data.gunzipped()
                {
                    model = try JSONDecoder().decode(Signable.self, from: uncompressData)
                } else if let data = json.data(using: .utf8) {
                    model = try JSONDecoder().decode(Signable.self, from: data)
                }

                guard let model else {
                    throw LLError.decodeFailed
                }

                if model.roles.payer, !model.roles.proposer, !model.roles.authorizer {
                    approvePayerRequest(
                        request: sessionRequest,
                        model: model,
                        message: model.message
                    )
                    navigateBackTodApp(topic: sessionRequest.topic)
                    return
                }

                if let session = activeSessions.first(where: { $0.topic == sessionRequest.topic }) {
                    let request = RequestInfo(
                        cadence: model.cadence ?? "",
                        agrument: model.args,
                        name: session.peer.name,
                        descriptionText: session.peer.description,
                        dappURL: session.peer.url,
                        iconURL: session.peer.icons.first ?? "",
                        chains: Set(arrayLiteral: sessionRequest.chainId),
                        methods: nil,
                        pendingRequests: [],
                        message: model.message
                    )

                    currentRequestInfo = request

                    let authzVM = BrowserAuthzViewModel(
                        title: request.name,
                        url: request.dappURL,
                        logo: request.iconURL,
                        cadence: request.cadence,
                        arguments: request.agrument
                    ) { result in
                        if result {
                            self.approveRequest(request: sessionRequest, requestInfo: request)
                        } else {
                            self.rejectRequest(request: sessionRequest)
                        }
                    }

                    Router.route(to: RouteMap.Explore.authz(authzVM))
                }

                if model.roles.payer {
                    navigateBackTodApp(topic: sessionRequest.topic)
                }

            } catch {
                print("[WALLET] Respond Error: \(error.localizedDescription)")
                log.error("WalletConnectManager -> Respond Error:", context: error)
                rejectRequest(request: sessionRequest)
            }
        case FCLWalletConnectMethod.userSignature.rawValue:

            do {
                currentRequest = sessionRequest
                let jsonString = try sessionRequest.params.get([String].self)

                guard let json = jsonString.first else {
                    throw LLError.decodeFailed
                }
                var model: SignableMessage?
                if let data = Data(base64Encoded: json),
                   data.isGzipped,
                   let uncompressData = try? data.gunzipped()
                {
                    model = try JSONDecoder().decode(SignableMessage.self, from: uncompressData)
                } else if let data = json.data(using: .utf8) {
                    model = try JSONDecoder().decode(SignableMessage.self, from: data)
                }
                guard let model = model else {
                    throw LLError.decodeFailed
                }

                if let session = activeSessions.first(where: { $0.topic == sessionRequest.topic }) {
                    let request = RequestMessageInfo(
                        name: session.peer.name,
                        descriptionText: session.peer.description,
                        dappURL: session.peer.url,
                        iconURL: session.peer.icons.first ?? "",
                        chains: Set(arrayLiteral: sessionRequest.chainId),
                        methods: nil,
                        pendingRequests: [],
                        message: model.message
                    )
                    currentMessageInfo = request

                    let vm = BrowserSignMessageViewModel(
                        title: request.name,
                        url: request.dappURL,
                        logo: request.iconURL,
                        cadence: request.message
                    ) { result in
                        if result {
                            self.approveRequestMessage(
                                request: sessionRequest,
                                requestInfo: request
                            )
                        } else {
                            self.rejectRequest(request: sessionRequest)
                        }
                        self.navigateBackTodApp(topic: sessionRequest.topic)
                    }

                    Router.route(to: RouteMap.Explore.signMessage(vm))
                }
            } catch {
                print(error)
                rejectRequest(request: sessionRequest)
            }
        case FCLWalletConnectMethod.accountInfo.rawValue:
            Task {
                do {
                    let param = try WalletConnectSyncDevice.packageUserInfo()
                    try await Sign.instance.respond(
                        topic: sessionRequest.topic,
                        requestId: sessionRequest.id,
                        response: .response(param)
                    )
                } catch {
                    log.error("[WALLET] Respond Error: [accountInfo] \(error.localizedDescription)")
                    rejectRequest(request: sessionRequest)
                }
            }
        case FCLWalletConnectMethod.addDeviceInfo.rawValue:
            Task {
                do {
                    let res = try sessionRequest.params
                        .get(SyncInfo.SyncResponse<SyncInfo.DeviceInfo>.self)
                    let viewModel = SyncAddDeviceViewModel(with: res.data!) { result in
                        if result {
                            Task {
                                do {
                                    try await Sign.instance.respond(
                                        topic: sessionRequest.topic,
                                        requestId: sessionRequest.id,
                                        response: .response(AnyCodable(""))
                                    )
                                } catch {
                                    self.rejectRequest(request: sessionRequest)
                                    print(
                                        "[WALLET] Request Error: [addDeviceInfo] \(error.localizedDescription)"
                                    )
                                }
                            }
                        } else {
                            self.rejectRequest(request: sessionRequest)
                        }
                    }
                    Router.route(to: RouteMap.RestoreLogin.syncDevice(viewModel))
                } catch {
                    print("[WALLET] Request Error: [addDeviceInfo] \(error.localizedDescription)")
                    rejectRequest(request: sessionRequest)
                }
            }
        case WalletConnectEVMMethod.personalSign.rawValue:
            log.info("[EVM] sign person")

            handler.handlePersonalSignRequest(request: sessionRequest) { signStr in
                Task {
                    do {
                        try await Sign.instance.respond(
                            topic: sessionRequest.topic,
                            requestId: sessionRequest.id,
                            response: .response(AnyCodable(signStr))
                        )
                    } catch {
                        self.rejectRequest(request: sessionRequest)
                        log.error("[EVM] Request Error: [personalSign] \(error)")
                    }
                }
            } cancel: {
                log.error("[EVM] Request cancel: [personalSign]")
                self.rejectRequest(request: sessionRequest)
            }
        case WalletConnectEVMMethod.sendTransaction.rawValue:
            log.info("[EVM] sendTransaction")
            handler.handleSendTransactionRequest(request: sessionRequest) { signStr in
                Task {
                    do {
                        try await Sign.instance.respond(
                            topic: sessionRequest.topic,
                            requestId: sessionRequest.id,
                            response: .response(AnyCodable(signStr))
                        )
                    } catch {
                        self.rejectRequest(request: sessionRequest)
                        log.error("[EVM] Request Error: [sendTransaction] \(error)")
                    }
                }
            } cancel: {
                log.info("[EVM] Request cancel: [sendTransaction]")
                self.rejectRequest(request: sessionRequest)
            }
        case WalletConnectEVMMethod.signTypedData.rawValue:
            handleSignTypedData(sessionRequest)
        case WalletConnectEVMMethod.signTypedDataV3.rawValue:
            handleSignTypedData(sessionRequest)
        case WalletConnectEVMMethod.signTypedDataV4.rawValue:
            handleSignTypedData(sessionRequest)
        case WalletConnectEVMMethod.watchAsset.rawValue:
            handleWatchAsset(sessionRequest)
        case FCLWalletConnectMethod.addMultiAccount.rawValue:
            handleSyncMultiAccount(sessionRequest)
        default:
            rejectRequest(request: sessionRequest, reason: "unspport method")
        }
    }

    func handleResponse(_ response: WalletConnectSign.Response) {
        guard let request = currentRequest else {
            log.error("[WALLET] current request is empty")
            return
        }

        switch response.result {
        case let .response(data):

            if WalletConnectSyncDevice.isAccount(request: request, with: response) {
                do {
                    let user = try WalletConnectSyncDevice.parseAccount(data: data)
                    Router.route(to: RouteMap.RestoreLogin.syncAccount(user))
                } catch {
                    log.error("[WALLET] Respond Error: [account info] \(error.localizedDescription)")
                }
            } else if WalletConnectSyncDevice.isDevice(request: request, with: response) {
                NotificationCenter.default.post(
                    name: .syncDeviceStatusDidChanged,
                    object: WalletConnectSyncDevice.SyncResult.success
                )
            } else if WalletConnectManager.shared.isMultiAccount(request: request, with: response) {
                Router.popToRoot(animated: false)
                // TODO: multi-account to confirm which profile
            }
        case let .error(error):
            if WalletConnectSyncDevice.isDevice(request: request, with: response) {
                let obj = WalletConnectSyncDevice.SyncResult.failed("process_failed_text".localized)
                NotificationCenter.default.post(name: .syncDeviceStatusDidChanged, object: obj)
            }
            print("[WALLET] Respond Error: [addDeviceInfo] \(error.localizedDescription)")
            HUD.error(title: "process_failed_text".localized)
        }
    }

    private func handleSignTypedData(_ sessionRequest: WalletConnectSign.Request) {
        handler.handleSignTypedDataV4(request: sessionRequest) { signStr in
            Task {
                do {
                    try await Sign.instance.respond(
                        topic: sessionRequest.topic,
                        requestId: sessionRequest.id,
                        response: .response(AnyCodable(signStr))
                    )
                } catch {
                    self.rejectRequest(request: sessionRequest)
                    log.error("[EVM] Request Error: [signTypedDataV4] \(error)")
                }
            }
        } cancel: {
            log.error("[EVM] Request cancel: [signTypedDataV4]")
            self.rejectRequest(request: sessionRequest)
        }
    }

    private func handleWatchAsset(_ sessionRequest: WalletConnectSign.Request) {
        handler.handleWatchAsset(request: sessionRequest) { result in
            Task {
                do {
                    try await Sign.instance
                        .respond(
                            topic: sessionRequest.topic,
                            requestId: sessionRequest.id,
                            response: .response(AnyCodable(result))
                        )
                } catch {
                    self.rejectRequest(request: sessionRequest)
                    log.error("[EVM] Add Custom Token Error: \(error)")
                }
            }

        } cancel: {
            log.error("[EVM] invalid token")
            self.rejectRequest(request: sessionRequest)
        }
    }
}

// MARK: - Action

extension WalletConnectManager {
    private func approveSession(proposal: Session.Proposal) {
        guard WalletManager.shared.getPrimaryWalletAddress() != nil else {
            return
        }

        Task {
            do {
                let namespaces = try handler.approveSessionNamespaces(sessionProposal: proposal)

                _ = try await Sign.instance.approve(proposalId: proposal.id, namespaces: namespaces)
                doAfterApprove(proposal: proposal)
                HUD.success(title: "approved".localized)
            } catch {
                debugPrint("WalletConnectManager -> approveSession failed: \(error)")
                HUD.error(title: "approve_failed".localized)
            }
        }
    }

    /// do action after approve. e.g.  sync multi-account
    private func doAfterApprove(proposal: Session.Proposal) {
        let namespaces = try? handler.approveSessionNamespaces(sessionProposal: proposal)
        // handle addMultiAccount
        let result = namespaces?.values.filter { $0.methods.contains(FCLWalletConnectMethod.addMultiAccount.rawValue) }.count ?? 0
        if result > 0 {
            /// sync multi-account[1]: approve
            skipToSyncAction(source: .old)
        }
    }

    private func rejectSession(proposal: Session.Proposal) {
        Task {
            do {
                try await Sign.instance.rejectSession(
                    proposalId: proposal.id,
                    reason: .userRejected
                )
                HUD.success(title: "rejected".localized)
            } catch {
                HUD.error(title: "reject_failed".localized)
            }
        }
    }

    private func approveRequest(request: Request, requestInfo: RequestInfo) {
        guard let account = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }

        Task {
            do {
                let data = Data(requestInfo.message.hexValue)
                let signedData = try await WalletManager.shared.sign(signableData: data)
                let signature = signedData.hexValue
                let result = AuthnResponse(
                    fType: "PollingResponse",
                    fVsn: "1.0.0",
                    status: .approved,
                    data: AuthnData(
                        addr: account,
                        fType: "CompositeSignature",
                        fVsn: "1.0.0",
                        services: nil,
                        keyId: 0,
                        signature: signature
                    ),
                    reason: nil,
                    compositeSignature: nil
                )

                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .response(AnyCodable(result))
                )

                HUD.success(title: "approved".localized)
            } catch {
                log.error("WalletConnectManager -> approveRequest failed", context: error)
                rejectRequest(request: request)
            }
        }
        reloadPendingRequests()
    }

    private func approvePayerRequest(request: Request, model: Signable, message: String) {
        guard let account = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }

        Task {
            do {
                let tx = model.voucher.toFCLVoucher()
                let data = Data(message.hexValue)
                let signedData = try await RemoteConfigManager.shared.sign(
                    voucher: tx,
                    signableData: data
                )
                let signature = signedData.hexValue
                let result = AuthnResponse(
                    fType: "PollingResponse",
                    fVsn: "1.0.0",
                    status: .approved,
                    data: AuthnData(
                        addr: account,
                        fType: "CompositeSignature",
                        fVsn: "1.0.0",
                        services: nil,
                        keyId: 0,
                        signature: signature
                    ),
                    reason: nil,
                    compositeSignature: nil
                )
                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .response(AnyCodable(result))
                )
                HUD.success(title: "payer_approved".localized)
            } catch {
                log.error("WalletConnectManager -> approveRequest failed", context: error)
                rejectRequest(request: request)
            }
        }
    }

    func rejectRequest(request: Request, reason: String = "User reject request") {
        let result = AuthnResponse(
            fType: "PollingResponse",
            fVsn: "1.0.0",
            status: .declined,
            reason: reason,
            compositeSignature: nil
        )

        Task {
            do {
                let isEVM = WalletManager.shared.isSelectedEVMAccount
                let response: RPCResult = isEVM ? .error(.init(code: 400, message: reason)) : .response(AnyCodable(result))

                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: response
                )
                HUD.success(title: "rejected".localized)
            } catch {
                log.error("WalletConnectManager -> approveRequest failed", context: error)
                HUD.error(title: "reject_failed".localized)
//                rejectRequest(request: request)
            }
        }

        reloadPendingRequests()
    }

    private func approveRequestMessage(request: Request, requestInfo: RequestMessageInfo) {
        guard let account = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }

        Task {
            do {
                let data = Flow.DomainTag.user.normalize + Data(requestInfo.message.hexValue)
                let signedData = try await WalletManager.shared.sign(signableData: data)
                let signature = signedData.hexValue
                let result = AuthnResponse(
                    fType: "PollingResponse",
                    fVsn: "1.0.0",
                    status: .approved,
                    data: AuthnData(
                        addr: account,
                        fType: "CompositeSignature",
                        fVsn: "1.0.0",
                        services: nil,
                        keyId: 0,
                        signature: signature
                    ),
                    reason: nil,
                    compositeSignature: nil
                )
                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .response(AnyCodable(result))
                )
                HUD.success(title: "approved".localized)
            } catch {
                debugPrint("WalletConnectManager -> approveRequestMessage failed: \(error)")
                HUD.error(title: "approve_failed".localized)
                rejectRequest(request: request)
            }
        }

        reloadPendingRequests()
    }
}

extension WalletConnectManager {
    func prepareSyncAccount() {
        syncAccountFlag = true
    }

    func resetSyncAccount() {
        syncAccountFlag = false
    }

    func updateCurrentRequest(_ request: WalletConnectSign.Request?) {
        currentRequest = request
    }

    func sendSyncAccount(in session: Session) {
        if !syncAccountFlag {
            return
        }
        syncAccountFlag = false
        Task {
            do {
                self.currentRequest = try await WalletConnectSyncDevice
                    .requestSyncAccount(in: session)
            } catch {
                // TODO:
                log.error("[sync]-account: send sync account requst failed")
            }
        }
    }

    func findSession(method: String, at name: String = "flow") -> Session? {
        let session = activeSessions.last { session in
            log.info("\(session.topic) : \(session.pairingTopic)")
            return session.namespaces[name]?.methods.contains(method) ?? false
        }

        return session
    }

    func findSession(topic: String) -> Session? {
        activeSessions.first(where: { $0.topic == topic })
    }
}

extension WalletConnectSign.Request {
    func toLocalNews() -> RemoteConfigManager.News {
        RemoteConfigManager.News(
            id: topic,
            priority: .urgent,
            type: .message,
            title: "Pending Request - \(name ?? "Unknown")",
            body: "You have a pending request from \((dappURL?.host) ?? "Unknown").",
            icon: logoURL?.absoluteString ?? AppPlaceholder.image,
            image: nil,
            url: nil,
            expiryTime: .distantFuture,
            displayType: .click,
            flag: .walletconnect,
            conditions: nil
        )
    }
}
