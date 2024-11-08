//
//  MultiBackupVerifyPinViewModel.swift
//  FRW
//
//  Created by cat on 2024/2/6.
//

import Foundation
import SwiftUI
import UIKit

extension MultiBackupVerifyPinViewModel {
    typealias VerifyCallback = (Bool, String) -> Void
    enum From {
        case backup
        case restore
    }
}

class MultiBackupVerifyPinViewModel: ObservableObject {
    @Published var inputPin: String = ""
    @Published var pinCodeErrorTimes: Int = 0

    var from: MultiBackupVerifyPinViewModel.From
    var callback: MultiBackupVerifyPinViewModel.VerifyCallback?

    private lazy var generator: UINotificationFeedbackGenerator = {
        let obj = UINotificationFeedbackGenerator()
        return obj
    }()

    private var isBionicVerifing: Bool = false
    private var canVerifyBionicAutomatically = true

    init(from: MultiBackupVerifyPinViewModel.From,
         callback: MultiBackupVerifyPinViewModel.VerifyCallback?)
    {
        self.callback = callback
        self.from = from
    }

    var desc: String {
        if from == .backup {
            return "pin_hint_for_backup".localized
        } else {
            return "pin_hint_for_create".localized
        }
    }
}

extension MultiBackupVerifyPinViewModel {
    func verifyPinAction() {
        if from == .backup {
            verifyBackupPin()
        } else {
            verifyRestorePin()
        }
    }

    private func verifyBackupPin() {
        let result = SecurityManager.shared.authPinCode(inputPin)
        if !result {
            pinVerifyFailed()
            return
        }

        verifySuccess()
    }

    private func verifyRestorePin() {
        if let customCallback = callback {
            customCallback(true, inputPin)
            Router.pop()
        }
    }

    private func pinVerifyFailed() {
        generator.notificationOccurred(.error)

        inputPin = ""
        withAnimation(.default) {
            pinCodeErrorTimes += 1
        }
    }

    private func verifySuccess() {
        if let customCallback = callback {
            customCallback(true, inputPin)
        }
    }
}
