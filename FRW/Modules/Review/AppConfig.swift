//
//  AppConfig.swift
//  FRW
//
//  Created by cat on 2024/7/2.
//

import Foundation

// MARK: - AppHide

enum AppHide {
    static var FTAdd: ViewVisibility {
        if isChildAccount {
            return .gone
        }
        return ViewVisibility.visible
    }

    static var NFTAdd: ViewVisibility {
        if isChildAccount {
            return .gone
        }
        return ViewVisibility.visible
    }

    static var swap: ViewVisibility {
        if isChildAccount {
            return .gone
        }
        return ViewVisibility.visible
    }

    static var stake: ViewVisibility {
        if isChildAccount {
            return .gone
        }
        return ViewVisibility.visible
    }

    static var backup: ViewVisibility {
        if isChildAccount {
            return .gone
        }
        return ViewVisibility.visible
    }
}

extension AppHide {
    private static var isChildAccount: Bool {
        WalletManager.shared.selectedChildAccount != nil
    }
}
