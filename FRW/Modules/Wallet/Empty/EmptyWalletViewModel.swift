//
//  EmptyWalletViewModel.swift
//  Flow Wallet
//
//  Created by Hao Fu on 25/12/21.
//

import Alamofire
import Combine
import Foundation
import SwiftUI

// MARK: - EmptyWalletViewModel

class EmptyWalletViewModel: ObservableObject {
  // MARK: Lifecycle

  init() {
    ProfileManager.shared.$profiles
      .receive(on: DispatchQueue.main)
      .map { $0 }
      .sink { [weak self] list in
        guard let self = self else { return }
        self.updateList(list)
      }.store(in: &cancelSets)
  }

  // MARK: Internal

  @Published
  var profiles: [ProfileModel] = []

  @Published
  var isLoading: Bool = false

  func switchAccount(_ profile: ProfileModel) {
    Task {
      do {
        HUD.loading()
        try await UserManager.shared.switchAccount(with: profile)
        HUD.dismissLoading()
      } catch {
        log.error("switch account failed", context: error)
        HUD.dismissLoading()
        HUD.error(title: error.localizedDescription)
      }
    }
  }

  func createNewAccountAction() {
    Router.route(to: RouteMap.Register.root(nil))
  }

  func loginAccountAction() {
    Router.route(to: RouteMap.RestoreLogin.restoreList)
  }

  func syncAccountAction() {
    Router.route(to: RouteMap.RestoreLogin.syncQC)
  }

  func tryToRestoreAccountWhenFirstLaunch() {
    if LocalUserDefaults.shared.tryToRestoreAccountFlag {
      // has been triggered or no old account to restore
      return
    }
    guard let isReachable = net?.isReachable else { return }

    if isReachable {
      net?.stopListening()
      restoreAccounts()
      return
    } else {
      net?.startListening(onQueue: .main, onUpdatePerforming: { status in
        log.info("[NET] network changed")
        switch status {
        case .reachable:
          self.restoreAccounts()
        default:
          log.info("[NET] not reachable")
        }
      })
    }
  }

  // MARK: Private

  private var cancelSets = Set<AnyCancellable>()
  private var net: NetworkReachabilityManager? = NetworkReachabilityManager()

  private func updateList(_ list: [ProfileModel]) {
    profiles = ProfileManager.shared.showProfileList()
  }

  private func restoreAccounts() {
    Task {
      await MainActor.run {
        isLoading = true
      }
      await UserManager.shared.tryToRestoreOldAccountOnFirstLaunch()
      await MainActor.run {
        isLoading = false
      }
    }
  }
}
