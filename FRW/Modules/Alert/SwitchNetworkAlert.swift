//
//  SwitchNetworkAlert.swift
//  FRW
//
//  Created by cat on 4/24/25.
//

import SwiftUI

extension AlertViewController {
    static func showSwitchNetworkAlert(_ callback: @escaping BoolClosure) {
        runOnMain {
            AlertViewController.presentOnRoot(
                title: .init("wrong_network_title".localized),
                customContentView: AnyView(
                    VStack(alignment: .center, spacing: 8) {
                        Text("wrong_network_des".localized)
                    }
                    .padding(.vertical, 8)
                ),
                buttons: [
                    AlertView.ButtonItem(type: .primaryAction, title: "switch_to_mainnet".localized, action: {
                        WalletManager.shared.changeNetwork(.mainnet)
                        callback(true)
                    }),

                    AlertView.ButtonItem(type: .normal, title: "action_cancel".localized, action: {
                        callback(false)
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
