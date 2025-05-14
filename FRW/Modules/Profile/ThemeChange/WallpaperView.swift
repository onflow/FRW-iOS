//
//  WallpaperView.swift
//  FRW
//
//  Created by cat on 2024/6/28.
//

import SwiftUI

// MARK: - WallpaperView

struct WallpaperView: RouteableView {
    var title: String {
        "Wallpaper".localized
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 8),
        GridItem(.adaptive(minimum: 150), spacing: 8),
    ]

    @State
    var dynamicCase = CardBackground.dynamicCases

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    Section {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(0 ..< dynamicCase.count, id: \.self) { index in
                                let card = dynamicCase[index]
                                Card(cardBackgroud: card)
                                    .frame(width: (proxy.size.width - 32) / 2.0)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Dynamic")
                                .font(.inter(size: 14, weight: .semibold))
                                .foregroundStyle(Color.Theme.Text.black8)
                            Spacer()
                        }
                        .padding(.leading, 2)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }

                    Section {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(0 ..< CardBackground.imageCases.count, id: \.self) { index in
                                let card = CardBackground.imageCases[index]
                                Card(cardBackgroud: card)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Static")
                                .font(.inter(size: 14, weight: .semibold))
                                .foregroundStyle(Color.Theme.Text.black8)
                            Spacer()
                        }
                        .padding(.leading, 2)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .applyRouteable(self)
        .tracedView(self)
    }
}

// MARK: WallpaperView.Card

extension WallpaperView {
    struct Card: View {
        // MARK: Internal

        var cardBackgroud: CardBackground

        var body: some View {
            VStack {
                Button {
                    walletCardBackrgound = cardBackgroud.rawValue
//                    Router.popToRoot()
                } label: {
                    cardBackgroud.renderView()
                        .cornerRadius(8)
                        .frame(height: 118)
                }
                .buttonStyle(ScaleButtonStyle())
                .clipped()
            }
            .overlay(alignment: .topTrailing, content: {
                Image("wallpaper_check")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .visibility(walletCardBackrgound == cardBackgroud.rawValue ? .visible : .gone)
            })
            .cornerRadius(8)
//            .onTapGesture {
//                log.error("[Paper] click: \(index)-\(cardBackgroud.rawValue)")
//                walletCardBackrgound = cardBackgroud.rawValue
            ////                Router.popToRoot()
//            }
            .clipped()
        }

        // MARK: Private

        @AppStorage("WalletCardBackrgound")
        private var walletCardBackrgound: String = "fade:0"
    }
}

#Preview {
    WallpaperView()
}
