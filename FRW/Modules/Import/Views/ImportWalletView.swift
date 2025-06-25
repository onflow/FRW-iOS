//
//  ImportWalletView.swift
//  FRW
//
//  Created by cat on 6/19/25.
//

import SwiftUI

struct ImportWalletView: RouteableView {
    @StateObject var viewModel: ImportWalletViewModel
    @State private var showSwitchUserAlert = false

    init(viewModel: ImportWalletViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var title: String {
        ""
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 8) {
                Text(topTitle)
                    .font(.inter(size: 24, weight: .w700))
                    .foregroundStyle(Color.Summer.Text.primary)
                Text(topSubtitle)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Summer.Text.secondary)
            }

            VStack(spacing: 8) {
                ImportWalletCard(
                    icon: "restore.icon.device",
                    title: "import_account_device_title".localized,
                    des: "restore_device_desc_2".localized
                ) {
                    if isMainnet() {
                        Router.route(to: RouteMap.RestoreLogin.syncQC)
                    }
                }

                ImportWalletCard(
                    icon: "restore.icon.multi",
                    title: "restore_multi_title".localized,
                    des: "restore_multi_desc".localized
                ) {
                    if isMainnet() {
                        Router.route(to: RouteMap.ImportWallet.multibackList(viewModel))
                    }
                }

                ImportWalletCard(
                    icon: "restore.icon.phrase",
                    title: "restore_phrase_title_2".localized,
                    des: "restore_phrase_desc_2".localized
                ) {
                    if isMainnet() {
                        Router.route(to: RouteMap.RestoreLogin.root)
                    }
                }
                if isAccount {
                    ImportWalletCard(
                        icon: "restore.profile.icon",
                        title: "restore.profile.title".localized,
                        des: "restore.profile.desc".localized
                    ) {
                        if isMainnet() {
                            // TODO: #six skip to profile
                        }
                    }
                }
            }
            .padding(.top, 18)
            .alert("wrong_network_title".localized, isPresented: $showSwitchUserAlert) {
                Button("switch_to_mainnet".localized) {
                    WalletManager.shared.changeNetwork(.mainnet)
                }
                Button("action_cancel".localized, role: .cancel) {}
            } message: {
                Text("wrong_network_des".localized)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
        .backgroundFill(Color.Summer.Background.nav)
        .applyRouteable(self)
        .tracedView(self)
    }

    func isMainnet() -> Bool {
        if currentNetwork != .mainnet {
            showSwitchUserAlert = true
            return false
        }
        return true
    }
}

// MARK: - UI

extension ImportWalletView {
    var isAccount: Bool {
        viewModel.importType == .account
    }

    var topTitle: String {
        isAccount ? "import_account".localized : "import_profile".localized
    }

    var topSubtitle: String {
        isAccount ? "import_account_subtitle".localized : "import_profile_subtitle".localized
    }
}

#Preview {
    ImportWalletView(viewModel: .init(importType: .account))
}

struct ImportWalletCard: View {
    var icon: String
    var title: String
    var des: String
    var onClick: () -> Void

    var body: some View {
        Button {
            onClick()
        } label: {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(icon)
                        .resizable()
                        .frame(width: 28, height: 28)
                    Text(title)
                        .font(.inter(size: 16, weight: .w600))
                        .foregroundStyle(Color.Summer.Text.primary)
                    Text(des)
                        .font(.inter(size: 14))
                        .foregroundStyle(Color.Summer.Text.primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.Summer.icons)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(18)
            .background(Color.Summer.cards)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
