//
//  RestoreListView.swift
//  FRW
//
//  Created by cat on 2024/1/7.
//

import SwiftUI

// MARK: - RestoreListView

struct RestoreListView: RouteableView {
    // MARK: Internal

    var title: String {
        ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("import_btn_text".localized)
                        .foregroundColor(Color.Theme.Accent.green)
                        .bold()
                    Text("wallet".localized)
                        .foregroundColor(Color.Theme.Text.black8)
                        .bold()
                }
                .font(.LL.largeTitle)

                Text("restore_from_backup".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                RestoreListView.CardView(
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

                RestoreListView.CardView(
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

                RestoreListView.CardView(
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
            }
            .padding(.top, 46)
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
        .padding(.horizontal, 28)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @State
    private var showSwitchUserAlert = false
}

// MARK: RestoreListView.CardView

extension RestoreListView {
    struct CardView: View {
        var icon: String
        var title: String
        var des: String
        var onClick: () -> Void

        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Image(icon)
                        .resizable()
                        .frame(width: 40, height: 40)
                    Text(title)
                        .font(.inter(size: 16, weight: .semibold))
                        .foregroundStyle(Color.Theme.Accent.grey)
                    Text(des)
                        .font(.inter(size: 12))
                        .foregroundStyle(Color.Theme.Accent.grey)
                }
                Spacer()
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.leading, 32)
            .padding(.trailing, 12)
            .background(Color.Theme.Line.line)
            .cornerRadius(16)
            .onTapGesture {
                onClick()
            }
        }
    }
}

#Preview {
    RestoreListView()
//    RestoreListView.CardView(icon: "restore.icon.device", title: "From Device Backup", des: "Mobile or Extension Devices")
}
