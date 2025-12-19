//
//  ProfileViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 23/5/2022.
//

import Combine
import Foundation
import SwiftUI

extension ProfileView {
    enum BackupFetchingState {
        case none
        case fetching
        case multiBackup
    }

    struct ProfileState {
        var isLogin: Bool = false
        var currency: String = CurrencyCache.cache.currentCurrency.rawValue
        var colorScheme: ColorScheme?
        var backupFetchingState: BackupFetchingState = .fetching
        var isPushEnabled: Bool = PushHandler.shared.isPushEnabled
    }

    enum ProfileInput {}

    class ProfileViewModel: ViewModel {
        // MARK: Lifecycle

        init() {
            state.colorScheme = ThemeManager.shared.style

            CurrencyCache.cache.$currentCurrency.sink { currency in
                DispatchQueue.main.async {
                    self.state.currency = currency.rawValue
                }
            }.store(in: &cancelSets)

            ThemeManager.shared.$style
              .receive(on: DispatchQueue.main)
              .sink(receiveValue: { [weak self] newScheme in
                  self?.state.colorScheme = newScheme
              }).store(in: &cancelSets)

            UserManager.shared.$activatedUID
                .receive(on: DispatchQueue.main)
                .map { $0 }
                .sink { [weak self] _ in
                    self?.refreshBackupState()
                }.store(in: &cancelSets)


            PushHandler.shared.$isPushEnabled
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .map { $0 }
                .sink { isEnabled in
                    self.state.isPushEnabled = isEnabled
                }.store(in: &cancelSets)

            WalletManager.shared.$mainAccount
                .receive(on: DispatchQueue.main)
                .map { $0 }
                .sink { [weak self] _ in
                    self?.refreshWalletAccountState()
                }.store(in: &cancelSets)
        }

        // MARK: Internal

        @Published
        var state = ProfileState()

        let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        let buildVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        @Published
        var isLinkedAccount = false

        func trigger(_: ProfileInput) {}

        // MARK: Private

        private var cancelSets = Set<AnyCancellable>()

        private func refreshBackupState() {
            guard UserManager.shared.activatedUID != nil else {
                state.backupFetchingState = .none
                return
            }
            guard WalletManager.shared.getPrimaryWalletAddress() != nil else {
                state.backupFetchingState = .none
                return
            }
            Task {
              let viewModel = BackupListViewModel()
              await viewModel.fetchMultiBackup()
              await MainActor.run {
                self.state.backupFetchingState = (viewModel.backupList.count >= 2) ? .multiBackup : .none
              }
            }
        }

        private func refreshWalletAccountState() {
            isLinkedAccount = WalletManager.shared.selectedChildAccount != nil
        }
    }
}

extension ProfileView.ProfileViewModel {
    func securityAction() {
        Task {
            let result = await SecurityManager.shared.SecurityVerify()
            if result {
                Router.route(to: RouteMap.Profile.security(true))
            }
        }
    }

    func linkedAccountAction() {
        Router.route(to: RouteMap.Profile.linkedAccount)
    }

    func showSwitchProfileAction() {
        Router.route(to: RouteMap.Profile.switchProfile)
    }

    func showSystemSettingAction() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    PushHandler.shared.requestPermission()
                } else {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
}
