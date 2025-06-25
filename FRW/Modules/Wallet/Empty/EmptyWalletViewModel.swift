//
//  EmptyWalletViewModel.swift
//  Flow Wallet
//
//  Created by Hao Fu on 25/12/21.
//

import Alamofire
import Combine
import Foundation
import SwiftUI

// MARK: - EmptyWalletViewModel.Placeholder

extension EmptyWalletViewModel {
    struct Placeholder {
        let uid: String
        let avatar: String
        let username: String
        let address: String
    }
}

// MARK: - EmptyWalletViewModel

class EmptyWalletViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        UserManager.shared.$loginUIDList
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] list in
                guard let self = self else { return }
                var index = 1
                let userStoreList = LocalUserDefaults.shared.userList
                self.placeholders = list.map { uid in
                    let userInfo = MultiAccountStorage.shared.getUserInfo(uid)
                    var address = MultiAccountStorage.shared.getWalletInfo(uid)?
                        .getNetworkWalletModel(network: .mainnet)?.getAddress ?? "0x"
                    if address == "0x" {
                        address = LocalUserDefaults.shared.userAddressOfDeletedApp[uid] ?? "0x"
                    }
                    if address == "0x" {
                        let userStore = userStoreList.last { $0.userId == uid }
                        address = userStore?.address ?? "0x"
                    }

                    var username = userInfo?.nickname ?? userInfo?.username
                    if username == nil {
                        username = "Account \(index)"
                        index += 1
                    }
                    return Placeholder(
                        uid: uid,
                        avatar: userInfo?.avatar ?? "",
                        username: username ?? "",
                        address: address
                    )
                }
            }.store(in: &cancelSets)
    }

    // MARK: Internal

    @Published
    var placeholders: [EmptyWalletViewModel.Placeholder] = []

    @Published
    var isLoading: Bool = false

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

    func createNewAccountAction() {
        Router.route(to: RouteMap.Register.root(nil))
    }

    func loginAccountAction() {
        Router.route(to: RouteMap.ImportWallet.profile)
    }

    func syncAccountAction() {
        Router.route(to: RouteMap.RestoreLogin.syncQC)
    }

    func tryToRestoreAccountWhenFirstLaunch() {
        if LocalUserDefaults.shared.tryToRestoreAccountFlag {
            // has been triggered or no old account to restore
            return
        }
        guard let isReachable = net?.isReachable else { return }

        if isReachable {
            net?.stopListening()
            restoreAccounts()
            return
        } else {
            net?.startListening(onQueue: .main, onUpdatePerforming: { status in
                log.info("[NET] network changed")
                switch status {
                case .reachable:
                    self.restoreAccounts()
                default:
                    log.info("[NET] not reachable")
                }
            })
        }
    }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()
    private var net: NetworkReachabilityManager? = NetworkReachabilityManager()

    private func restoreAccounts() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            await UserManager.shared.tryToRestoreOldAccountOnFirstLaunch()
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
