//
//  RouteMap+ImportWallet.swift
//  FRW
//
//  Created by cat on 6/24/25.
//

import SwiftUI
import UIKit

extension RouteMap {
    enum ImportWallet {
        case account
        case profile
        case multibackList(ImportWalletViewModel)
    }
}

extension RouteMap.ImportWallet: RouterTarget {
    func onPresent(navi: UINavigationController) {
        switch self {
        case .account:
            let viewModel = ImportWalletViewModel(importType: .account)
            navi.push(content: ImportWalletView(viewModel: viewModel))
        case .profile:
            let viewModel = ImportWalletViewModel(importType: .profile)
            navi.push(content: ImportWalletView(viewModel: viewModel))
        case let .multibackList(viewModel):
            navi.push(content: ImportFromMultiBackupView(viewModel))
        }
    }
}
