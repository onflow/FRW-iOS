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
        // Guard against multiple calls
        guard !isRootViewSetup else {
            log.warning("[Coordinator] showRootView() called multiple times, ignoring")
            return
        }
        isRootViewSetup = true

        // Set initial root view controller synchronously to avoid launch error
        let isLogout = ProfileManager.shared.profiles.isEmpty || !UserManager.shared.isLoggedIn
        updateRootView(isEmpty: isLogout, animated: false)

        // Subscribe to profile changes for dynamic updates
        ProfileManager.shared.$profiles
            .dropFirst() // Skip initial value since we already handled it above
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profiles in
              if UserManager.shared.isLoggedIn {
                self?.updateRootView(isEmpty: profiles.isEmpty, animated: true)
              } else {
                self?.updateRootView(isEmpty: true, animated: true)
              }
            }
            .store(in: &cancelSets)
    }

    // MARK: Private

    /// Guard against multiple showRootView() calls
    private var isRootViewSetup = false

    /// Track current root state to avoid redundant updates
    private enum RootState {
        case reactNative
        case sideContainer
    }

    private var currentRootState: RootState?

    private func updateRootView(isEmpty: Bool, animated: Bool) {
        let targetState: RootState = isEmpty ? .reactNative : .sideContainer

        // Avoid redundant updates
        guard currentRootState != targetState else { return }
        currentRootState = targetState

        let newRootNavi: RouterNavigationController

        if isEmpty {
            log.info("[Coordinator] profiles empty → show ReactNativeViewController")
            let vc = ReactNativeViewController()
            vc.route = .getStarted
            newRootNavi = RouterNavigationController(rootViewController: vc)
            newRootNavi.setNavigationBarHidden(true, animated: false)
            newRootNavi.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            log.info("[Coordinator] profiles exist → show SideContainerView")
            let rootView = SideContainerView()
            let hostingView = UIHostingController(rootView: rootView)
            newRootNavi = RouterNavigationController(rootViewController: hostingView)
            newRootNavi.setNavigationBarHidden(true, animated: false)
        }

        rootNavi = newRootNavi

        if animated {
            // Smooth transition for dynamic updates
            newRootNavi.view.alpha = 0
            window.rootViewController = newRootNavi
            UIView.animate(withDuration: 0.3) {
                newRootNavi.view.alpha = 1
            }
        } else {
            window.rootViewController = newRootNavi
        }
    }

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
