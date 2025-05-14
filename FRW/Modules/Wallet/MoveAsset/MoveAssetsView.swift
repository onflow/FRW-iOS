//
//  MoveAssetsView.swift
//  FRW
//
//  Created by cat on 2024/5/17.
//

import SwiftUI
import SwiftUIX

struct MoveAssetsView: RouteableView, PresentActionDelegate {
    // MARK: Internal

    var changeHeight: (() -> Void)?

    var token: TokenModel?

    var title: String {
        ""
    }

    var showCheck: Bool {
        MoveAssetsAction.shared.showCheckOnMoveAsset
    }

    var showNote: String {
        if let note = MoveAssetsAction.shared.showNote {
            return note
        }
        return "move_assets_note".localized
    }

    var body: some View {
        ScrollView {
            VStack {
                TitleWithClosedView(title: "move_assets".localized, closeAction: {
                    Router.dismiss(animated: true, completion: {
                        MoveAssetsAction.shared.endBrowser()
                    })
                })
                .padding(.top, 24)

                Text(showNote)
                    .font(.inter(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.Theme.Text.black8)
                    .padding(.vertical, 25)

                HStack {
                    Button {
                        onClose()
                        Router.route(to: RouteMap.Wallet.moveNFTs)
                    } label: {
                        card(isNFT: true)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Spacer()
                    Button {
                        if let current = currentToken() {
                            onClose()
                            Router.route(to: RouteMap.Wallet.moveToken(current))
                        } else {
                            HUD.error(title: "not found token")
                        }
                    } label: {
                        card(isNFT: false)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                if showCheck {
                    VPrimaryButton(
                        model: ButtonStyle.primary,
                        state: .enabled,
                        action: {
                            Router.dismiss(animated: true, completion: {
                                MoveAssetsAction.shared.endBrowser()
                            })
                        },
                        title: "skip".localized
                    )
                    .padding(.top, 24)

                    HStack {
                        Spacer()
                        if notAsk {
                            Image("icon_check_rounde_0")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(Color.Theme.Text.black8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image("icon_check_rounde_1")
                                .resizable()
                                .frame(width: 16, height: 16)
                        }

                        Text("do_not_ask".localized)
                            .font(.inter(size: 16))
                            .foregroundStyle(Color.Theme.Text.black8)
                        Spacer()
                    }
                    .padding(.top)
                    .onTapGesture {
                        notAsk.toggle()
                    }
                    .padding(.bottom, 43)
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, 18)
        }
        .backgroundFill(Color.Theme.Background.grey)
        .cornerRadius([.topLeading, .topTrailing], 16)
        .applyRouteable(self)
        .tracedView(self)
        .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    func card(isNFT: Bool) -> some View {
        VStack {
            Image(cardHead(isNFT: isNFT))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: isNFT ? (showCheck ? 128 : 134) : (showCheck ? 96 : 140),
                    height: showCheck ? 56 : 96
                )

            Text(isNFT ? "move_nft".localized : "move_token".localized)
                .font(.inter(size: 18, weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black)
        }
        .frame(width: 164, height: showCheck ? 120 : 224)
        .background {
            Image(cardBG(isNFT: isNFT))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 164, height: showCheck ? 120 : 224)
                .clipped()
        }
    }

    func customViewDidDismiss() {
        MoveAssetsAction.shared.endBrowser()
    }

    // MARK: Private

    @State
    private var notAsk: Bool = LocalUserDefaults.shared.showMoveAssetOnBrowser {
        didSet {
            LocalUserDefaults.shared.showMoveAssetOnBrowser = notAsk
        }
    }

    private func cardHead(isNFT: Bool) -> String {
        if showCheck {
            return isNFT ? "evm_move_nft_header_s" : "evm_move_token_header_s"
        }
        return isNFT ? "evm_move_nft_header" : "evm_move_token_header"
    }

    private func cardBG(isNFT: Bool) -> String {
        if showCheck {
            return "move_assets_bg_s_\(isNFT ? "0" : "1")"
        }
        return "move_assets_bg_\(isNFT ? "0" : "1")"
    }

    private func currentToken() -> TokenModel? {
        if let current = token {
            return current
        }
        let flowToken = WalletManager.shared.activatedCoins.first { $0.isFlowCoin }
        if let token = flowToken {
            return token
        }
        if let current = WalletManager.shared.activatedCoins.first {
            return current
        }
        return nil
    }

    private func onClose() {
        Router.dismiss()
    }
}

#Preview {
    VStack {
        Spacer()
        MoveAssetsView(token: TokenModel.mock())
    }
}
