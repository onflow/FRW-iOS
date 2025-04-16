//
//  DeveloperModeView.swift
//  Flow Wallet
//
//  Created by Selina on 7/6/2022.
//

import SwiftUI
import Flow

// MARK: - DeveloperModeView_Previews

struct DeveloperModeView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperModeView()
    }
}

// MARK: - DeveloperModeView

struct DeveloperModeView: RouteableView {
    // MARK: Internal

    var title: String {
        "developer_mode".localized
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Toggle("developer_mode".localized, isOn: $isDeveloperMode)
                        .toggleStyle(SwitchToggleStyle(tint: .LL.Primary.salmonPrimary))
                        .onChange(of: isDeveloperMode) { value in
                            if !value {
                                walletManager.changeNetwork(.mainnet)
                            }
                        }
                }
                .frame(height: 64)
                .padding(.horizontal, 16)
            }
            .background(.LL.bgForIcon)
            .cornerRadius(16)
            .padding(.horizontal, 18)

            if isDeveloperMode {
                VStack {
                    Text("switch_network".localized)
                        .font(.inter())
                        .foregroundColor(.LL.Neutrals.neutrals3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    VStack(spacing: 0) {
                        Section {
                            let isMainnet = lud.network == .mainnet
                            let isTestnet = lud.network == .testnet

                            Cell(
                                sysImageTuple: (
                                    isMainnet ? .checkmarkSelected :
                                        .checkmarkUnselected,
                                    isMainnet ? .LL.Primary.salmonPrimary : .LL.Neutrals.neutrals1
                                ),
                                title: "Mainnet",
                                desc: isMainnet ? "Selected::message".localized : ""
                            )
                            .onTapGestureOnBackground {
                                walletManager.changeNetwork(.mainnet)
                            }

                            Divider()
                            Cell(
                                sysImageTuple: (
                                    isTestnet ? .checkmarkSelected :
                                        .checkmarkUnselected,
                                    isTestnet ? Flow.ChainID.testnet
                                        .color : .LL.Neutrals.neutrals1
                                ),
                                title: "Testnet",
                                desc: isTestnet ? "Selected" : ""
                            )
                            .onTapGestureOnBackground {
                                walletManager.changeNetwork(.testnet)
                            }
                        }
                        .background(.LL.bgForIcon)
                    }
                    .cornerRadius(16)

                    Text("watch_address".localized)
                        .font(.inter())
                        .foregroundColor(.LL.Neutrals.neutrals3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    VStack(spacing: 0) {
                        Section {
                            Cell(
                                sysImageTuple: (
                                    vm
                                        .isCustomAddress ? .checkmarkUnselected :
                                        .checkmarkSelected,
                                    vm.isCustomAddress ? .LL.Neutrals.neutrals1 : .LL.Primary
                                        .salmonPrimary
                                ),
                                title: "my_own_address".localized,
                                desc: ""
                            )
                            .onTapGestureOnBackground {
                                vm.changeCustomAddressAction("")
                            }

                            Divider()

                            Cell(
                                sysImageTuple: (
                                    vm
                                        .isDemoAddress ? .checkmarkSelected : .checkmarkUnselected,
                                    vm.isDemoAddress ? .LL.Primary.salmonPrimary : .LL.Neutrals
                                        .neutrals1
                                ),
                                title: vm.demoAddress,
                                desc: ""
                            )
                            .onTapGestureOnBackground {
                                vm.changeCustomAddressAction(vm.demoAddress)
                            }

                            Divider()

                            Cell(
                                sysImageTuple: (
                                    vm
                                        .isSVGDemoAddress ? .checkmarkSelected :
                                        .checkmarkUnselected,
                                    vm.isSVGDemoAddress ? .LL.Primary.salmonPrimary : .LL.Neutrals
                                        .neutrals1
                                ),
                                title: vm.svgDemoAddress,
                                desc: ""
                            )
                            .onTapGestureOnBackground {
                                vm.changeCustomAddressAction(vm.svgDemoAddress)
                            }

                            Divider()

                            HStack {
                                Image(
                                    systemName: vm
                                        .isCustomAddress ? .checkmarkSelected : .checkmarkUnselected
                                )
                                .foregroundColor(
                                    vm.isCustomAddress ? .LL.Primary
                                        .salmonPrimary : .LL.Neutrals.neutrals1
                                )
                                Text("custom_address".localized)
                                    .font(.inter())

                                TextField("", text: $vm.customAddressText)
                                    .autocorrectionDisabled()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .padding(.horizontal, 10)
                                    .background(.LL.Neutrals.background)
                                    .cornerRadius(8)
                                    .onChange(of: vm.customAddressText) { _ in
                                        let trimedAddress = vm.customAddressText.trim()
                                        if trimedAddress == vm.customWatchAddress {
                                            return
                                        }

                                        DispatchQueue.main.async {
                                            vm
                                                .changeCustomAddressAction(
                                                    vm.customAddressText
                                                        .trim()
                                                )
                                        }
                                    }
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)
                        }
                        .background(.LL.bgForIcon)
                    }
                    .cornerRadius(16)

                    Section {
                        VStack {
                            HStack {
                                Toggle(
                                    openLogWindow ? "Hide Log View" : "Open Log View",
                                    isOn: $openLogWindow
                                )
                                .toggleStyle(SwitchToggleStyle(tint: .LL.Primary.salmonPrimary))
                                .onChange(of: isDeveloperMode) { value in
                                    if !value {
                                        walletManager.changeNetwork(.mainnet)
                                    }
                                }
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)
                            .onChange(of: openLogWindow, perform: { value in
                                LocalUserDefaults.shared.openLogWindow = value
                                if value {
                                    DebugViewer.shared.show(theme: .dark)
                                } else {
                                    DebugViewer.shared.close()
                                }
                            })

                            Divider()

                            HStack {
                                Text("Share Log File")
                                    .font(.inter(size: 17, weight: .medium))
                                    .foregroundStyle(Color.Theme.Text.black8)
                                Spacer()
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                if let path = log.path {
                                    let activityController = UIActivityViewController(
                                        activityItems: [path],
                                        applicationActivities: nil
                                    )
                                    activityController.isModalInPresentation = true
                                    UIApplication.shared.windows.first?.rootViewController?.present(
                                        activityController,
                                        animated: true,
                                        completion: nil
                                    )
                                } else {
                                    HUD.error(title: "Don't find log file.")
                                }
                            }
                        }
                        .background(.LL.bgForIcon)
                        .cornerRadius(16)
                    } header: {
                        headView(title: "Log")
                    }

                    Section {
                        VStack {
                            HStack {
                                Button {
                                    Router.route(to: RouteMap.Profile.keychain)
                                } label: {
                                    Text("All Keys on Local")
                                }
                                Spacer()
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)

                            Divider()
                            HStack {
                                Button {
                                    HUD.success(title: "done")
                                    LocalUserDefaults.shared.migrationFinished = false
                                } label: {
                                    Text("Reset Migration Flag")
                                }
                                Spacer()
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)

//                            Divider()
//                            HStack {
//                                Button {
//                                    HUD.success(title: "done")
//                                    let list = LocalUserDefaults.shared.userList
//                                    log.debug("[User] \(list)")
//
//                                } label: {
//                                    Text("Copy all user")
//                                }
//                                Spacer()
//                            }
//                            .frame(height: 64)
//                            .padding(.horizontal, 16)
                        }
                        .background(.LL.bgForIcon)
                        .cornerRadius(16)
                    } header: {
                        headView(title: "Tools")
                    }
                    .visibility(showTool ? .visible : .gone)

                    Text("other".localized.uppercasedFirstLetter())
                        .font(.inter())
                        .foregroundColor(.LL.Neutrals.neutrals3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    VStack(spacing: 0) {
                        Section {
                            HStack {
                                Button {
                                    Task {
                                        HUD.loading()
                                        await UserManager.shared
                                            .tryToRestoreOldAccountOnFirstLaunch()
                                        HUD.dismissLoading()
                                    }

                                } label: {
                                    Text("Reload Local Profile")
                                }
                                Spacer()
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)

                            Divider()
                            HStack {
                                Text("Script Version")
                                Spacer()

                                Text("\(CadenceManager.shared.version)")
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)

                            Divider()
                            HStack {
                                Text("Cadence Version")

                                Spacer()
                                Text(
                                    "\(String(describing: CadenceManager.shared.current.version ?? ""))"
                                )
                                .font(.inter(size: 17))
                                .foregroundStyle(Color.Theme.Text.black8)
                            }
                            .frame(height: 64)
                            .padding(.horizontal, 16)
                        }
                        .background(.LL.bgForIcon)
                    }
                    .cornerRadius(16)

                    if isDevModel {
                        Section {
                            VStack {
                                HStack {
                                    Button {
                                        Router.route(to: RouteMap.Profile.keychain)
                                    } label: {
                                        Text("KeyChain")
                                    }
                                    Spacer()
                                }
                                .frame(height: 64)
                                .padding(.horizontal, 16)

                                HStack {
                                    Text(
                                        "Reset the move asset configuration in the built-in browser"
                                    )
                                    Spacer()
                                }
                                .frame(height: 64)
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    LocalUserDefaults.shared.showMoveAssetOnBrowser = true
                                    HUD.success(title: "done.")
                                }

                                HStack {
                                    Text("Remove Wallet Home News(click)")
                                        .font(.inter(size: 14, weight: .medium))
                                        .foregroundStyle(Color.Theme.Text.black8)
                                    Spacer()
                                }
                                .frame(height: 64)
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    LocalUserDefaults.shared.removedNewsIds = []
                                    RemoteConfigManager.shared.fetchNews()
                                    HUD.success(title: "done.")
                                }

                                HStack {
                                    Text("Remove What is Backup Deail (click)")
                                    Spacer()
                                }
                                .frame(height: 64)
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    LocalUserDefaults.shared.clickedWhatIsBack = false
                                    HUD.success(title: "done.")
                                }

                                HStack {
                                    Text("Remove Custom token (click)")
                                    Spacer()
                                }
                                .frame(height: 64)
                                .padding(.horizontal, 16)
                                .onTapGesture {
                                    LocalUserDefaults.shared.customToken = []
                                    HUD.success(title: "done.")
                                }
                            }
                            .background(.LL.bgForIcon)
                            .cornerRadius(16)
                        } header: {
                            headView(title: "Debug")
                        }
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .font(.inter())
        .foregroundStyle(Color.Theme.Text.black8)
        .background(
            Color.LL.Neutrals.background.ignoresSafeArea()
        )
        .onTapGesture(count: 6, disabled: false, perform: {
            log.info("click 6 times")
            if !isDeveloperMode {
                showTool = true
            }
        })
        .applyRouteable(self)
    }

    // MARK: Private

    @StateObject
    private var lud = LocalUserDefaults.shared
    @StateObject
    private var vm: DeveloperModeViewModel = .init()
    @StateObject
    private var walletManager = WalletManager.shared

    @State
    private var showTool = false
    @AppStorage("isDeveloperMode")
    private var isDeveloperMode = false

    @State
    private var openLogWindow = LocalUserDefaults.shared.openLogWindow

    private func headView(title: String) -> some View {
        Text(title)
            .font(.inter())
            .foregroundColor(.LL.Neutrals.neutrals3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}

// MARK: DeveloperModeView.Cell

extension DeveloperModeView {
    struct Cell: View {
        let sysImageTuple: (String, Color)
        let title: String
        let desc: String
        var btnTitle: String? = nil
        var btnAction: (() -> Void)? = nil
        var titleAlpha: Double = 1.0

        var body: some View {
            HStack {
                Image(systemName: sysImageTuple.0).foregroundColor(sysImageTuple.1)
                Text(title).font(.inter()).frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(titleAlpha)
                Text(desc).font(.inter()).foregroundColor(.LL.Neutrals.note)

                Button {
                    if let btnAction = btnAction {
                        btnAction()
                    }
                } label: {
                    Text(btnTitle ?? "")
                        .font(.inter(size: 12, weight: .medium))
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Color(hex: "#F3EA5F"))
                        .cornerRadius(16)
                }
                .visibility(btnTitle?.isEmpty ?? true ? .gone : .visible)
            }
            .frame(height: 64)
            .padding(.horizontal, 16)
        }
    }
}
