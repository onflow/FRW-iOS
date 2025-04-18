//
//  HUDManager.swift
//  Flow Wallet
//
//  Created by Hao Fu on 4/1/22.
//

import SPIndicator
import SwiftUI
import UIKit

class HUD {
    static func present(
        title: String,
        message: String? = nil,
        preset: SPIndicatorIconPreset = .done,
        haptic: SPIndicatorHaptic = .success,
        from _: SPIndicatorPresentSide = .top
    ) {
        DispatchQueue.main.async {
            SPIndicator.present(
                title: title,
                message: message,
                preset: preset,
                haptic: haptic,
                from: .top,
                completion: nil
            )
        }
    }

    static func info(title: String, message: String? = nil, from _: SPIndicatorPresentSide = .top) {
        DispatchQueue.main.async {
            SPIndicator.present(title: title, message: message, haptic: .error)
        }
    }

    static func success(
        title: String,
        message: String? = nil,
        preset: SPIndicatorIconPreset = .done,
        haptic: SPIndicatorHaptic = .success
    ) {
        HUD.present(title: title, message: message, preset: preset, haptic: haptic)
    }

    static func error(
        title: String,
        message: String? = nil,
        preset: SPIndicatorIconPreset = .error,
        haptic: SPIndicatorHaptic = .error
    ) {
        HUD.present(title: title, message: message, preset: preset, haptic: haptic)
    }
    
    static func error(
        _ error: any BaseError
    ) {
        log.error(error.errorLog)
        HUD.error(title: "Error Code: \(error.errorCode)", message: error.errorMessage)
    }

    static func debugSuccess(
        title: String,
        message: String? = nil,
        preset: SPIndicatorIconPreset = .done,
        haptic: SPIndicatorHaptic = .success
    ) {
        #if DEBUG
        HUD.present(title: title, message: message, preset: preset, haptic: haptic)
        #endif
    }

    static func debugError(
        title: String,
        message: String? = nil,
        preset: SPIndicatorIconPreset = .error,
        haptic: SPIndicatorHaptic = .error
    ) {
        #if DEBUG
        HUD.present(title: title, message: message, preset: preset, haptic: haptic)
        #endif
    }

    static func setupProgressHUD() {
        ProgressHUD.animationType = .lottie
        ProgressHUD.colorAnimation = UIColor.LL.Primary.salmonPrimary
        ProgressHUD.colorStatus = UIColor.LL.Primary.salmonPrimary
        ProgressHUD.fontStatus = .systemFont(ofSize: 19, weight: .medium)
    }

    static func loading(_ title: String = "", interaction: Bool = false) {
        ProgressHUD.show(title, interaction: interaction)
    }

    static func dismissLoading() {
        ProgressHUD.dismiss()
    }

    static func showAlert(
        title: String,
        msg: String,
        cancelTitle: String = "cancel".localized,
        cancelAction: @escaping () -> Void,
        confirmTitle: String,
        confirmIsDestructive: Bool = false,
        confirmAction: @escaping () -> Void
    ) {
        runOnMain {
            let alertVC = UIAlertController(title: title, message: msg, preferredStyle: .alert)

            let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
                cancelAction()
            }

            let okAction = UIAlertAction(title: confirmTitle, style: confirmIsDestructive ? .destructive : .default) { _ in
                confirmAction()
            }

            alertVC.addAction(cancelAction)
            alertVC.addAction(okAction)

            Router.topNavigationController()?.present(alertVC, animated: true)
        }
    }
}
