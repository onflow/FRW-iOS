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
    
    @State
    var reloadCount = 0
    
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
                                .visibility(vm.hasCoa ? .gone : .visible)
                            accountListView
                        }
                    }

                    bottomMenu
                        .padding(.bottom, 16 + proxy.safeAreaInsets.bottom)
                }
                .padding(.horizontal, 18)
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
            HStack(spacing: 16) {
                KFImage.url(URL(string: um.userInfo?.avatar.convertedAvatarString() ?? ""))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
              
                Text(um.userInfo?.nickname ?? "lilico".localized)
                    .foregroundColor(.LL.Neutrals.text)
                    .font(.inter(size: 14, weight: .bold))
              
                Spacer()

                Button {
                    vm.switchAccountMoreAction()
                } label: {
                    Image("profile_switch_icon")
                        .renderingMode(.template)
                        .foregroundColor(Color.Brain.Core.icons)
                }
            }
            .padding(.vertical, 14)

            Divider()
            .background(Color.Brain.Light.lines25)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    var accountListView: some View {
      VStack(spacing: 0) {
          if let account = vm.currentAccount {
            Section {
              SideMenuView.AccountRow(account: account, isActivity: true, onClick: { clickedAccount in
              })
              .padding(.horizontal, 16)
                .background(Color.Brain.Core.cards)
                .cornerRadius(16)
            } header: {
              HStack {
                  Text("active_account".localized)
                      .font(.inter(size: 14))
                      .foregroundStyle(Color.Theme.Text.black8)
                      .padding(.vertical, 16)
                  Spacer()
              }
            }
        }
        
        if !vm.allAccounts.isEmpty {
          Section {
            ForEach(0..<vm.allAccounts.count, id: \.self) { index in
              let section = vm.allAccounts[index]
              ForEach(0..<section.count, id: \.self) { subIndex in
                let account = section[subIndex]
                let isActive = vm.currentAccount?.address == account.address
                SideMenuView.AccountRow(account: account, isActivity: isActive) { clickedAccount in
                  vm.updateCurrentAccount(clickedAccount)
                }
              }
            }
          } header: {
            HStack {
                Text("other_accounts".localized)
                  .font(.inter(size: 14))
                  .foregroundStyle(Color.Theme.Text.black8)
                  .padding(.vertical, 16)
                Spacer()
            }
          }
        }
      }
    }

    var bottomMenu: some View {
        VStack {
            Divider()
                .background(.Theme.Line.line)
                .frame(height: 1)
                .padding(.bottom, 12)
            
            Button {
                reloadCount += 1
                UIFeedbackGenerator.impactOccurred(.light)
                wallet.reloadWalletInfo()
                wallet.loadLinkedAccounts()
            } label: {
                HStack {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .foregroundStyle(Color.Theme.Text.black8)
                        .font(.system(size: 14).bold())
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(360 * reloadCount ))
                        .animation(.linear(duration: 0.5), value: reloadCount)
                    
                    Text("Refresh Accounts".localized)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.black8)
                    Spacer()
                }
                .contentShape(Rectangle())
                .frame(height: 40)
            }
            .buttonStyle(ScaleButtonStyle())
            
            if isDeveloperMode {
                HStack {
                    Image("icon_side_link")
                        .resizable()
                        .renderingMode(.template)
//                        .aspectRatio(contentMode: .fit)
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
                                    currentNetwork: currentNetwork
                                )
                            }

                            Button {
                                NotificationCenter.default.post(name: .toggleSideMenu)
                                WalletManager.shared.changeNetwork(.testnet)

                            } label: {
                                NetworkMenuItem(
                                    network: .testnet,
                                    currentNetwork: currentNetwork
                                )
                            }
                        }

                    } label: {
                        Text(currentNetwork.rawValue.uppercasedFirstLetter())
                            .font(.inter(size: 12))
                            .foregroundStyle(currentNetwork.color)
                            .frame(height: 24)
                            .padding(.horizontal, 8)
                            .background(currentNetwork.color.opacity(0.08))
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
                .contentShape(Rectangle())
                .frame(height: 40)
            }
            .buttonStyle(ScaleButtonStyle())
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
    
    @AppStorage("isDeveloperMode")
    private var isDeveloperMode = false
    @State
    private var showSwitchUserAlert = false

    private let cPadding = 12.0
}
