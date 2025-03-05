//
//  WalletSettingViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 24/10/2022.
//

import Flow
import SwiftUI

class WalletSettingViewModel: ObservableObject {
    @Published var storageUsedRatio: Double = 0
    @Published var storageUsedDesc: String = ""

    init() {
        fetchAccountInfo()
    }

    private func fetchAccountInfo() {
        Task {
            do {
                let info = try await FlowNetwork.checkAccountInfo()
                await MainActor.run {
                    self.storageUsedRatio = info.storageUsedRatio
                    self.storageUsedDesc = info.storageUsedString
                }
            } catch {
                
            }
        }
    }

    func resetWalletAction() {
        Router.route(to: RouteMap.Profile.resetWalletConfirm)
    }
}
