//
//  RestoreMultiAccountViewModel.swift
//  FRW
//
//  Created by cat on 2024/1/7.
//

import FlowWalletKit
import Foundation

class RestoreMultiAccountViewModel: ObservableObject {
    // MARK: Lifecycle

    init(items: [[MultiBackupManager.StoreItem]]) {
        self.items = items
    }

    // MARK: Internal

    var items: [[MultiBackupManager.StoreItem]]

    func onClickUser(at index: Int) {
        guard index < items.count else {
            return
        }
        let selectedUser = items[index]

        guard let selectedUserId = selectedUser.first?.userId else {
            log.error("[restore] invaid user id")
            return
        }

        if let item = selectedUser.first {
            let methods = selectedUser.map { $0.backupType?.methodName() ?? "" }
            EventTrack.Account
                .recovered(address: item.address, mechanism: "multi-backup", methods: methods)
        }

        // If it is the current user, do nothing and return directly.
        if let userId = UserManager.shared.activatedUID, userId == selectedUserId {
            Router.popToRoot()
            return
        }

        // If it is in the login list, switch user
        if UserManager.shared.loginUIDList.contains(selectedUserId) {
            Task {
                do {
                    HUD.loading()
                    try await UserManager.shared.switchAccount(withUID: selectedUserId)
                    MultiAccountStorage.shared.setBackupType(.multi, uid: selectedUserId)
                    HUD.dismissLoading()
                } catch {
                    log.error("switch account failed", context: error)
                    HUD.dismissLoading()
                    HUD.error(title: error.localizedDescription)
                }
            }
            return
        }

        guard selectedUser.count > 1 else {
            return
        }

        Task {
            do {
                HUD.loading()
                try await MultiBackupManager.shared.addKeyToAccount(with: selectedUser)
                HUD.dismissLoading()
            } catch {
                log.error("add new device failed", context: error)
                HUD.dismissLoading()
                // TODO: des
                HUD.error(title: "restore failed")
            }
        }
    }
}
