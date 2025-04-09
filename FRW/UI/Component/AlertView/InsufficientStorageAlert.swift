//
//  InsufficientStorageAlert.swift
//  FRW
//
//  Created by Antonio Bello on 11/26/24.
//

import SwiftUI

extension AlertViewController {
    static func showInsufficientStorageError(minimumBalance: Double) {
        showStorageAlert(
            minimumBalance: minimumBalance,
            titleRes: "insufficient_storage::error::title",
            firstContentRes: "insufficient_storage::error::content::first",
            secondContentRes: "insufficient_storage::error::content::second",
            thirdContentRes: "insufficient_storage::error::content::third"
        )
    }

    static func showInsufficientStorageWarningBefore(minimumBalance: Double) {
        showStorageAlert(
            minimumBalance: minimumBalance,
            titleRes: "insufficient_storage::warning::before::title",
            firstContentRes: "insufficient_storage::warning::before::content::first",
            secondContentRes: "insufficient_storage::warning::before::content::second",
            thirdContentRes: "insufficient_storage::warning::before::content::third"
        )
    }

    static func showInsufficientStorageWarningAfter(minimumBalance: Double) {
        showStorageAlert(
            minimumBalance: minimumBalance,
            titleRes: "insufficient_storage::warning::after::title",
            firstContentRes: "insufficient_storage::warning::after::content::first",
            secondContentRes: "insufficient_storage::warning::after::content::second",
            thirdContentRes: "insufficient_storage::warning::after::content::third"
        )
    }

    private static func showStorageAlert(minimumBalance: Double, titleRes: String, firstContentRes: String, secondContentRes: String, thirdContentRes: String) {
        runOnMain {
            AlertViewController.presentOnRoot(
                title: .init(titleRes.localized),
                customContentView: AnyView(
                    VStack(alignment: .center, spacing: 8) {
                        Text(.init(firstContentRes.localized))
                        Text(.init(secondContentRes.localized(minimumBalance)))
                            .foregroundColor(Color.LL.Button.Warning.background)
                        Text(.init(thirdContentRes.localized))
                            .padding(.top, 8)
                    }
                        .padding(.vertical, 8)
                ),
                buttons: [
                    AlertView.ButtonItem(type: .secondaryAction, title: "Deposit::message".localized, action: {
                        Router.route(to: RouteMap.Wallet.receiveQR)
                    }),
                    AlertView.ButtonItem(type: .primaryAction, title: "buy_flow".localized, action: {
                        Router.route(to: RouteMap.Wallet.buyCrypto)
                    })
                ],
                useDefaultCancelButton: false,
                showCloseButton: true,
                buttonsLayout: .horizontal,
                textAlignment: .center
            )
        }
    }
}
