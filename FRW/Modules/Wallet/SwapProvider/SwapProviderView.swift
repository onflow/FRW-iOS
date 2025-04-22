//
//  SwapProviderView.swift
//  FRW
//
//  Created by cat on 2/5/25.
//

import Kingfisher
import SwiftUI

// MARK: - SwapProviderView

struct SwapProviderView: RouteableView & PresentActionDelegate {
    // MARK: Lifecycle

    init(token: TokenModel?) {
        var result: [SwapProviderModel] = []
        if EVMAccountManager.shared.selectedAccount != nil {
            result.append(SwapProviderModel.Punch)
            result.append(SwapProviderModel.Trado)
        } else {
            if let token, token.isFlowCoin {
                result.append(SwapProviderModel.Punch)
                result.append(SwapProviderModel.Trado)
            }
            result.append(SwapProviderModel.Increment)
        }
        self.list = result
    }

    // MARK: Internal

    var changeHeight: (() -> Void)?

    @State
    var list: [SwapProviderModel]

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Color.clear
                    .frame(width: 24, height: 24)
                Spacer()
                Text("Choose Swap Provider".localized)
                    .font(.inter(size: 18, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                Button {
                    Router.dismiss()
                } label: {
                    Image("icon_close_circle_gray")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.bottom, 20)

            VStack(spacing: 8) {
                ForEach(0..<list.count, id: \.self) { index in
                    let model = list[index]
                    Cell(model: model)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let url = URL(string: model.url) {
                                Router.dismiss(animated: false)
                                Router.route(to: RouteMap.Explore.browser(url))
                            }
                        }
                }
            }
            Spacer()
        }
        .padding(18)
        .background(.Theme.BG.bg1)
        .cornerRadius([.topLeading, .topTrailing], 16)
        .applyRouteable(self)
    }

    @ViewBuilder
    func Cell(model: SwapProviderModel) -> some View {
        HStack {
            KFImage.url(model.iconUrl)
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .cornerRadius(18)

            VStack(alignment: .leading) {
                Text(model.title)
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black)
                Text(model.host)
                    .font(.inter(size: 12))
                    .foregroundStyle(Color.Theme.Text.black6)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(.Theme.BG.bg2)
        .cornerRadius(16)
    }
}

// MARK: - SwapProviderModel

struct SwapProviderModel {
    static let Punch = SwapProviderModel(
        title: "PunchSwap",
        icon: "https://swap.kittypunch.xyz/Punch1.png",
        url: "https://swap.kittypunch.xyz"
    )
    static let Trado = SwapProviderModel(
        title: "Trado",
        icon: "https://cdn.prod.website-files.com/60f008ba9757da0940af288e/66d7acb788c226956c0517db_trado.JPG",
        url: "https://spot.trado.one/trade/swap"
    )
    static let Increment = SwapProviderModel(
        title: "Increment Finance",
        icon: "https://raw.githubusercontent.com/Outblock/Assets/main/dapp/increment/logo.jpeg",
        url: "https://\(currentNetwork == .mainnet ? "app" : "demo")" +
            ".increment.fi/swap"
    )

    let title: String
    let icon: String
    let url: String

    var iconUrl: URL? {
        URL(string: icon)
    }

    var host: String {
        url.removePrefix("https://")
    }
}

#Preview {
    SwapProviderView(token: nil)
}
