//
//  AccountSettingView.swift
//  Flow Wallet
//
//  Created by Selina on 21/6/2023.
//

import Combine
import Kingfisher
import SwiftUI

// MARK: - AccountSettingViewModel

class AccountSettingViewModel: ObservableObject {
    init() {
        ChildAccountManager.shared.refresh()
    }
}

// MARK: - AccountSettingView

// FIXME: remove this view?
struct AccountSettingView: RouteableView {
    // MARK: Internal

    var title: String {
        "wallet".localized.capitalized
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    walletInfoCell()

                    if !cm.childAccounts.isEmpty {
                        linkAccountContentView
                            .padding(.top, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    var linkAccountContentView: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            Text("linked_account".localized)
                .foregroundColor(Color.LL.Neutrals.text4)
                .font(.inter(size: 16, weight: .bold))

            ForEach(cm.sortedChildAccounts, id: \.addr) { childAccount in
                Button {
                    Router.route(to: RouteMap.Profile.accountDetail(childAccount))
                } label: {
                    childAccountCell(childAccount)
                }
            }
        }
    }

    func walletInfoCell() -> some View {
        Button {
            guard let account = WalletManager.shared.mainAccount else {
                return
            }
            Router.route(to: RouteMap.Profile.walletSetting(
                true,
                account
            ))
        } label: {
            HStack(spacing: 18) {
                Image("flow")
                    .resizable()
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 5) {
                    Text("My Wallet")
                        .foregroundColor(Color.LL.Neutrals.text)
                        .font(.inter(size: 14, weight: .semibold))

                    Text(WalletManager.shared.getPrimaryWalletAddress() ?? "0x")
                        .foregroundColor(Color.LL.Neutrals.text3)
                        .font(.inter(size: 12))
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 78)
            .background(Color.LL.background)
            .contentShape(Rectangle())
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.02), x: 0, y: 12, blur: 16)
        }
    }

    func childAccountCell(_ childAccount: ChildAccount) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 18) {
                KFImage.url(URL(string: childAccount.icon))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .cornerRadius(18)

                VStack(alignment: .leading, spacing: 5) {
                    Text(childAccount.aName)
                        .foregroundColor(Color.LL.Neutrals.text)
                        .font(.inter(size: 14, weight: .semibold))

                    Text(childAccount.addr ?? "")
                        .foregroundColor(Color.LL.Neutrals.text3)
                        .font(.inter(size: 12))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                withAnimation(.none) {
                    cm.togglePinStatus(childAccount)
                }
            } label: {
                Image("icon-pin")
                    .renderingMode(.template)
                    .foregroundColor(
                        childAccount.isPinned ? Color.LL.Primary
                            .salmonPrimary : Color(hex: "#00B881")
                    )
                    .frame(width: 32, height: 32)
                    .background {
                        if childAccount.isPinned {
                            LinearGradient(
                                colors: [Color.clear, Color(hex: "#00B881").opacity(0.15)],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                            .cornerRadius([.topTrailing, .bottomLeading], 16)
                        } else {
                            Color.clear
                        }
                    }
                    .contentShape(Rectangle())
            }
        }
        .padding(.leading, 20)
        .frame(height: 66)
        .background(Color.LL.background)
        .contentShape(Rectangle())
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), x: 0, y: 12, blur: 16)
    }

    // MARK: Private

    @StateObject
    private var cm = ChildAccountManager.shared
    @StateObject
    private var vm = AccountSettingViewModel()
}
