//
//  FlowAccountDetailView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 7/9/2022.
//

import FlowWalletKit
import SwiftUI

struct FlowAccountDetailView: RouteableView {
    // MARK: Lifecycle

    init(account: FlowWalletKit.Account) {
        self.account = account
        showInAccount = !UserManager.shared.filterAccounts.inFilter(with: account)
        isSelected = WalletManager.shared.selectedAccountAddress == account.hexAddr
    }

    // MARK: Internal

    @State var account: FlowWalletKit.Account
    @State
    var showAccountEditor = false

    var isSelected: Bool

    var title: String {
        "account".localized.capitalized
    }

    var isSecureEnclave: Bool {
        WalletManager.shared.keyProvider?.keyType == .secureEnclave
    }

    var isSeedPhrase: Bool {
        WalletManager.shared.keyProvider?.keyType == .seedPhrase
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    AccountInfoCard(account: account) {
                        showAccountEditor.toggle()
                    }

                    VStack(spacing: 16) {
                        if isSecureEnclave {
                            VStack(spacing: 0) {
                                Button {
                                    Router.route(to: RouteMap.Profile.secureEnclavePrivateKey)
                                } label: {
                                    ProfileSecureView.ItemCell(
                                        title: "private_key".localized,
                                        style: .arrow,
                                        isOn: false,
                                        toggleAction: nil
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(18)
                            .roundedBg()
                        } else {
                            VStack(spacing: 0) {
                                Button {
                                    Task {
                                        let result = await SecurityManager.shared.SecurityVerify()
                                        if result {
                                            Router.route(to: RouteMap.Profile.privateKey(true))
                                        }
                                    }
                                } label: {
                                    ProfileSecureView.ItemCell(
                                        title: "private_key".localized,
                                        style: .arrow,
                                        isOn: false,
                                        toggleAction: nil
                                    )
                                }

                                Divider().foregroundColor(.LL.Neutrals.background)
                                    .visibility(isSeedPhrase ? .visible : .gone)

                                Button {
                                    Task {
                                        let result = await SecurityManager.shared.SecurityVerify()
                                        if result {
                                            Router.route(to: RouteMap.Profile.manualBackup(true))
                                        }
                                    }
                                } label: {
                                    ProfileSecureView.ItemCell(
                                        title: "recovery_phrase".localized,
                                        style: .arrow,
                                        isOn: false,
                                        toggleAction: nil
                                    )
                                }
                                .visibility(isSeedPhrase ? .visible : .gone)
                            }
                            .roundedBg()
                        }

                        VStack(spacing: 0) {
                            Button {
                                Router.route(to: RouteMap.Profile.accountKeys)
                            } label: {
                                ProfileSecureView.ItemCell(
                                    title: "wallet_account_key".localized,
                                    style: .arrow,
                                    isOn: false,
                                    toggleAction: nil
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .roundedBg()

                        if !isSelected {
                            HStack {
                                Text("show_in_account".localized)
                                    .font(.inter(size: 16))
                                    .foregroundColor(Color.LL.Neutrals.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()

                                Toggle(isOn: $showInAccount) {}
                                    .tint(.LL.Primary.salmonPrimary)
                                    .onChange(of: showInAccount) { value in
                                        if value {
                                            UserManager.shared.filterAccounts.removeFilter(with: account)
                                        } else {
                                            UserManager.shared.filterAccounts.addFilter(with: account)
                                        }
                                    }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(18)
                            .roundedBg()
                        }

                        VStack(spacing: 8) {
                            HStack {
                                Text("free_gas_fee".localized)
                                    .font(.inter(size: 16))
                                    .foregroundColor(Color.LL.Neutrals.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()

                                Toggle(isOn: $localGreeGas) {}
                                    .tint(.LL.Primary.salmonPrimary)
                                    .onChange(of: localGreeGas) { _ in
                                    }
                                    .disabled(!RemoteConfigManager.shared.remoteGreeGas)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(18)
                            .roundedBg()

                            Text("gas_fee_desc".localized)
                                .font(.inter(size: 12))
                                .foregroundColor(Color.Theme.Text.text4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                        }

                        StorageUsageView(
                            title: "storage".localized,
                            usage: $vm.storageUsedDesc,
                            usageRatio: $vm.storageUsedRatio
                        )
                        .titleFont(.inter(size: 16, weight: .medium))
                        .padding(18)
                        .roundedBg()
                    }
                    .visibility(onlyShowInfo() ? .gone : .visible)
                }
                .padding(.horizontal, 18)
            }
            .clipped()
            .safeAreaInset(edge: .bottom) {
                Button {
                    vm.resetWalletAction()
                } label: {
                    Text("remove_account".localized)
                        .font(.inter(size: 16, weight: .bold))
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.Theme.Accent.red)
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 18)
                .visibility(onlyShowInfo() ? .gone : .visible)
            }
        }
        .backgroundFill(Color.Theme.Background.white)
        .applyRouteable(self)
        .tracedView(self)
        .popup(isPresented: $showAccountEditor) {
            WalletAccountEditor(address: account.hexAddr) {
                reload()
                showAccountEditor = false
            }
        } customize: {
            $0
                .closeOnTap(false)
                .closeOnTapOutside(true)
                .backgroundColor(.black.opacity(0.4))
        }
    }

    func reload() {
        let user = WalletManager.shared.walletAccount.readInfo(at: account.hexAddr)
        account = account
        WalletManager.shared.changeNetwork(currentNetwork)
    }

    func onlyShowInfo() -> Bool {
        let list = EVMAccountManager.shared.accounts
            .filter { $0.showAddress.lowercased() == account.hexAddr.lowercased() }
        return !list.isEmpty
    }

    // MARK: Private

    @StateObject
    private var vm = WalletSettingViewModel()
    @AppStorage(LocalUserDefaults.Keys.freeGas.rawValue)
    private var localGreeGas = true

    @State private var showInAccount: Bool
}
