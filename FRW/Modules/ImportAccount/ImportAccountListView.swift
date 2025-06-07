//
//  ImportAccountListView.swift
//  FRW
//
//  Created by cat on 5/21/25.
//

import SwiftUI

/// a list of all import type
struct ImportAccountListView: RouteableView {
    // MARK: Internal

    var title: String {
        ""
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: 8) {
                Text("import_account".localized)
                    .font(.inter(size: 24, weight: .w700))
                    .foregroundStyle(Color.Summer.Text.primary)
                Text("restore_from_backup".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Summer.Text.secondary)
            }

            VStack(spacing: 8) {
                ImportOptionCard(
                    icon: "restore.icon.device",
                    title: "restore_device_title".localized,
                    des: "restore_device_desc_2".localized
                ) {
                    if currentNetwork != .mainnet {
                        showSwitchUserAlert = true
                    } else {
                        Router.route(to: RouteMap.RestoreLogin.syncQC)
                    }
                }

                ImportOptionCard(
                    icon: "restore.icon.multi",
                    title: "restore_multi_title".localized,
                    des: "restore_multi_desc".localized
                ) {
                    if currentNetwork != .mainnet {
                        showSwitchUserAlert = true
                    } else {
                        Router.route(to: RouteMap.RestoreLogin.restoreMulti)
                    }
                }

                ImportOptionCard(
                    icon: "restore.icon.phrase",
                    title: "restore_phrase_title_2".localized,
                    des: "restore_phrase_desc_2".localized
                ) {
                    if currentNetwork != .mainnet {
                        showSwitchUserAlert = true
                    } else {
                        Router.route(to: RouteMap.RestoreLogin.root)
                    }
                }

                ImportOptionCard(
                    icon: "restore.profile.icon",
                    title: "restore.profile.title".localized,
                    des: "restore.profile.desc".localized
                ) {
                    if currentNetwork != .mainnet {
                        showSwitchUserAlert = true
                    } else {
                        // TODO: #six skip to profile
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

    // MARK: Private

    @State
    private var showSwitchUserAlert = false
}

struct ImportOptionCard: View {
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

#Preview {
    ImportAccountListView()
}
