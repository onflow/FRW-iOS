//
//  EmptyKeychainAlert.swift
//  FRW
//
//  Created by cat on 4/23/25.
//

import InstabugSDK
import SwiftUI

extension AlertViewController {
    static var lastTime: Date?
    static func showEmptyKeychain() {
        guard lastTime == nil else {
            return
        }
        lastTime = Date.now
        runOnMain {
            AlertViewController.presentOnRoot(
                title: .init("miss_key_title".localized),
                customContentView: AnyView(
                    VStack(alignment: .center, spacing: 8) {
                        Text("miss_key_body".localized)
                    }
                    .padding(.vertical, 8)
                ),
                buttons: [
                    AlertView.ButtonItem(type: .primaryAction, title: "restore_wallet".localized, action: {
                        Router.route(to: RouteMap.RestoreLogin.restoreList)
                    }),

                    AlertView.ButtonItem(type: .normal, title: "tutorial_restore".localized, action: {
                        if let url = URL(string: "https://docs.wallet.flow.com/tutorial/mobile-wallet-restore-guide#from-device-backup") {
                            Router.route(to: RouteMap.Explore.browser(url))
                        }
                    }),

                    AlertView.ButtonItem(type: .normal, title: "contact_us".localized, action: {
                        BugReporting.show(with: .question, options: [])
                    }),

                    AlertView.ButtonItem(type: .normal, title: "action_cancel".localized, action: {}),
                ],
                useDefaultCancelButton: false,
                showCloseButton: true,
                buttonsLayout: .vertical,
                textAlignment: .center
            )
        }
    }
}
