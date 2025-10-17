//
//  MoveAssetsAction.swift
//  FRW
//
//  Created by cat on 2024/6/13.
//

import Foundation

// MARK: - MoveAssetsAction

class MoveAssetsAction {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = MoveAssetsAction()

    var allowMoveAssets: Bool {
        true
    }

    var showNote: String? {
        guard let name = appName, !name.isEmpty else {
            return nil
        }
        return "move_asset_browser_title_x".localized(name)
    }

    var showCheckOnMoveAsset: Bool {
        browserCallback != nil
    }

    func startBrowserWithMoveAssets(appName: String?, callback: @escaping EmptyClosure) {
      callback()
    }

    func endBrowser() {
        browserCallback?()
        browserCallback = nil
        appName = ""
    }

    // MARK: Private

    private var browserCallback: EmptyClosure?
    private var appName: String?
}

extension MoveAssetsAction {}
