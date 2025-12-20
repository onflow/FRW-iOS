//
//  RestoreWalletViewModel.swift
//  Flow Wallet
//
//  Created by Hao Fu on 1/1/22.
//

import Foundation

// MARK: - RestoreWalletViewModel

class RestoreWalletViewModel {}

// MARK: - Action

extension RestoreWalletViewModel {
    func restoreWithManualAction() {
        Router.route(to: RouteMap.RestoreLogin.seedPhrase)
//        Router.route(to: RouteMap.RestoreLogin.restoreManual)
    }

    func restoreWithCloudAction(type: BackupManager.BackupType) {
        HUD.loading()

        Task {
            do {
                let items = try await BackupManager.shared.getCloudDriveItems(from: type)
                HUD.dismissLoading()

                if items.isEmpty {
                    HUD.error(title: "no_x_backup".localized(type.descLocalizedString))
                    return
                }

                Router.route(to: RouteMap.RestoreLogin.chooseAccount(items, type))
            } catch BackupError.fileIsNotExistOnCloud {
                HUD.dismissLoading()
                HUD.error(title: "no_x_backup".localized(type.descLocalizedString))
            } catch {
                HUD.dismissLoading()
                HUD.error(title: "restore_with_x_failed".localized(type.descLocalizedString))
            }
        }
    }

    func restoreWithKeyStore() {
        Router.route(to: RouteMap.RestoreLogin.keystore)
    }

    func resteroWithPrivateKey() {
        Router.route(to: RouteMap.RestoreLogin.privateKey(nil))
    }
}
