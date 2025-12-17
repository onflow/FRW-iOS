//
//  Coordinator.swift
//  Flow Wallet
//
//  Created by Selina on 25/7/2022.
//

import Combine
import SwiftUI
import UIKit

// MARK: - AppTabType

// import Lottie

enum AppTabType {
    case wallet
    case nft
    case explore
    case txhistory
    case profile
}

// MARK: - AppTabBarPageProtocol

protocol AppTabBarPageProtocol {
    static func tabTag() -> AppTabType
    static func iconName() -> String
    static func title() -> String
}

// MARK: - Coordinator

final class Coordinator {
    // MARK: Lifecycle

    init(window: UIWindow) {
        self.window = window

        ThemeManager.shared.$style.sink { _ in
            DispatchQueue.main.async {
                self.refreshColorScheme()
            }
        }.store(in: &cancelSets)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    // MARK: Internal

    let window: UIWindow
    lazy var rootNavi: UINavigationController? = nil

    func showRootView() {
        let rootView = SideContainerView()
        let hostingView = UIHostingController(rootView: rootView)
        let navi = RouterNavigationController(rootViewController: hostingView)
        navi.setNavigationBarHidden(true, animated: true)
        rootNavi = navi
        window.rootViewController = rootNavi

        if ProfileManager.shared.profiles.isEmpty {
          log.info("[] don't have Profile")
            let vc = ReactNativeViewController()
            vc.route = .getStarted
            navi.setNavigationBarHidden(true, animated: true)
            navi.interactivePopGestureRecognizer?.isEnabled = false
            navi.pushViewController(vc, animated: false)
        } else {
          log.info("[] has profile")
        }
    }

    // MARK: Private

    private lazy var privateView: AppPrivateView = {
        let view = AppPrivateView()
        return view
    }()

    private var cancelSets = Set<AnyCancellable>()
}

extension Coordinator {
    private func refreshColorScheme() {
        window.overrideUserInterfaceStyle = ThemeManager.shared.getUIKitStyle()
    }
}

// MARK: - Private Screen

extension Coordinator {
    @objc
    private func didEnterBackground() {
        privateView.alpha = 1
        privateView.removeFromSuperview()
        privateView.frame = window.bounds
        window.addSubview(privateView)
        privateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc
    private func didBecomeActive() {
        let systemStyle = UIScreen.main.traitCollection.userInterfaceStyle
        ThemeManager.shared.updateStyle(style: systemStyle)
        UIView.animate(withDuration: 0.25) {
            self.privateView.alpha = 0
        } completion: { _ in
            self.privateView.removeFromSuperview()
        }
    }
}
