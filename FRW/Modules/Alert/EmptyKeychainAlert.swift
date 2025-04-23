//
//  EmptyKeychainAlert.swift
//  FRW
//
//  Created by cat on 4/23/25.
//

import SwiftUI

extension AlertViewController {
    static func showEmptyKeychain() {
        runOnMain {
            AlertViewController.presentOnRoot(
                title: .init("Key Warning"),
                customContentView: AnyView(
                    VStack(alignment: .center, spacing: 8) {
                        Text(.init("restore_device_title".localized))
                    }
                    .padding(.vertical, 8)
                ),
                buttons: [
                    AlertView.ButtonItem(type: .secondaryAction, title: "tutorial".localized, action: {
                        if let url = URL(string: "https://docs.wallet.flow.com/tutorial/mobile-wallet-restore-guide#from-device-backup") {
                            Router.route(to: RouteMap.Explore.browser(url))
                        }
                    }),
                    AlertView.ButtonItem(type: .primaryAction, title: "btn_sync".localized, action: {
                        Router.route(to: RouteMap.RestoreLogin.syncQC)
                    }),
                ],
                useDefaultCancelButton: false,
                showCloseButton: true,
                buttonsLayout: .horizontal,
                textAlignment: .center
            )
        }
    }
}
