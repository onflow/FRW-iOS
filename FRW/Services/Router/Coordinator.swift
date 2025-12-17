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
        // Set initial root view controller synchronously to avoid launch error
        updateRootView(isEmpty: ProfileManager.shared.profiles.isEmpty)

        // Subscribe to profile changes for dynamic updates
        ProfileManager.shared.$profiles
            .dropFirst() // Skip initial value since we already handled it above
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profiles in
                self?.updateRootView(isEmpty: profiles.isEmpty)
            }
            .store(in: &cancelSets)
    }

    // MARK: Private

    /// Track current root state to avoid redundant updates
    private enum RootState {
        case reactNative
        case sideContainer
    }

    private var currentRootState: RootState?

    private func updateRootView(isEmpty: Bool) {
        let targetState: RootState = isEmpty ? .reactNative : .sideContainer

        // Avoid redundant updates
        guard currentRootState != targetState else { return }
        currentRootState = targetState

        if isEmpty {
            log.info("[Coordinator] profiles empty → show ReactNativeViewController")
            let vc = ReactNativeViewController()
            vc.route = .getStarted
            let navi = RouterNavigationController(rootViewController: vc)
            navi.setNavigationBarHidden(true, animated: true)
            navi.interactivePopGestureRecognizer?.isEnabled = false
            rootNavi = navi
            window.rootViewController = rootNavi
        } else {
            log.info("[Coordinator] profiles exist → show SideContainerView")
            let rootView = SideContainerView()
            let hostingView = UIHostingController(rootView: rootView)
            let navi = RouterNavigationController(rootViewController: hostingView)
            navi.setNavigationBarHidden(true, animated: true)
            rootNavi = navi
            window.rootViewController = rootNavi
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
