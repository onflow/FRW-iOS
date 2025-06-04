//
//  AccountSwitchViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 13/6/2023.
//

import Combine
import SwiftUI

// MARK: - AccountSwitchViewModel.Placeholder

extension AccountSwitchViewModel {
    struct Placeholder {
        let uid: String
        let avatar: String
        let username: String
        let address: String
    }
}

// MARK: - AccountSwitchViewModel

class AccountSwitchViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        UserManager.shared.$loginUIDList
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] _ in
                guard let self = self else { return }
                let userStoreList = LocalUserDefaults.shared.userList
                let result = userStoreList.map { user in
                    var model = user
                    model.userInfo = MultiAccountStorage.shared.getUserInfo(user.userId)
                    return model
                }
                self.placeholders = result
            }.store(in: &cancelSets)
    }

    // MARK: Internal

    @Published
    var placeholders: [UserManager.StoreUser] = []
    var selectedUid: String?

    func createNewAccountAction() {
        Router.route(to: RouteMap.Register.root(nil))
    }

    func loginAccountAction() {
        Router.route(to: RouteMap.RestoreLogin.restoreList)
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

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()
}
