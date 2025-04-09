//
//  PushHandler.swift
//  Flow Wallet
//
//  Created by Selina on 17/7/2023.
//

import Combine
import FirebaseMessaging
import UIKit
import WalletConnectNotify

// MARK: - PushHandler

class PushHandler: NSObject, ObservableObject {
    // MARK: Lifecycle

    override private init() {
        super.init()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        refreshPushStatus()

        WalletManager.shared.$currentMainAccount
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                log.debug("wallet info refresh triggerd a upload token action")
                self.uploadWhenAppUpgrade()
                self.uploadCurrentToken()
            }.store(in: &cancelSets)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.refreshPushStatus()
            }.store(in: &cancelSets)
    }

    // MARK: Internal

    static let shared = PushHandler()

    @Published
    var isPushEnabled: Bool = false

    func requestPermission() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { result, _ in
            DispatchQueue.main.async {
                self.refreshPushStatus()

                if result {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func showPushAlertIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined, !self.hasSeenPushAlert {
                    self.showPushAlert()
                }
            }
        }
    }

    // MARK: Private

    private var fcmToken: String?
    private var uploadedHistory: [String: String] = [:]
    private var cancelSets = Set<AnyCancellable>()
    private var uploadingAddress: String?
    private var hasSeenPushAlert = false
}

extension PushHandler {
    private func showPushAlert() {
        hasSeenPushAlert = true
        Router.route(to: RouteMap.Wallet.pushAlert)
    }

    private func refreshPushStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isPushEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    private func uploadToken(_ token: String) {
        if fcmToken != token {
            uploadedHistory.removeAll()
        }

        fcmToken = token
        uploadCurrentToken()
    }

    private func uploadCurrentToken() {
        guard let address = WalletManager.shared
            .getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
            let fcmToken = fcmToken
        else {
            return
        }

        if uploadedHistory[address] == fcmToken {
            // uploaded
            log.debug("\(address) push token already uploaded")
            return
        }

        if uploadingAddress == address {
            return
        }

        uploadingAddress = address

        sendToken(token: fcmToken, address: address)
    }

    func uploadWhenAppUpgrade() {
        guard let address = WalletManager.shared
            .getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
            let fcmToken = Messaging.messaging().fcmToken
        else {
            return
        }

        if AppUpdateManager.shared.isUpdated {
            sendToken(token: fcmToken, address: address)
            return
        }
    }

    private func sendToken(token: String, address: String) {
        Task {
            do {
                let resp: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.Utils.retoken(
                        token,
                        address
                    ))
                log.debug("\(address) upload push token success", context: resp)
                DispatchQueue.main.async {
                    self.uploadedHistory[address] = token
                    self.uploadingAddress = nil
                }
            } catch {
                log.error("\(address) upload push token failed", context: error)
                DispatchQueue.main.async {
                    self.uploadingAddress = nil
                }
            }
        }
    }
}

// MARK: MessagingDelegate, UNUserNotificationCenterDelegate

extension PushHandler: MessagingDelegate, UNUserNotificationCenterDelegate {
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        log.debug("fcm token: ", context: fcmToken)
        if let fcmToken = fcmToken, !fcmToken.isEmpty {
            uploadToken(fcmToken)
        }
//        registerForWalletConnect()
    }

    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            let userInfo = response.notification.request.content.userInfo
            log.debug("user did click a notification", context: userInfo)
            if let transactionId = userInfo["transactionId"] as? String {
                let network = LocalUserDefaults.shared.flowNetwork
                let accountType = AccountType.current
                let url = network.getTransactionHistoryUrl(accountType: accountType, transactionId: transactionId)

                url.map { Router.route(to: RouteMap.Explore.browser($0)) }
            }
        }
    }
}

extension PushHandler {
    private func registerForWalletConnect() {
        if let deviceToken = Messaging.messaging().apnsToken {
            Task(priority: .high) {
                log.debug("[Push] web3wallet register before")
                let deviceTokenString = deviceToken.map { data in String(format: "%02.2hhx", data) }
                UserDefaults.standard.set(deviceTokenString.joined(), forKey: "deviceToken")
                do {
//                    try await Notify.instance.register(deviceToken: deviceToken, enableEncrypted: true)
                    log.debug("[Push] web3wallet register after")
                } catch {
                    log.error("[Push] web3wallet register error")
                }
            }
        }
    }
}
