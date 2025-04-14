//
//  CreateProfileWaitingViewModel.swift
//  FRW
//
//  Created by cat on 2024/6/5.
//

import Combine
import Flow
import Foundation
import SwiftUI

class CreateProfileWaitingViewModel: ObservableObject {
    // MARK: Lifecycle

    deinit {
        EventTrack.Account.createdTimeEnd()
    }

    init(txId: String, callback: @escaping (_ succeeded: Bool, _ createBackup: Bool) -> Void) {
        self.txId = Flow.ID(hex: txId)
        self.callback = callback

        WalletManager.shared.$mainAccount
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { [weak self] account in
                if let _ = account {
                    self?.updateWalletInfo()
                    self?.createFinished = true
                    EventTrack.Account.createdTimeEnd()
                }
            }.store(in: &cancellableSet)
        EventTrack.Account.createdTimeStart()
    }

    // MARK: Internal

    @Published
    var animationPhase: AnimationPhase = .initial
    @Published
    var createFinished = false

    var txId = Flow.ID(hex: "")
    var callback: (_ succeeded: Bool, _ createBackup: Bool) -> Void

    private func onConfirm(createBackup: Bool) {
        HUD.success(title: "create_user_success".localized)
        callback(true, createBackup)
        LocalUserDefaults.shared.shouldShowConfettiOnHome = true
    }

    func onGoHome() {
        onConfirm(createBackup: false)
    }
    
    func onCreateBackup() {
        onConfirm(createBackup: true)
    }
    
    // MARK: Private

    private var cancellableSet = Set<AnyCancellable>()

    private func updateWalletInfo() {
        guard let uid = UserManager.shared.activatedUID, let address = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }
        LocalUserDefaults.shared.updateSEUser(by: uid, address: address)
    }
}
