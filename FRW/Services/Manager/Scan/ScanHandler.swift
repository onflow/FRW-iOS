//
//  ScanHandler.swift
//  Flow Wallet
//
//  Created by Selina on 8/8/2022.
//

import SwiftUI
import UIKit

class ScanHandler {
    static func handler() -> SPQRCodeCallback {
        { data, vc in
            switch data {
            case let .walletConnect(string):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: {
                    DispatchQueue.main.async {
                        WalletConnectManager.shared.connect(link: string)
                    }
                })
            case let .flowWallet(address):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: {
                    let vaultIdentifier = LocalUserDefaults.shared.recentToken
                    guard let token = WalletManager.shared.getToken(by: vaultIdentifier) else {
                        return
                    }
                    let contract = Contact(
                        address: address,
                        avatar: nil,
                        contactName: "-",
                        contactType: .none,
                        domain: nil,
                        id: -1,
                        username: nil,
                        user: nil
                    )
                    Router.route(to: RouteMap.Wallet.sendAmount(contract, token, isPush: false))
                })
            case let .ethWallet(address):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: {
                    let vaultIdentifier = LocalUserDefaults.shared.recentToken
                    guard let token = WalletManager.shared.getToken(by: vaultIdentifier) else {
                        return
                    }
                    let contract = Contact(
                        address: address,
                        avatar: nil,
                        contactName: "-",
                        contactType: .none,
                        domain: nil,
                        id: -1,
                        username: nil,
                        user: nil
                    )
                    Router.route(to: RouteMap.Wallet.sendAmount(contract, token, isPush: false))
                })
            default:
                break
            }
        }
    }

    static func clickHandler() -> SPQRCodeCallback {
        { data, vc in
            switch data {
            case let .walletConnect(string):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: {
                    DispatchQueue.main.async {
                        WalletConnectManager.shared.connect(link: string)
                    }
                })
            case let .flowWallet(address):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: {
                    let vaultIdentifier = LocalUserDefaults.shared.recentToken
                    guard let token = WalletManager.shared.getToken(by: vaultIdentifier) else {
                        return
                    }
                    let contract = Contact(
                        address: address,
                        avatar: nil,
                        contactName: "-",
                        contactType: .none,
                        domain: nil,
                        id: -1,
                        username: nil,
                        user: nil
                    )
                    Router.route(to: RouteMap.Wallet.sendAmount(contract, token, isPush: false))
                })
            case let .text(text):
                UIPasteboard.general.string = text
                HUD.success(title: "copied".localized)
            case let .ethWallet(address):
                UIPasteboard.general.string = address
                HUD.success(title: "copied".localized)
            case let .url(url):
                vc.stopRunning()
                vc.presentingViewController?.dismiss(animated: true, completion: {
                    Router.route(to: RouteMap.Explore.browser(url))
                })
            }
        }
    }

    static func scan() {
        Router.route(to: RouteMap.Wallet.scan(
            ScanHandler.handler(),
            click: ScanHandler.clickHandler()
        ))
    }
}
