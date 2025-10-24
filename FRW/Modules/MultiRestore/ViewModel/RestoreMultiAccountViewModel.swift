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
      log.debug("🟢 [RestoreMultiAccountVM] onClickUser called with index: \(index)")
        guard index < items.count else {
          log.debug("⚠️ [RestoreMultiAccountVM] Invalid index: \(index), items count: \(items.count)")
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
          log.debug("ℹ️ [RestoreMultiAccountVM] Already current user, popping to root")
            Router.popToRoot()
            return
        }

        // If it is in the login list, switch user

        if ProfileManager.shared.hasProfile(userId: selectedUserId) {
          log.debug("🔄 [RestoreMultiAccountVM] Switching to existing user: \(selectedUserId)")
            Task {
                do {
                    HUD.loading()
                    try await UserManager.shared.switchAccount(withUID: selectedUserId)
                    MultiAccountStorage.shared.setBackupType(.multi, uid: selectedUserId)
                    HUD.dismissLoading()
                } catch LLError.accountNotFound {
                  addKey(item: selectedUser)
                } catch {
                  log.error("switch account failed", context: error)
                  HUD.dismissLoading()
                  HUD.error(title: error.localizedDescription)
                  return
                }
            }
            return
        }

        guard selectedUser.count > 1 else {
            return
        }

        addKey(item: selectedUser)
    }
  
  private func addKey(item: [MultiBackupManager.StoreItem]) {
    Task {
        do {
            HUD.loading()
            try await MultiBackupManager.shared.addKeyToAccount(with: item)
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
