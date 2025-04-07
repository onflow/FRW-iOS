//
//  SideMenuViewModel.swift
//  FRW
//
//  Created by Hao Fu on 1/4/2025.
//

import Foundation
import SwiftUI
import Combine

// MARK: - SideMenuViewModel.AccountPlaceholder

extension SideMenuViewModel {
    struct AccountPlaceholder {
        let uid: String
        let avatar: String
    }
}

// MARK: - SideMenuViewModel

class SideMenuViewModel: ObservableObject {
    // MARK: Internal

    @Published
    var nftCount: Int = 0
    
    @Published
    var isSwitchOpen = false
    
    @Published
    var userInfoBackgroudColor = Color.LL.Neutrals.neutrals6
    
    @Published
    var walletBalance: [String: String] = [:]

    var colorsMap: [String: Color] = [:]

    var currentAddress: String {
        WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? ""
    }

    @objc
    func onToggle() {
        isSwitchOpen = false
    }
    
    // MARK: Lifecycle
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onToggle),
            name: .toggleSideMenu,
            object: nil
        )
    }

    func pickColor(from url: String) {
        guard !url.isEmpty else {
            userInfoBackgroudColor = Color.LL.Neutrals.neutrals6
            return
        }
        if let color = colorsMap[url] {
            userInfoBackgroudColor = color
            return
        }
        Task {
            let color = await ImageHelper.mostFrequentColor(from: url)
            await MainActor.run {
                self.colorsMap[url] = color
                self.userInfoBackgroudColor = color
            }
        }
    }

    func switchAccountAction(_ uid: String) {
        Task {
            do {
                HUD.loading()
                try await UserManager.shared.switchAccount(withUID: uid)
                HUD.dismissLoading()
            } catch {
                log.error(AccountError.switchAccountFailed, context: error)
                HUD.dismissLoading()
                HUD.error(title: error.localizedDescription)
            }
        }
    }

    func switchAccountMoreAction() {
        Router.route(to: RouteMap.Profile.switchProfile)
    }

    func onClickEnableEVM() {
        NotificationCenter.default.post(name: .toggleSideMenu)
        Router.route(to: RouteMap.Wallet.enableEVM)
    }

    func switchProfile() {
        LocalUserDefaults.shared.recentToken = nil
    }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()
}
