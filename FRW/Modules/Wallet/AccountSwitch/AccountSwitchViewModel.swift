//
//  AccountSwitchViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 13/6/2023.
//

import Combine
import SwiftUI

// MARK: - AccountSwitchViewModel

class AccountSwitchViewModel: ObservableObject {
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
  
  private func updateList(_ list: [ProfileModel]) {
    self.profiles = ProfileManager.shared.showProfileList()
  }

  // MARK: Internal

  var selectedProfile: ProfileModel?

  @Published var profiles: [ProfileModel] = []

  func createNewAccountAction() {
    Router.route(to: RouteMap.ReactNative.profileSelection)
//    Router.route(to: RouteMap.Register.root(nil))
  }

  func loginAccountAction() {

    Router.route(to: RouteMap.RestoreLogin.restoreList)
  }

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

  // MARK: Private

  private var cancelSets = Set<AnyCancellable>()

}
