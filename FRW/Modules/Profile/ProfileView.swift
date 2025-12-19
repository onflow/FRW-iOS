//
//  ProfileView.swift
//  Flow Wallet-lite
//
//  Created by Hao Fu on 30/11/21.
//

import InstabugSDK
import Kingfisher
import SwiftUI

// MARK: - ProfileView + AppTabBarPageProtocol

extension ProfileView: AppTabBarPageProtocol {
  static func tabTag() -> AppTabType {
    .profile
  }

  static func iconName() -> String {
    "tabler-icon-settings"
  }

  static func title() -> String {
    "Settings::message".localized
  }
}

// MARK: - ProfileView

struct ProfileView: RouteableView {
  // MARK: Internal

  var title: String {
    ""
  }

  var isNavigationBarHidden: Bool {
    true
  }

  var body: some View {
    ZStack {
      ScrollView {
        VStack(spacing: 16) {
          if userManager.isLoggedIn {
            switchProfileTips
              .visibility(lud.switchProfileTipsFlag ? .gone : .visible)
            InfoContainerView()
            ActionSectionView()
            WalletConnectView()
          } else {
            NoLoginTipsView()
          }

          GeneralSectionView()
          DeveloperSectionView()

          if userManager.isLoggedIn {
            ProfileView.FreeGasSectionView()
          }
          ProfileView.AboutSectionView()
          if vm.state.isLogin {
            MoreSectionView()
          }

          Text("Version \(vm.buildVersion ?? "") (\(vm.version ?? ""))")
              .font(.inter(size: 13, weight: .regular))
              .foregroundColor(.LL.note.opacity(0.5))
              .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
      }
      .background(.clear)
      .buttonStyle(.plain)
    }
    .padding(.top, 16)
    .backgroundFill(.Theme.Background.white)
    .environmentObject(vm)
    .environmentObject(lud)
    .environmentObject(userManager)
    .applyRouteable(self)
    .tracedView(self)
  }

  // MARK: Private

  @StateObject
  private var vm = ProfileViewModel()
  @StateObject
  private var lud = LocalUserDefaults.shared
  @StateObject
  private var userManager = UserManager.shared
}

// MARK: ProfileView.NoLoginTipsView

extension ProfileView {
  struct NoLoginTipsView: View {
    // MARK: Internal

    var body: some View {
      Section {
        Button {
          Router.route(to: RouteMap.Register.root(nil))
        } label: {
          HStack {
            VStack {
              Image("icon-cool-cat")
            }.frame(maxHeight: .infinity, alignment: .top)

            VStack(alignment: .leading) {
              Text(title).font(.inter(size: 16, weight: .bold))
              Text(desc).font(.inter(size: 16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image("icon-orange-right-arrow")
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 16)
          .roundedBg(
            cornerRadius: 12,
            strokeColor: .LL.Primary.salmonPrimary,
            strokeLineWidth: 1
          )
        }
      }
      .listRowInsets(.zero)
      .listRowBackground(Color.clear)
      .background(.clear)
    }

    // MARK: Private

    private let title = "welcome_to_lilico".localized
    private let desc = "welcome_desc".localized
  }
}

// MARK: - Section user info

extension ProfileView {
  struct InfoContainerView: View {
    // MARK: Internal

    var jailbreakTipsView: some View {
      Button {
        Router.route(to: RouteMap.Wallet.jailbreakAlert)
      } label: {
        HStack(spacing: 8) {
          Image("icon-warning-mark")
            .renderingMode(.template)
            .foregroundColor(Color.LL.Warning.warning2)

          Text("jailbreak_alert_msg".localized)
            .font(.inter(size: 16, weight: .medium))
            .foregroundColor(Color.LL.Warning.warning2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)

          Image("icon-account-arrow-right")
            .renderingMode(.template)
            .foregroundColor(Color.LL.Warning.warning2)
        }
        .padding(.all, 18)
        .background(Color.LL.Warning.warning5)
        .cornerRadius(16)
      }
    }

    var body: some View {
      Section {
        VStack(spacing: 20) {
          Button {
            vm.showSwitchProfileAction()
          } label: {
            ProfileView.InfoView()
              .contentShape(Rectangle())
          }

          jailbreakTipsView
            .visibility(UIDevice.isJailbreak ? .visible : .gone)

          ProfileView.InfoActionView()
        }
      }
    }

    // MARK: Private

    @EnvironmentObject
    private var vm: ProfileViewModel
  }

  struct InfoView: View {
    // MARK: Internal

    var body: some View {
      HStack(spacing: 16) {
        KFImage.url(URL(string: userManager.userInfo?.avatar.convertedAvatarString() ?? ""))
          .placeholder {
            Image("placeholder")
              .resizable()
          }
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 40, height: 40)
          .cornerRadius(8)

        Text(userManager.userInfo?.nickname ?? "")
          .foregroundColor(Color.Brain.Text.primary)
          .font(.inter(size: 14, weight: .bold))

        Spacer()
        Button {
          Router.route(to: RouteMap.Profile.edit)
        } label: {
          Image("icon-profile-edit")
            .resizable()
            .frame(width: 24, height: 24)
            .padding(10)
            .background(Color.Brain.Light.lines10)
            .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
      }
    }

    // MARK: Private

    @EnvironmentObject
    private var userManager: UserManager
  }

  struct InfoActionView: View {
    var body: some View {
      HStack(alignment: .center, spacing: 0) {
        ProfileView.InfoActionButton(
          iconName: "icon-address",
          title: "addresses".localized
        ) {
          Router.route(to: RouteMap.Profile.addressBook)
        }

        ProfileView.InfoActionButton(
          iconName: "icon-wallet",
          title: "wallets".localized
        ) {
          Router.route(to: RouteMap.Profile.accountList)
        }
      }
      .padding(18)
      .profileStyle()
      .cornerRadius(16)
    }
  }

  struct InfoActionButton: View {
    let iconName: String
    let title: String
    let action: () -> Void

    var body: some View {
      Button(action: action) {
        VStack {
          Image(iconName)
            .renderingMode(.template)
            .foregroundStyle(Color.Brain.System.green)

          Text(title)
            .foregroundColor(Color.Brain.Text.primary)
            .font(.inter(size: 14))
        }
      }
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity)
    }
  }
}

// MARK: ProfileView.ActionSectionView

extension ProfileView {
  struct ActionSectionView: View {
    // MARK: Internal

    enum Row {
      case backup(ProfileViewModel)
      case security
      case linkedAccount
    }

    var body: some View {
      VStack {
        Section {
          if !vm.isLinkedAccount {
            Button {
              guard vm.state.backupFetchingState != .fetching else {
                return
              }
              if !isDevModel, currentNetwork != .mainnet {
                showAlert = true
              } else {
                let wallet = WalletManager.shared
                if wallet.keyProvider?.keyType == .seedPhrase, vm.state.backupFetchingState == .none {
                  Router.route(to: RouteMap.Profile.RecoveryPhraseBackup)
                } else {
                  Router.route(to: RouteMap.Backup.backupList)
                }
              }
            } label: {
              ProfileView.SettingItemCell(
                iconName: Row.backup(vm).iconName,
                title: Row.backup(vm).title,
                style: Row.backup(vm).style,
                desc: Row.backup(vm).desc,
                imageName: Row.backup(vm).imageName,
                sysImageColor: Row.backup(vm).sysImageColor
              )
            }
            .alert("wrong_network_title".localized, isPresented: $showAlert) {
              Button("switch_to_mainnet".localized) {
                WalletManager.shared.changeNetwork(.mainnet)
              }
              Button("action_cancel".localized, role: .cancel) {}
            } message: {
              Text("wrong_network_des".localized)
            }

            Divider().background(Color.LL.Neutrals.background)
          }

          Button {
            vm.securityAction()
          } label: {
            ProfileView.SettingItemCell(
              iconName: Row.security.iconName,
              title: Row.security.title,
              style: Row.security.style,
              desc: Row.security.desc
            )
          }
        }
      }
      .profileStyle()
      .cornerRadius(16)
    }

    // MARK: Private

    @EnvironmentObject
    private var vm: ProfileViewModel
    @State
    private var showAlert = false
  }
}

// MARK: ProfileView.WalletConnectView

extension ProfileView {
  struct WalletConnectView: View {
    // MARK: Internal

    enum Row {
      case walletConnect
      case devices
    }

    var body: some View {
      VStack {
        Section {
          if !vm.isLinkedAccount {
            Button {
              Router.route(to: RouteMap.Profile.walletConnect)
            } label: {
              ProfileView.SettingItemCell(
                iconName: Row.walletConnect.iconName,
                title: Row.walletConnect.title,
                style: Row.walletConnect.style,
                desc: Row.walletConnect.desc,
                imageName: Row.walletConnect.imageName,
                sysImageColor: Row.walletConnect.sysImageColor
              )
            }
            .buttonStyle(ScaleButtonStyle())

            Divider().background(Color.LL.Neutrals.background)
          }

          Button {
            Router.route(to: RouteMap.Profile.devices)
          } label: {
            ProfileView.SettingItemCell(
              iconName: Row.devices.iconName,
              title: Row.devices.title,
              style: Row.devices.style,
              desc: Row.devices.desc,
              imageName: Row.devices.imageName,
              sysImageColor: Row.devices.sysImageColor
            )
          }
        }
      }
      .profileStyle()
      .cornerRadius(16)
    }

    // MARK: Private

    @EnvironmentObject
    private var vm: ProfileViewModel
  }
}

extension ProfileView.WalletConnectView.Row {
  var iconName: String {
    switch self {
      case .walletConnect:
        "profile-icon-wc"
      case .devices:
        "profile-icon-device"
    }
  }

  var title: String {
    switch self {
      case .walletConnect:
        "walletconnect".localized
      case .devices:
        "devices".localized
    }
  }

  var style: ProfileView.SettingItemCell.Style {
    switch self {
      case .walletConnect:
        .arrow
      case .devices:
        .arrow
    }
  }

  var desc: String {
    ""
  }

  var sysImageColor: Color {
    .clear
  }

  var imageName: String {
    ""
  }
}

extension ProfileView.ActionSectionView.Row {
  var iconName: String {
    switch self {
      case .backup:
        "icon-backup"
      case .security:
        "icon-security"
      case .linkedAccount:
        "icon-linked-account"
    }
  }

  var title: String {
    switch self {
      case .backup:
        "backup".localized
      case .security:
        "security".localized
      case .linkedAccount:
        "linked_account".localized
    }
  }

  var style: ProfileView.SettingItemCell.Style {
    switch self {
      case let .backup(vm):
        switch vm.state.backupFetchingState {
        case .fetching:
          return .progress
        default:
          return .arrow
        }

      case .security:
        return .arrow
      case .linkedAccount:
        return .arrow
    }
  }

  var desc: String {
    switch self {
      case .backup:
        ""
      case .security:
        ""
      case .linkedAccount:
        ""
    }
  }

  var imageName: String {
    switch self {
      case .backup:
        ""

      default:
        ""
    }
  }

  var sysImageColor: Color {
    switch self {
      case .backup:
        .clear
      default:
        .clear
    }
  }
}

// MARK: - ProfileView.GeneralSectionView

extension ProfileView {
  struct GeneralSectionView: View {
    // MARK: Internal

    enum Row: Hashable {
      case notification
      case currency
      case theme
    }

    var body: some View {
      VStack {
        Section {
          // Hide notification
          ForEach([Row.notification, Row.currency, Row.theme], id: \.self) { row in

            if row == Row.notification {
              Button {
                vm.showSystemSettingAction()
              } label: {
                ProfileView
                  .SettingItemCell(
                    iconName: row.iconName,
                    title: row.title,
                    style: row.style,
                    toggle: vm.state.isPushEnabled
                  )
              }
            } else {
              Button {
                switch row {
                  case .theme:
                    Router.route(to: RouteMap.Profile.themeChange)
                  case .currency:
                    Router.route(to: RouteMap.Profile.currency)
                  default:
                    break
                }
              } label: {
                ProfileView.SettingItemCell(
                  iconName: row.iconName,
                  title: row.title,
                  style: row.style,
                  desc: row.desc(with: vm),
                  toggle: row.toggle
                )
              }
            }

            if row != .theme {
              Divider().background(Color.LL.Neutrals.background)
            }
          }
        }
      }
      .profileStyle()
      .cornerRadius(16)
    }

    // MARK: Private

    @EnvironmentObject
    private var vm: ProfileViewModel
  }
}

extension ProfileView.GeneralSectionView.Row {
  var iconName: String {
    switch self {
      case .notification:
        "profile-icon-note"
      case .currency:
        "icon-currency"
      case .theme:
        "icon-theme"
    }
  }

  var title: String {
    switch self {
      case .currency:
        "currency".localized
      case .theme:
        "theme".localized
      case .notification:
        "notifications".localized
    }
  }

  var style: ProfileView.SettingItemCell.Style {
    switch self {
      case .currency:
        .desc
      case .theme:
        .desc
      case .notification:
        .toggle
    }
  }

  var toggle: Bool {
    switch self {
      case .currency:
        false
      case .theme:
        false
      default:
        false
    }
  }

  func desc(with vm: ProfileView.ProfileViewModel) -> String {
    switch self {
      case .currency:
        vm.state.currency
      case .theme:
        vm.state.colorScheme?.desc ?? "auto".localized
      default:
        ""
    }
  }
}

// MARK: - ProfileView.DeveloperSectionView

extension ProfileView {
  struct DeveloperSectionView: View {
    enum Row {
      case instabug
      case developerMode(LocalUserDefaults)
      case plugin
    }

    @EnvironmentObject
    var lud: LocalUserDefaults

    var body: some View {
      VStack {
        Section {
          let dm = Row.developerMode(lud)

          Button {
            Instabug.show()
          } label: {
            ProfileView.SettingItemCell(
              iconName: Row.instabug.iconName,
              title: Row.instabug.title,
              style: Row.instabug.style
            )
          }

          Button {
            Router.route(to: RouteMap.Profile.developer)
          } label: {
            ProfileView.SettingItemCell(
              iconName: dm.iconName,
              title: dm.title,
              style: dm.style,
              desc: dm.desc,
              toggle: dm.toggle
            )
          }

          Divider().background(Color.LL.Neutrals.background)

          Button {
            UIApplication.shared
              .open(
                URL(
                  string: "https://chrome.google.com/webstore/detail/lilico/hpclkefagolihohboafpheddmmgdffjm"
                )!
              )
          } label: {
            ProfileView.SettingItemCell(
              iconName: Row.plugin.iconName,
              title: Row.plugin.title,
              style: Row.plugin.style,
              desc: Row.plugin.desc,
              toggle: Row.plugin.toggle,
              imageName: Row.plugin.imageName,
              sysImageColor: Row.plugin.sysImageColor
            )
          }
        }
      }
      .profileStyle()
      .cornerRadius(16)
    }
  }
}

extension ProfileView.DeveloperSectionView.Row {
  var iconName: String {
    switch self {
      case .instabug:
        "icon-instabug"
      case .plugin:
        "icon-plugin"
      case .developerMode:
        "icon-developer-mode"
    }
  }

  var title: String {
    switch self {
      case .instabug:
        "bug_report".localized
      case .plugin:
        "Chrome Extension"
      case .developerMode:
        "developer_mode".localized
    }
  }

  var style: ProfileView.SettingItemCell.Style {
    switch self {
      case .instabug:
        .none
      case .plugin:
        .sysImage
      case .developerMode:
        .desc
    }
  }

  var desc: String {
    switch self {
      case .instabug:
        ""
      case .plugin:
        ""
      case let .developerMode(lud):
        lud.network.rawValue.capitalized
    }
  }

  var toggle: Bool {
    switch self {
      case .instabug:
        false
      case .plugin:
        false
      case .developerMode:
        false
    }
  }

  var imageName: String {
    switch self {
      case .instabug:
        ""
      case .plugin:
        "arrow.up.right"
      case .developerMode:
        ""
    }
  }

  var sysImageColor: Color {
    switch self {
      case .instabug:
        Color.clear
      case .plugin:
        Color.LL.note
      case .developerMode:
        Color.clear
    }
  }
}

// MARK: - ProfileView.FreeGasSectionView

extension ProfileView {
  struct FreeGasSectionView: View {
    // MARK: Internal

    enum Row {
      case gas
    }

    var body: some View {
      VStack(alignment: .leading) {
        Section {
          Button {} label: {
            ProfileView.SettingItemCell(
              iconName: FreeGasSectionView.Row.gas.iconName,
              title: FreeGasSectionView.Row.gas.title,
              style: FreeGasSectionView.Row.gas.style,
              toggle: localGreeGas
            ) { toggle in
              localGreeGas = toggle
            }
            .disabled(!RemoteConfigManager.shared.remoteGreeGas)
          }
          .profileStyle()
          .cornerRadius(16)

          Text("* " + "gas_fee_desc".localized)
            .font(.inter(size: 12))
            .foregroundStyle(Color.Brain.Text.secondary)
            .lineLimit(2)
        }
      }
    }

    // MARK: Private

    @AppStorage(LocalUserDefaults.Keys.freeGas.rawValue)
    private var localGreeGas = true
  }
}

extension ProfileView.FreeGasSectionView.Row {
  var iconName: String {
    switch self {
      case .gas:
        ""
    }
  }

  var title: String {
    switch self {
      case .gas:
        "free_gas_fee".localized
    }
  }

  var style: ProfileView.SettingItemCell.Style {
    switch self {
      case .gas:
        .toggle
    }
  }
}

// MARK: - ProfileView.AboutSectionView

extension ProfileView {
  struct AboutSectionView: View {
    enum Row {
      case about
    }

    var body: some View {
      VStack {
        Section {
          Button {
            Router.route(to: RouteMap.Profile.about)
          } label: {
            ProfileView.SettingItemCell(
              iconName: Row.about.iconName,
              title: Row.about.title,
              style: Row.about.style,
              desc: Row.about.desc
            )
          }
        }
      }
      .profileStyle()
      .cornerRadius(16)
    }
  }
}

extension ProfileView.AboutSectionView.Row {
  var iconName: String {
    switch self {
      case .about:
        "icon-about"
    }
  }

  var title: String {
    switch self {
      case .about:
        "about".localized
    }
  }

  var style: ProfileView.SettingItemCell.Style {
    switch self {
      case .about:
        .arrow
    }
  }

  var desc: String {
    switch self {
      case .about:
        "about".localized
    }
  }
}

// MARK: - ProfileView.MoreSectionView

extension ProfileView {
  struct MoreSectionView: View {
    enum Row: CaseIterable {
      case switchAccount
    }

    var body: some View {
      VStack {
        Section {
          ForEach(Row.allCases, id: \.self) {
            ProfileView.SettingItemCell(
              iconName: $0.iconName,
              title: $0.title,
              style: $0.style,
              desc: $0.desc,
              toggle: $0.toggle
            )
          }
        }
      }
      .profileStyle()
    }
  }
}

extension ProfileView.MoreSectionView.Row {
  var iconName: String {
    switch self {
      case .switchAccount:
        "icon-switch-account"
    }
  }

  var title: String {
    switch self {
      case .switchAccount:
        "switch_account".localized
    }
  }

  var style: ProfileView.SettingItemCell.Style {
    switch self {
      case .switchAccount:
        .none
    }
  }

  var desc: String {
    switch self {
      case .switchAccount:
        ""
    }
  }

  var toggle: Bool {
    switch self {
      case .switchAccount:
        false
    }
  }
}

// MARK: - Component

extension ProfileView {
  struct SettingItemCell: View {
    enum Style {
      case none
      case desc
      case arrow
      case toggle
      case image
      case sysImage
      case progress
    }

    let iconName: String
    let title: String
    let style: Style

    var desc: String? = ""
    @State
    var toggle: Bool = false
    var imageName: String? = ""
    var toggleAction: ((Bool) -> Void)? = nil
    var sysImageColor: Color? = nil

    var body: some View {
      HStack {
        if !iconName.isEmpty {
          Image(iconName)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundStyle(Color.Brain.Primary.main)
        }

        Text(title)
          .font(.inter(size: 16, weight: .bold))
          .frame(maxWidth: .infinity, alignment: .leading)

        Text(desc ?? "")
          .font(.inter(size: 12))
          .foregroundColor(Color.Brain.Text.secondary)
          .visibility(style == .desc ? .visible : .gone)
        Image("icon-black-right-arrow")
          .renderingMode(.template)
          .foregroundColor(Color.Brain.Core.cards)
          .visibility(style == .arrow ? .visible : .gone)
        Toggle(isOn: $toggle) {}
          .tint(.LL.Primary.salmonPrimary)
          .visibility(style == .toggle ? .visible : .gone)
          .onChange(of: toggle) { value in
            if let action = toggleAction {
              action(value)
            }
          }

        if let imageName = imageName, style == .image {
          Image(imageName)
        }

        if let imageName = imageName, let sysImageColor = sysImageColor,
           style == .sysImage {
          Image(systemName: imageName)
            .foregroundColor(sysImageColor)
        }

        if style == .progress {
          ProgressView()
            .progressViewStyle(.circular)
        }
      }
      .padding(.vertical, 16)
      .contentShape(Rectangle())
      .backgroundFill(Color.Brain.Core.cards)
    }
  }

  var switchProfileTips: some View {
    VStack(spacing: 0) {
      HStack(spacing: 5) {
        Image("light-tips-icon")
          .renderingMode(.template)
          .foregroundStyle(Color.Theme.Accent.green)

        Text("switch_profile_tips".localized)
          .font(.inter(size: 12))
          .foregroundColor(Color.Theme.Accent.green)
          .multilineTextAlignment(.leading)

        Spacer()

        Button {
          LocalUserDefaults.shared.switchProfileTipsFlag = true
        } label: {
          Image("icon-close-tips")
            .renderingMode(.template)
            .foregroundColor(Color.Theme.Accent.green)
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
        }
      }
      .padding(.vertical, 3)
      .padding(.leading, 18)
      .padding(.trailing, 8)
      .background {
        RoundedRectangle(cornerRadius: 8)
          .foregroundColor(Color.Theme.Accent.green.opacity(0.16))
      }

      Image("icon-tips-bottom-arrow")
        .renderingMode(.template)
        .foregroundColor(Color.Theme.Accent.green.opacity(0.16))
    }
  }
}

// MARK: - ProfileStyle

// MARK: -

fileprivate struct ProfileStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .buttonStyle(PressButtonStyle())
      .padding(.horizontal, 18)
      .background(Color.Brain.Core.cards)
  }
}

// MARK: - ProfileContentStyle

fileprivate struct ProfileContentStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.vertical, 16)
  }
}

extension View {
  fileprivate func profileStyle() -> some View {
    modifier(ProfileStyle())
  }

  fileprivate func contentStyle() -> some View {
    modifier(ProfileContentStyle())
  }
}

#Preview {
  ProfileView()
}
