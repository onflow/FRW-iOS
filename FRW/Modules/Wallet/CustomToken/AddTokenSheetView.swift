//
//  AddTokenSheetView.swift
//  FRW
//
//  Created by cat on 11/5/24.
//

import Kingfisher
import SwiftUI

struct AddTokenSheetView: RouteableView & PresentActionDelegate {
    var changeHeight: (() -> Void)?

    let customToken: CustomToken
    let callback: (Bool) -> Void

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var body: some View {
        GeometryReader { _ in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Add Suggested Token".localized)
                                .font(.inter(size: 18, weight: .w700))
                                .foregroundStyle(Color.LL.Neutrals.text)
                                .padding(.top, 6)
                            Spacer()

                            Button {
                                onClose()
                            } label: {
                                Image("icon_close_circle_gray")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.top, 8)
                        HStack {
                            Text("like_import_token".localized)
                                .font(.inter(size: 14))
                                .foregroundStyle(Color.Theme.Text.black3)
                                .padding(.top, 12)
                            Spacer()
                        }

                        Divider()
                            .foregroundStyle(Color.Theme.Line.line)
                            .padding(.top, 16)
                            .padding(.bottom, 16)

                        tokenView()
                            .padding(.bottom, 16)
                        Spacer()
                    }
                    .padding(18)
                }
            }
            .backgroundFill(Color.Theme.BG.bg1)
            .cornerRadius([.topLeading, .topTrailing], 16)
            .edgesIgnoringSafeArea(.bottom)
            .overlay(alignment: .bottom) {
                VPrimaryButton(
                    model: ButtonStyle.primary,
                    state: .enabled,
                    action: {
                        onAdd()
                    },
                    title: "add_token".localized
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            }
        }
        .applyRouteable(self)
        .tracedView(self)
    }

    func onClose() {
        callback(false)
        Router.dismiss()
    }

    func customViewDidDismiss() {
        callback(false)
    }

    func onAdd() {
        Task {
            let manager = WalletManager.shared.customTokenManager
            let isExist = manager.isExist(token: customToken)
            if !isExist {
                await manager.add(token: customToken)
            }
            DispatchQueue.main.async {
                HUD.success(title: "successful".localized)
                self.callback(true)
                Router.dismiss()
            }
        }
    }

    func tokenView() -> some View {
        HStack {
            KFImage.url(URL(string: customToken.icon ?? ""))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            Text(customToken.name)
                .font(.inter(size: 16, weight: .bold))
                .foregroundStyle(Color.Theme.Text.black)

            Spacer()

            Text(customToken.balanceValue + " " + "flow".localized.uppercased())
                .font(.inter(size: 16))
                .foregroundStyle(Color.Theme.Text.black)
        }
        .padding(16)
        .background(Color.Theme.Background.pureWhite)
        .cornerRadius(16)
    }
}

#Preview {
    AddTokenSheetView(
        customToken: CustomToken(
            address: "",
            decimals: 12,
            name: "",
            symbol: "",
            flowIdentifier: nil,
            belong: .evm,
            balance: nil,
            icon: nil
        )
    ) { _ in
    }
}
