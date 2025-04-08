//
//  SideMenuView.swift
//  Flow Wallet
//
//  Created by Selina on 4/1/2023.
//

import Combine
import Kingfisher
import SwiftUI
import Factory

// MARK: - SideMenuView

struct SideMenuView: View {
    // MARK: Internal

    private let SideOffset: CGFloat = 65
    
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                VStack {
                    cardView
                        .padding(.top, proxy.safeAreaInsets.top)

                    ScrollView {
                        VStack {
                            enableEVMView
                                .padding(.top, 24)
                                .visibility(evmManager.showEVM ? .visible : .gone)

                            addressListView
                        }
                    }

                    bottomMenu
                        .padding(.bottom, 16 + proxy.safeAreaInsets.bottom)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.Theme.Background.white)
                .ignoresSafeArea()

                // placeholder, do not use this
                VStack {}
                    .frame(width: SideOffset)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    var cardView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                KFImage.url(URL(string: um.userInfo?.avatar.convertedAvatarString() ?? ""))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .onSuccess { _ in
                        vm.pickColor(from: um.userInfo?.avatar.convertedAvatarString() ?? "")
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .cornerRadius(24)

                Spacer()

                Button {
                    vm.switchAccountMoreAction()
                } label: {
                    Image("icon-more")
                        .renderingMode(.template)
                        .foregroundColor(Color.LL.Neutrals.text)
                }
            }

            Text(um.userInfo?.nickname ?? "lilico".localized)
                .foregroundColor(.LL.Neutrals.text)
                .font(.inter(size: 20, weight: .bold))
                .frame(height: 32)
                .padding(.top, 4)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: vm.userInfoBackgroudColor.opacity(00), location: 0.00),
                    Gradient.Stop(color: vm.userInfoBackgroudColor.opacity(0.64), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
            .cornerRadius(12)
        }
    }

    var enableEVMView: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Image("icon_planet")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .zIndex(1)
                    .offset(x: 8, y: -8)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("enable_path".localized)
                            .font(.inter(size: 16, weight: .semibold))
                            .foregroundStyle(Color.Theme.Text.black8)
                        Text("evm_on_flow".localized)
                            .font(.inter(size: 16, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.Theme.Accent.blue, Color.Theme.Accent.green],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text(" !")
                            .font(.inter(size: 16, weight: .semibold))
                            .foregroundStyle(Color.Theme.Text.black8)
                        Spacer()
                        Image("right-arrow-stroke")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    .frame(height: 24)
                    Text("enable_evm_tip".localized)
                        .font(.inter(size: 14))
                        .foregroundStyle(Color.Theme.Text.black3)
                        .frame(height: 24)
                }
                .frame(height: 72)
                .padding(.horizontal, 18)
                .background(.Theme.Background.white)
                .cornerRadius(16)
                .shadow(color: Color.Theme.Background.white.opacity(0.08), radius: 16, y: 4)
                .offset(y: 8)
            }
        }
        .onTapGesture {
            vm.onClickEnableEVM()
        }
    }

    var addressListView: some View {
        VStack(spacing: 0) {
            Section {
                VStack(spacing: 0) {
                    ForEach(wallet.currentNetworkAccounts, id: \.address) { account in
                        AccountSideCell(
                            address: account.hexAddr,
                            currentAddress: vm.currentAddress,
                            balance: Binding<String>(
                                get: { vm.walletBalance[account.hexAddr]?.doubleValue.formatDisplayFlowBalance ?? "" },
                                set: { _ in }
                            )
                        ) { address in
                            WalletManager.shared.changeSelectedAccount(address: address, type: .main)
                        }
                    }
                }
                .cornerRadius(12)
                .animation(.easeInOut, value: WalletManager.shared.getPrimaryWalletAddress())
            } header: {
                HStack {
                    Text("main_account".localized)
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Text.black3)
                        .padding(.vertical, 8)
                    Spacer()
                }
            }
//            .mockPlaceholder(wm.walletEntity?.isLoading ?? true)

            Color.clear
                .frame(height: 16)

            Section {
                VStack(spacing: 0) {
                    if let coa = wallet.coa {
                        AccountSideCell(
                            address: coa.address,
                            currentAddress: vm.currentAddress
//                            ,
//                            balance: vm.walletBalance[coa.address]?.doubleValue?.formatDisplayFlowBalance
                        ) { address in
                            WalletManager.shared.changeSelectedAccount(address: address, type: .coa)
                        }
                    }

                    if let childs = wallet.childs, !childs.isEmpty {
                        ForEach(childs, id: \.address) { child in
                                AccountSideCell(
                                    address: child.address.hex,
                                    currentAddress: vm.currentAddress,
                                    name: child.name,
                                    logo: child.icon?.absoluteString
//                                    ,
//                                    balance: vm.walletBalance[child.address.hex]?.doubleValue?.formatDisplayFlowBalance
                                ) { address in
                                    WalletManager.shared.changeSelectedAccount(address: address, type: .child)
                                }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Linked_Account::message".localized)
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Text.black3)
                        .padding(.vertical, 8)
                    Spacer()
                }
                .visibility(
                    wallet.currentMainAccount?.hasLinkedAccounts ?? false
                )
            }
        }
        .mockPlaceholder(wallet.currentMainAccount?.isLoading ?? true)
    }

    var bottomMenu: some View {
        VStack {
            Divider()
                .background(.Theme.Line.line)
                .frame(height: 1)
                .padding(.bottom, 24)
            if isDeveloperMode {
                HStack {
                    Image("icon_side_link")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.Theme.Text.black8)
                    Text("Network::message".localized)
                        .lineLimit(1)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.black8)

                    Spacer()

                    Menu {
                        VStack {
                            Button {
                                NotificationCenter.default.post(name: .toggleSideMenu)
                                WalletManager.shared.changeNetwork(.mainnet)

                            } label: {
                                NetworkMenuItem(
                                    network: .mainnet,
                                    currentNetwork: LocalUserDefaults.shared.flowNetwork
                                )
                            }

                            Button {
                                NotificationCenter.default.post(name: .toggleSideMenu)
                                WalletManager.shared.changeNetwork(.testnet)

                            } label: {
                                NetworkMenuItem(
                                    network: .testnet,
                                    currentNetwork: LocalUserDefaults.shared.flowNetwork
                                )
                            }
                        }

                    } label: {
                        Text(LocalUserDefaults.shared.flowNetwork.rawValue.uppercasedFirstLetter())
                            .font(.inter(size: 12))
                            .foregroundStyle(LocalUserDefaults.shared.flowNetwork.color)
                            .frame(height: 24)
                            .padding(.horizontal, 8)
                            .background(LocalUserDefaults.shared.flowNetwork.color.opacity(0.08))
                            .cornerRadius(8)
                    }
                }
                .frame(height: 40)
            }

            Button {
                Router.route(to: RouteMap.RestoreLogin.restoreList)
            } label: {
                HStack {
                    Image("icon_side_import")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Color.Theme.Text.black8)
                    Text("import_wallet".localized)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.black8)

                    Spacer()
                }
                .frame(height: 40)
            }
        }
    }

    // MARK: Private

    @StateObject
    private var vm = SideMenuViewModel()
    @StateObject
    private var um = UserManager.shared
    
    @Injected(\.wallet)
    private var wallet: WalletManager
    
    @StateObject
    private var cm = ChildAccountManager.shared
    @StateObject
    private var evmManager = EVMAccountManager.shared
    @AppStorage("isDeveloperMode")
    private var isDeveloperMode = false
    @State
    private var showSwitchUserAlert = false

    private let cPadding = 12.0
}
