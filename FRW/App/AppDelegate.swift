//
//  AppDelegate.swift
//  Flow Wallet-lite
//
//  Created by Hao Fu on 12/12/21.
//

import CrowdinSDK
import Firebase
import FirebaseAnalytics
import FirebaseMessaging
import Foundation
import GoogleSignIn
import InstabugSDK
import ReownWalletKit
import Resolver
import SwiftUI
import SwiftyBeaver
import SwiftyDropbox
import UIKit
import WalletConnectNotify
import WalletCore
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider
import CodePush

#if DEBUG
    import Atlantis
#endif

let log = FlowLog.shared

// MARK: - AppDelegate

@main
class AppDelegate: RCTDefaultReactNativeFactoryDelegate, UIApplicationDelegate {
    static var isUnitTest: Bool {
        #if DEBUG
            return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        #else
            return false
        #endif
    }

    var window: UIWindow?
    var reactNativeDelegate: ReactNativeDelegate?
    var reactNativeFactory: RCTReactNativeFactory?
//    private var bridge: RCTBridge?
    lazy var coordinator = Coordinator(window: window!)

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        let delegate = ReactNativeDelegate()
        let factory = RCTReactNativeFactory(delegate: delegate)
        delegate.dependencyProvider = RCTAppDependencyProvider()
        reactNativeDelegate = delegate
        reactNativeFactory = factory
        
        KeyChainAccessibilityUpdate.udpate()

        _ = LocalEnvManager.shared
        SecureEnclaveMigration.start()
        FirebaseApp.configure()

        Analytics.setAnalyticsCollectionEnabled(true)
        Analytics.logEvent("ios_app_launch", parameters: [:])

        if !AppDelegate.isUnitTest {
            FirebaseConfig.start()
        }

        ServiceConfig.configure()

        appConfig()
        commonConfig()

        setupUI()
        _ = BlocklistHandler.shared

        let migration = Migration()
        migration.start()
        #if DEBUG
            Atlantis.start()
        #endif

        let crowdinProviderConfig = CrowdinProviderConfig(
            hashString: "f4bff0f0e2ed98c2ba53a29qzvm",
            sourceLanguage: "en"
        )
        let crowdinSDKConfig = CrowdinSDKConfig
            .config()
            .with(crowdinProviderConfig: crowdinProviderConfig)
            .with(debugEnabled: true)
        CrowdinSDK.startWithConfig(crowdinSDKConfig, completion: {
            log.info("[Crowdin] SDK is ready to use")
        })
        CrowdinSDK.setOnLogCallback { info in
            log.debug("[Crowdin] \(info)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.jailbreakDetect()
        }

        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            _ = Replies.didReceiveRemoteNotification(notification)
        }
        FlowLog.logEnv()
        InstallInfoManager.recordInstallInfoIfNeeded()
        return true
    }

    func application(
        _: UIApplication,
        open url: URL,
        options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if DeepLinkHandler.shared.canHandleURL(url) {
            DeepLinkHandler.shared.handleURL(url)
            return true
        }

        if WalletConnectManager.shared.canHandleURL(url) {
            WalletConnectManager.shared.handleURL(url)
        }

        // callback for login by dropbox
        let oauthCompletion: DropboxOAuthCompletion = {
            NotificationCenter.default.post(name: .dropboxCallback, object: $0)
        }
        let canHandleUrl = DropboxClientsManager.handleRedirectURL(
            url,
            includeBackgroundClient: false,
            completion: oauthCompletion
        )
        if canHandleUrl {
            return canHandleUrl
        }

        return GIDSignIn.sharedInstance.handle(url)
    }

    func application(
        _: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL
        {
            if DeepLinkHandler.shared.canHandleURL(url) {
                DeepLinkHandler.shared.handleURL(url)
                return true
            }

            if WalletConnectManager.shared.canHandleURL(url) {
                WalletConnectManager.shared.handleURL(url)
                return true
            }
        }
        return false
    }
    
    override func sourceURL(for bridge: RCTBridge) -> URL? {
        self.bundleURL()
    }
    
    override func bundleURL() -> URL? {
    #if DEBUG
        // Force Metro connection for debugging
        return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
    #else
        CodePush.bundleURL()
    #endif
    }
    
    // MARK: - React Native Bridge Access
//    
//    func getRCTBridge() -> RCTBridge? {
//        return bridge
//    }
    
    func getRCTReactNativeFactory() -> RCTReactNativeFactory? {
        return reactNativeFactory
    }
    
    deinit {
        // Clean up notification observers to prevent memory leaks
        NotificationCenter.default.removeObserver(self)
        
        // Clean up React Native resources
        reactNativeDelegate = nil
        reactNativeFactory = nil
        
        print("✅ DEBUG: AppDelegate cleaned up successfully")
    }
}

// MARK: - Config

extension AppDelegate {
    private func setupNavigationBar() {
        let font = UIFont(name: "Inter", size: 18)?.semibold
        let largeFont = UIFont(name: "Inter", size: 24)?.bold
        let color = UIColor(named: "neutrals.text")!
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: color, .font: font!]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: color,
            .font: largeFont!,
        ]
    }

    private func appConfig() {
        MultiAccountStorage.shared.upgradeFromOldVersionIfNeeded()
        _ = CadenceManager.shared
        _ = UserManager.shared
        _ = WalletManager.shared
        _ = BackupManager.shared
        _ = SecurityManager.shared
        _ = WalletConnectManager.shared
        _ = CoinRateCache.cache
        if !AppDelegate.isUnitTest {
            _ = RemoteConfigManager.shared
        }
        _ = StakingManager.shared

        _ = ChildAccountManager.shared
//        WalletManager.shared.bindChildAccountManager()
        NFTCatalogCache.cache.fetchIfNeed()

        if UserManager.shared.isLoggedIn {
            DeviceManager.shared.updateDevice()
        }
    }

    private func commonConfig() {
        setupNavigationBar()

        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().sectionHeaderTopPadding = 0
        UISearchBar.appearance().tintColor = UIColor.LL.Secondary.violetDiscover
        UINavigationBar.appearance().shadowImage = UIImage()

        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .orange

        HUD.setupProgressHUD()
    }
}

// MARK: - UI

extension AppDelegate {
    private func setupUI() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange),
            name: .networkChange,
            object: nil
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.LL.Neutrals.background

        coordinator.showRootView()
        coordinator.rootNavi?.view.alpha = 0

        window?.makeKeyAndVisible()

        SecurityManager.shared.lockAppIfNeeded()

        UIView.animate(withDuration: 0.2, delay: 0.1) {
            self.coordinator.rootNavi?.view.alpha = 1
        }

        delay(.seconds(5)) {
            UIView.animate(withDuration: 0.2) {
                self.window?.backgroundColor = currentNetwork == .mainnet ? UIColor.LL.Neutrals
                    .background : UIColor(currentNetwork.color)
            }
        }
    }

    @objc
    func handleNetworkChange() {
        window?.backgroundColor = currentNetwork == .mainnet ? UIColor.LL.Neutrals
            .background : UIColor(currentNetwork.color)
    }
}

// MARK: Delegate

extension AppDelegate {
    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let deviceTokenString = deviceToken.map { data in String(format: "%02.2hhx", data) }
        UserDefaults.standard.set(deviceTokenString.joined(), forKey: "deviceToken")
        log.info("DeviceToken: \(deviceTokenString)")
        Task(priority: .high) {
            log.debug("[Push] web3wallet register before \(deviceTokenString.joined())")
//            do {
//                try await Web3Wallet.instance.register(deviceToken: deviceToken, enableEncrypted: true)
//                log.debug("[Push] web3wallet register after")
//            }catch {
//                log.error("[Push] web3wallet register error")
//            }
        }
        #if DEBUG
            Messaging.messaging().setAPNSToken(deviceToken, type: .sandbox)
        #else
            Messaging.messaging().setAPNSToken(deviceToken, type: .prod)
        #endif

        Replies.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }

    func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        let isInstabugNotification = Replies.didReceiveRemoteNotification(userInfo)
    }
}

extension AppDelegate {
    private func jailbreakDetect() {
        if UIDevice.isJailbreak {
            Router.route(to: RouteMap.Wallet.jailbreakAlert)
        }
    }
}


class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
