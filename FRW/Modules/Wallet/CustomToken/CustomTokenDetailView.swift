//
//  CustomTokenDetailView.swift
//  FRW
//
//  Created by cat on 11/2/24.
//

import SwiftUI

// MARK: - CustomTokenDetailView

struct CustomTokenDetailView: RouteableView {
    let token: CustomToken

    var title: String {
        "Add Custom Token".localized
    }

    var body: some View {
        VStack(spacing: 12) {
            CustomTokenDetailView
                .Item(
                    title: "Token Contract Address".localized,
                    content: token.address
                )
            Divider()
                .foregroundStyle(Color.Theme.Line.stroke)
            CustomTokenDetailView
                .Item(title: "Token Name".localized, content: token.name)

            CustomTokenDetailView
                .Item(title: "Token Symbol".localized, content: token.symbol)

            CustomTokenDetailView
                .Item(title: "Token Decimal".localized, content: String(token.decimals))

            CustomTokenDetailView
                .Item(
                    title: "Flow Identifier".localized,
                    content: token.flowIdentifier ?? ""
                )
                .visibility(token.flowIdentifier == nil ? .gone : .visible)

            Spacer()

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: .enabled,
                action: {
                    onClickImport()
                },
                title: "import_btn_text".localized
            )
        }
        .padding(16)
        .background(.Theme.Background.bg2)
        .applyRouteable(self)
        .tracedView(self)
    }

    func onClickImport() {
        Task {
            let manager = WalletManager.shared.customTokenManager
            let inWhite = manager.isInWhite(token: token)
            if inWhite {
                HUD.success(title: "the token is added")
            } else {
                HUD.loading()
                await manager.add(token: token)
                HUD.dismissLoading()
                Router.popToRoot()
            }
        }
    }
}

// MARK: CustomTokenDetailView.Item

extension CustomTokenDetailView {
    struct Item: View {
        var title: String
        var content: String
        var dark: Bool = false

        var body: some View {
            VStack(alignment: .leading) {
                TitleView(title: title, isStar: false)
                HStack {
                    Text(content)
                        .font(.inter(size: 14))
                        .foregroundStyle(
                            dark ? Color.Theme.Text.black8 : Color.Theme.Text.black3
                        )
                    Spacer()
                }
                .padding(20)
                .frame(height: 64)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(.Theme.BG.bg1)
                }
            }
        }
    }
}

#Preview {
    CustomTokenDetailView(
        token: CustomToken(
            address: "0xaddd",
            decimals: 3,
            name: "Flow Test",
            symbol: "FLOW",
            belong: .evm
        )
    )
}
