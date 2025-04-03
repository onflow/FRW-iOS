//
//  ProfileView.swift
//  Flow Wallet-lite
//
//  Created by Hao Fu on 30/11/21.
//

import Instabug
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
                    FeedbackView()
                    AboutSectionView()

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
    }
    
    @ViewBuilder
    static private var divider: some View {
        Divider()
            .background(Color.Theme.BorderLine.line)
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

// struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
////        ProfileView.NoLoginTipsView()
////        ProfileView.GeneralSectionView()
//        let model = ProfileView.ProfileViewModel()
//        ProfileView().environmentObject(model)
////        ProfileView.InfoView()
////        ProfileView.InfoActionView()
//    }
// }

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
                VStack(spacing: 24) {
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
            .background(.clear)
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
                    .frame(width: 82, height: 82)
                    .cornerRadius(41)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(userManager.userInfo?.nickname ?? "")
                            .foregroundColor(.LL.Neutrals.text)
                            .font(.inter(weight: .semibold))

                        Image("icon-switch-profile")
                            .renderingMode(.template)
                    }

//                    Text("@\(userManager.userInfo?.username ?? "")").foregroundColor(.LL.Neutrals.text).font(.inter(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Router.route(to: RouteMap.Profile.edit)
                } label: {
                    Image("icon-profile-edit")
                }
                .frame(size: CGSize(width: 36, height: 36))
                .roundedButtonStyle(bgColor: .clear)
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
                    Router.route(to: RouteMap.Profile.walletList)
                }
            }
            .padding(.vertical, 20)
            .borderStyle()
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
                        .foregroundStyle(Color.Theme.Accent.green)

                    Text(title).foregroundColor(.LL.Neutrals.note).font(.inter(
                        size: 12,
                        weight: .medium
                    ))
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
                            vm.linkedAccountAction()
                        } label: {
                            ProfileView.SettingItemCell(
                                iconName: Row.linkedAccount.iconName,
                                title: Row.linkedAccount.title,
                                style: Row.linkedAccount.style,
                                desc: Row.linkedAccount.desc
                            )
                        }
                        ProfileView.divider

                        Button {
                            if !isDevModel && LocalUserDefaults.shared.flowNetwork != .mainnet {
                                showAlert = true
                            } else {
                                Router.route(to: RouteMap.Backup.backupList)
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

                        ProfileView.divider
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
            .borderStyle()
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

                        ProfileView.divider
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
            .borderStyle()
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
            return "walletconnect"
        case .devices:
            return "devices"
        }
    }

    var title: String {
        switch self {
        case .walletConnect:
            return "walletconnect".localized
        case .devices:
            return "devices".localized
        }
    }

    var style: ProfileView.SettingItemCell.Style {
        switch self {
        case .walletConnect:
            return .arrow
        case .devices:
            return .arrow
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
            return "icon-backup"
        case .security:
            return "icon-security"
        case .linkedAccount:
            return "icon-linked-account"
        }
    }

    var title: String {
        switch self {
        case .backup:
            return "backup".localized
        case .security:
            return "security".localized
        case .linkedAccount:
            return "linked_account".localized
        }
    }

    var style: ProfileView.SettingItemCell.Style {
        switch self {
        case let .backup(vm):
            return .arrow
        case .security:
            return .arrow
        case .linkedAccount:
            return .arrow
        }
    }

    var desc: String {
        switch self {
        case let .backup(vm):
            switch vm.state.backupFetchingState {
            case .manually:
                return ""
            case .none:
                return ""
            default:
                return ""
            }
        case .security:
            return ""
        case .linkedAccount:
            return ""
        }
    }

    var imageName: String {
        switch self {
        case let .backup(vm):
            return ""

        default:
            return ""
        }
    }

    var sysImageColor: Color {
        switch self {
        case let .backup(vm):
            return .clear
        default:
            return .clear
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
                            HStack {
                                Image("icon-notification")
                                    .renderingMode(.template)
                                    .foregroundStyle(Color.Theme.Accent.green)

                                Text("notifications".localized).font(.inter())
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()

                                Toggle(isOn: $vm.state.isPushEnabled) {}
                                    .tint(.LL.Primary.salmonPrimary)
                                    .onTapGesture {
                                        vm.showSystemSettingAction()
                                    }
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)
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
                            ProfileView.divider
                        }
                    }
                }
            }
            .borderStyle()
        }

        // MARK: Private

        @EnvironmentObject
        private var vm: ProfileViewModel
    }
}

extension ProfileView.GeneralSectionView.Row {
    var iconName: String {
        switch self {
        case .currency:
            return "icon-currency"
        case .theme:
            return "icon-theme"
        default:
            return ""
        }
    }

    var title: String {
        switch self {
        case .currency:
            return "currency".localized
        case .theme:
            return "theme".localized
        default:
            return ""
        }
    }

    var style: ProfileView.SettingItemCell.Style {
        switch self {
        case .currency:
            return .desc
        case .theme:
            return .desc
        default:
            return .none
        }
    }

    var toggle: Bool {
        switch self {
        case .currency:
            return false
        case .theme:
            return false
        default:
            return false
        }
    }

    func desc(with vm: ProfileView.ProfileViewModel) -> String {
        switch self {
        case .currency:
            return vm.state.currency
        case .theme:
            return vm.state.colorScheme?.desc ?? "auto".localized
        default:
            return ""
        }
    }
}

// MARK: - ProfileView.FeedbackView

extension ProfileView {
    struct FeedbackView: View {
        enum Row {
            case instabug
        }

        var body: some View {
            VStack {
                Section {
                    Button {
                        Instabug.show()
                    } label: {
                        ProfileView.SettingItemCell(
                            iconName: Row.instabug.iconName,
                            title: Row.instabug.title,
                            style: Row.instabug.style
                        )
                    }
                }
            }
            .borderStyle()
        }
    }
}

extension ProfileView.FeedbackView.Row {
    var iconName: String {
        switch self {
        case .instabug:
            return "icon-instabug"
        }
    }

    var title: String {
        switch self {
        case .instabug:
            return "bug_report".localized
        }
    }

    var style: ProfileView.SettingItemCell.Style {
        switch self {
        case .instabug:
            return .none
        }
    }
}

// MARK: - ProfileView.AboutSectionView

extension ProfileView {
    struct AboutSectionView: View {
        enum Row {
            case developerMode(LocalUserDefaults)
            case plugin
            case about
        }

        @EnvironmentObject
        var lud: LocalUserDefaults

        var body: some View {
            VStack {
                Section {
                    let dm = Row.developerMode(lud)

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

                    ProfileView.divider

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

                    ProfileView.divider

                    Button {
                        Router.route(to: RouteMap.Profile.about)
                    } label: {
                        ProfileView.SettingItemCell(
                            iconName: Row.about.iconName,
                            title: Row.about.title,
                            style: Row.about.style,
                            desc: Row.about.desc,
                            toggle: Row.about.toggle
                        )
                    }
                }
            }
            .borderStyle()
        }
    }
}

extension ProfileView.AboutSectionView.Row {
    var iconName: String {
        switch self {
        case .about:
            return "icon-about"
        case .plugin:
            return "icon-plugin"
        case .developerMode:
            return "icon-developer-mode"
        }
    }

    var title: String {
        switch self {
        case .about:
            return "about".localized
        case .plugin:
            return "Chrome Extension"
        case .developerMode:
            return "developer_mode".localized
        }
    }

    var style: ProfileView.SettingItemCell.Style {
        switch self {
        case .about:
            return .arrow
        case .plugin:
            return .sysImage
        case .developerMode:
            return .desc
        }
    }

    var desc: String {
        switch self {
        case .about:
            return "about".localized
        case .plugin:
            return ""
        case let .developerMode(lud):
            return lud.flowNetwork.rawValue.capitalized
        }
    }

    var toggle: Bool {
        switch self {
        case .about:
            return false
        case .plugin:
            return false
        case .developerMode:
            return false
        }
    }

    var imageName: String {
        switch self {
        case .about:
            return ""
        case .plugin:
            return "arrow.up.right"
        case .developerMode:
            return ""
        }
    }

    var sysImageColor: Color {
        switch self {
        case .about:
            return Color.clear
        case .plugin:
            return Color.LL.note
        case .developerMode:
            return Color.clear
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
            .borderStyle()
        }
    }
}

extension ProfileView.MoreSectionView.Row {
    var iconName: String {
        switch self {
        case .switchAccount:
            return "icon-switch-account"
        }
    }

    var title: String {
        switch self {
        case .switchAccount:
            return "switch_account".localized
        }
    }

    var style: ProfileView.SettingItemCell.Style {
        switch self {
        case .switchAccount:
            return .none
        }
    }

    var desc: String {
        switch self {
        case .switchAccount:
            return ""
        }
    }

    var toggle: Bool {
        switch self {
        case .switchAccount:
            return false
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
                Image(iconName)
                    .renderingMode(.template)
                    .foregroundStyle(Color.Theme.Accent.green)
                Text(title).font(.inter()).frame(maxWidth: .infinity, alignment: .leading)

                Text(desc ?? "").font(.inter()).foregroundColor(.LL.Neutrals.note)
                    .visibility(style == .desc ? .visible : .gone)
                Image("icon-black-right-arrow")
                    .renderingMode(.template)
                    .foregroundColor(Color.LL.Button.color)
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
            .frame(height: 64)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
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

#Preview {
    ProfileView()
}
