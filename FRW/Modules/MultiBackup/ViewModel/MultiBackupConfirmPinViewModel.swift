//
//  MultiBackupConfirmPinViewModel.swift
//  FRW
//
//  Created by cat on 2024/2/6.
//

import SwiftUI

class MultiBackupConfirmPinViewModel: ObservableObject {
    let lastPin: String
    @Published var pinCodeErrorTimes: Int = 0
    @Published var text: String = ""

    init(pin: String) {
        self.lastPin = pin
    }

    func onMatch(confirmPin: String) {
        if lastPin != confirmPin {
            text = ""
            withAnimation(.default) {
                pinCodeErrorTimes += 1
            }
            return
        }

        if !SecurityManager.shared.enablePinCode(confirmPin) {
            HUD.error(title: "enable_pin_code_failed".localized)
            return
        }
        HUD.success(title: "pin_code_enabled".localized)
        DispatchQueue.main.async {
            let list = MultiBackupManager.shared.backupList
            if list.count > 0 {
                Router.route(to: RouteMap.Backup.uploadMulti(list))
            }
        }
    }
}