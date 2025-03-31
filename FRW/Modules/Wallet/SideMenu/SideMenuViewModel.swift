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
    // MARK: Lifecycle
    
    init() {
        UserManager.shared.$loginUIDList
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] uidList in
                guard let self = self else { return }

                self.accountPlaceholders = Array(uidList.dropFirst().prefix(2)).map { uid in
                    let avatar = MultiAccountStorage.shared.getUserInfo(uid)?.avatar
                        .convertedAvatarString() ?? ""
                    return AccountPlaceholder(uid: uid, avatar: avatar)
                }
            }.store(in: &cancelSets)

        WalletManager.shared.balanceProvider.$balances
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] balances in
                self?.walletBalance = balances
            }.store(in: &cancelSets)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onToggle),
            name: .toggleSideMenu,
            object: nil
        )
    }

    // MARK: Internal

    @Published
    var nftCount: Int = 0
    @Published
    var accountPlaceholders: [AccountPlaceholder] = []
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

    func scanAction() {
        NotificationCenter.default.post(name: .toggleSideMenu)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ScanHandler.scan()
        }
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
                log.error("switch account failed", context: error)
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

    func balanceValue(at address: String) -> String {
        guard let value = WalletManager.shared.balanceProvider.balanceValue(at: address) else {
            return ""
        }
        return "\(value) FLOW"
    }

    func switchProfile() {
        LocalUserDefaults.shared.recentToken = nil
    }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()
}
