//
//  AccountSwitchViewModel.swift
//  Flow Wallet
//
//  Created by Selina on 13/6/2023.
//

import Combine
import SwiftUI

// MARK: - AccountSwitchViewModel.Placeholder

extension AccountSwitchViewModel {
  struct Placeholder {
    let uid: String
    let avatar: String
    let username: String
    let address: String
  }
}

// MARK: - AccountSwitchViewModel

class AccountSwitchViewModel: ObservableObject {
  // MARK: Lifecycle

  init() {

    UserManager.shared.$loginUIDList
      .receive(on: DispatchQueue.main)
      .map { $0 }
      .sink { [weak self] list in
        guard let self = self else { return }
        self.placeholders = self.buildPlaceholder(list: list)
      }.store(in: &cancelSets)
    
    ProfileManager.shared.$profiles
      .receive(on: DispatchQueue.main)
      .map { $0 }
      .sink { [weak self] list in
        guard let self = self else { return }
        self.updateList(list)
      }.store(in: &cancelSets)
  }
  
  private func updateList(_ list: [ProfileModel]) {
    var index = 0
    let showList = ProfileManager.shared.showProfileList()
    let result = showList.map { model in
      index += 1
      if model.username == nil {
        return model.updated(username: "Profile \(index)")
      }
      return model
    }
    
    self.profiles = result
  }

  // MARK: Internal

  @Published
  var placeholders: [Placeholder] = []
  var selectedProfile: ProfileModel?

  @Published var profiles: [ProfileModel] = []

  func createNewAccountAction() {
    Router.route(to: RouteMap.Register.root(nil))
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
  
//  func switchAccountAction(_ uid: String) {
//    Task {
//      do {
//        HUD.loading()
//        try await UserManager.shared.switchAccount(withUID: uid)
//        HUD.dismissLoading()
//      } catch {
//        log.error("switch account failed", context: error)
//        HUD.dismissLoading()
//        HUD.error(title: error.localizedDescription)
//      }
//    }
//  }

  // MARK: Private

  private var cancelSets = Set<AnyCancellable>()

  private func buildPlaceholder(list: [String]) -> [AccountSwitchViewModel.Placeholder] {
    []
//    var index = 1
//    let userStoreList = LocalUserDefaults.shared.userList
//    
//
//    let placeholders = filterUserList.map { uid in
//      let userInfo = MultiAccountStorage.shared.getUserInfo(uid)
//      var address = MultiAccountStorage.shared.getWalletInfo(uid)?
//        .getNetworkWalletModel(network: .mainnet)?.getAddress ?? "0x"
//      if address == "0x" {
//        address = LocalUserDefaults.shared.userAddressOfDeletedApp[uid] ?? "0x"
//      }
//      if address == "0x" {
//        let userStore = userStoreList.last { $0.userId == uid }
//        address = userStore?.address ?? "0x"
//      }
//      var username = userInfo?.nickname ?? userInfo?.username
//      if username == nil {
//        username = "Profile \(index)"
//        index += 1
//      }
//
//      return Placeholder(
//        uid: uid,
//        avatar: userInfo?.avatar ?? "",
//        username: username ?? "",
//        address: address
//      )
//    }
//    return placeholders
  }
}
