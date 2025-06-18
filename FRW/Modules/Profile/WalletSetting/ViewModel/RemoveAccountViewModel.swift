//
//  RemoveAccountViewModel.swift
//  FRW
//
//  Created by cat on 6/18/25.
//

import FlowWalletKit
import Foundation

struct RemoveWalletModel {
    enum RemoveType {
        case account
        case profile
    }

    var removeType: RemoveType = .account
    var navTitle: String = ""
    var alertTitle: String = ""
    var alertMessage: String = ""
    var alertConfirm: String = ""

    var hintTitle: String = ""
    var hintDesc: String = ""

    var hintConfirm1: String = ""
    var hintConfirm: String = ""
    var hintConfirm3: String = ""

    var buttonTitle: String = ""

    static let account = RemoveWalletModel(
        removeType: .account,
        navTitle: "remove_account".localized,
        alertTitle: "reset_warning_alert_title".localized,
        alertMessage: "delete_warning_alert_desc".localized,
        alertConfirm: "remove_account".localized,
        hintTitle: "remove_account_title".localized,
        hintDesc: "remove_account_desc".localized,
        hintConfirm1: "remove_account_desc_1".localized,
        hintConfirm: "remove_account_desc_2".localized,
        hintConfirm3: "remove_account_desc_3".localized,
        buttonTitle: "remove_account".localized
    )

    static let profile = RemoveWalletModel(
        removeType: .profile,
        navTitle: "remove_profile".localized,
        alertTitle: "reset_warning_alert_title".localized,
        alertMessage: "delete_warning_alert_desc".localized,
        alertConfirm: "delete_wallet".localized,
        hintTitle: "remove_profile_title".localized,
        hintDesc: "remove_profile_desc".localized,
        hintConfirm1: "remove_account_desc_1".localized,
        hintConfirm: "remove_profile_desc_2".localized,
        hintConfirm3: "remove_account_desc_3".localized,
        buttonTitle: "remove_account".localized
    )
}

class RemoveWalletViewModel: ObservableObject {
    @Published var text: String = ""
    var data: RemoveWalletModel
    var account: AccountInfoProtocol?

    init(account: AccountInfoProtocol?) {
        self.account = account
        if account != nil {
            data = .account
        } else {
            data = .profile
        }
    }

    func removeAccount() {
        if text != data.hintConfirm {
            HUD.error(title: "reset_warning_text".localized)
            return
        }

        HUD.showAlert(
            title: data.alertTitle,
            msg: data.alertMessage,
            cancelAction: {},
            confirmTitle: data.alertConfirm,
            confirmIsDestructive: true
        ) {
            self.removeAction()
        }
    }

    private func removeAction() {
        if data.removeType == .account {
            removeAccountAction()
        } else {
            removeProfileAction()
        }
    }

    private func removeAccountAction() {
//        HUD.loading()
        // TODO: #multi-account #six
//        Task {
//            do {
//                try await UserManager.shared.reset()
//                HUD.dismissLoading()
//            } catch {
//                log.error("reset failed", context: error)
//                HUD.dismissLoading()
//            }
//        }
    }

    private func removeProfileAction() {
        // TODO: #multi-account #six
        log.debug("---")
    }
}
