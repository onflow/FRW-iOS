//
//  ImportWalletViewModel.swift
//  FRW
//
//  Created by cat on 6/19/25.
//

import Foundation

final class ImportWalletViewModel: ObservableObject {
    var importType: ImportType = .account

    init(importType: ImportType) {
        self.importType = importType
    }

    var title: String {
        importType == .account ? "import_account".localized : "import_profile".localized
    }
}

// MARK: - Import Account

extension ImportWalletViewModel {}

// MARK: - Import Profile

extension ImportWalletViewModel {}
