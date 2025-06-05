//
//  SideMenuView.swift
//  Flow Wallet
//
//  Created by Selina on 4/1/2023.
//

import Combine
import Factory
import Kingfisher
import SwiftUI

// MARK: - SideMenuView

struct SideMenuView: View {
    // MARK: Internal

    private let SideOffset: CGFloat = 65

    @State
    var reloadCount = 0

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                VStack(spacing: 24) {
                    VStack {
                        if vm.hasCoa {
                            ProfileView
                        } else {
                            EnableEVMView
                        }
                    }
                    .padding(.top, proxy.safeAreaInsets.top + 16)

                    ScrollView {
                        VStack(spacing: 24) {
                            ActivityAccountView
                            OtherAccountsView
                        }
                    }

//                    bottomMenu
//                        .padding(.bottom, 16 + proxy.safeAreaInsets.bottom)
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

// MARK: - New UI

extension SideMenuView {
    @ViewBuilder
    var ProfileView: some View {
        VStack {
            HStack(alignment: .center, spacing: 16) {
                ProfileInfoView(userInfo: um.userInfo ?? .empty)

                Spacer()

                Button {
                    vm.switchAccountMoreAction()
                } label: {
                    Image("icon_account_setting")
                        .resizable()
                        .frame(width: 44, height: 44)
                }
            }
            Divider()
                .foregroundStyle(Color.Summer.line)
        }
    }

    @ViewBuilder
    var EnableEVMView: some View {
        Button {
            vm.onClickEnableEVM()
        } label: {
            HStack(alignment: .center, spacing: 4) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("Add an")
                            .font(.inter(size: 14))
                            .foregroundStyle(Color.Summer.Text.primary)
                        TagView(size: 12, type: .evm)
                        Text("account on Flow")
                            .font(.inter(size: 14))
                            .foregroundStyle(Color.Summer.Text.primary)
                    }
                    .fontWeight(.bold)
                    Text("Manage your multi-VM assets seamlessly.")
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Summer.Text.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.Summer.icons)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.Summer.cards)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    var ActivityAccountView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let account = vm.activeAccount {
                Text("active_account".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Text.black8)
                AccountInfoView(account: account, isActivity: true, isSelected: true)
                    .animation(.bouncy, value: vm.activeAccount)
            }
        }
    }

    @ViewBuilder
    var OtherAccountsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if vm.hasOtherAccounts {
                Text("other_accounts".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Text.black8)
                ForEach(0 ..< um.accounts.count, id: \.self) { index in
                    ForEach(um.accounts[index], id: \.account.infoAddress) { account in
                        let isSelected = vm.activeAccount?.account.infoAddress == account.account.infoAddress
                        AccountInfoView(account: account, isActivity: false, isSelected: isSelected) { model, _ in
                            WalletManager.shared.changeSelectedAccount(address: model.account.infoAddress, type: model.account.accountType)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    var BottomView: some View {
        VStack {
            Button {} label: {
                HStack {
                    CircleButton(image: .add) {}
                        .allowsHitTesting(false)
                    Text("add_account".localized)
                        .font(.inter(size: 16, weight: .bold))
                        .foregroundStyle(Color.Theme.Text.black8)

                    Spacer()
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}
