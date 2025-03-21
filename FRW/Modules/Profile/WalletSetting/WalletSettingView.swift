//
//  WalletSettingView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 7/9/2022.
//

import SwiftUI

// MARK: - WalletSettingView

struct WalletSettingView: RouteableView {
    // MARK: Lifecycle

    init(address: String) {
        self.address = address
        user = WalletManager.shared.walletAccount.readInfo(at: address)
    }

    // MARK: Internal

    var address: String
    @State
    var showAccountEditor = false
    @State
    var user: WalletAccount.User

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
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        Button {} label: {
                            ProfileSecureView.WalletInfoCell(user: user, onEdit: {
                                showAccountEditor.toggle()
                            })
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .padding(.horizontal, 16)
                    .roundedBg()

                    VStack(spacing: 16) {
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
                                .contentShape(Rectangle())
                            }
                            .visibility(isSeedPhrase ? .visible : .gone)
                        }
                        .padding(.horizontal, 16)
                        .roundedBg()
                        .visibility(isSecureEnclave ? .gone : .visible)

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
                        .frame(height: 64)
                        .padding(.horizontal, 16)
                        .roundedBg()
                        .visibility(isSecureEnclave ? .visible : .gone)

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
                        .frame(height: 64)
                        .padding(.horizontal, 16)
                        .roundedBg()

                        VStack(spacing: 0) {
                            HStack {
                                Text("free_gas_fee".localized)
                                    .font(.inter(size: 16, weight: .medium))
                                    .foregroundColor(Color.LL.Neutrals.text)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Spacer()

                                Toggle(isOn: $localGreeGas) {}
                                    .tint(.LL.Primary.salmonPrimary)
                                    .onChange(of: localGreeGas) { _ in
                                    }
                                    .disabled(!RemoteConfigManager.shared.remoteGreeGas)
                            }

                            Text("gas_fee_desc".localized)
                                .font(.inter(size: 12, weight: .regular))
                                .foregroundColor(Color.LL.Neutrals.neutrals7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .padding(.horizontal, 16)
                        .roundedBg()

                        StorageUsageView(
                            title: "storage".localized,
                            usage: $vm.storageUsedDesc,
                            usageRatio: $vm.storageUsedRatio
                        )
                        .titleFont(.inter(size: 16, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .roundedBg()
                    }
                    .visibility(onlyShowInfo() ? .gone : .visible)
                }
                .padding(.horizontal, 18)
            }

            VStack(alignment: .trailing) {
                Button {
                    vm.resetWalletAction()
                } label: {
                    Text("delete_wallet".localized)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(.LL.Warning.warning2)
                        .cornerRadius(16)
                        .foregroundColor(Color.white)
                        .font(.inter(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 18)
            }
            .visibility(onlyShowInfo() ? .gone : .visible)
        }
        .backgroundFill(.LL.background)
        .applyRouteable(self)
        .popup(isPresented: $showAccountEditor) {
            WalletAccountEditor(address: address) {
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
        user = WalletManager.shared.walletAccount.readInfo(at: address)
        WalletManager.shared.changeNetwork(LocalUserDefaults.shared.flowNetwork)
    }

    func onlyShowInfo() -> Bool {
        let list = EVMAccountManager.shared.accounts
            .filter { $0.showAddress.lowercased() == address.lowercased() }
        return !list.isEmpty
    }

    // MARK: Private

    @StateObject
    private var vm = WalletSettingViewModel()
    @AppStorage(LocalUserDefaults.Keys.freeGas.rawValue)
    private var localGreeGas = true
}

// MARK: - WalletSettingView_Previews

struct WalletSettingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WalletSettingView(address: "0x")
        }
    }
}
