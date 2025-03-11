//
//  NFTTabScreen.swift
//  Flow Wallet
//
//  Created by Hao Fu on 16/1/22.
//

// Make sure you added this dependency to your project
// More info at https://bit.ly/CVPagingLayout
import CollectionViewPagingLayout
import IrregularGradient
import Kingfisher
import Lottie
import SwiftUI
import WebKit

// MARK: - NFTTabScreen + AppTabBarPageProtocol

extension NFTTabScreen: AppTabBarPageProtocol {
    static func tabTag() -> AppTabType {
        .nft
    }

    static func iconName() -> String {
        "layout-grid"
    }
    
    static func title() -> String {
        "NFTs::message".localized
    }
}

// MARK: - NFTTabScreen

struct NFTTabScreen: View {
    @StateObject
    var viewModel = NFTTabViewModel()

    @State
    var offset: CGFloat = 0

    @Namespace
    var NFTImageEffect

    let modifier = AnyModifier { request in
        var r = request
        r.setValue("APKAJYJ4EHJ62UVUHINA", forHTTPHeaderField: "CloudFront-Key-Pair-Id")
        return r
    }

    var body: some View {
        NFTCollectionsView(vm: NFTCollectionsViewModel(dataFetcher: NFTUIKitListNormalDataModel(), tabVM: viewModel))
            .backgroundFill(Color.LL.Neutrals.background.ignoresSafeArea())
            .ignoresSafeArea()
    }
}

// MARK: NFTTabScreen.Layout

extension NFTTabScreen {
    private enum Layout {
        static let menuHeight = 32.0
    }
}

// MARK: NFTTabScreen.CollectionBar

extension NFTTabScreen {
    struct CollectionBar: View {
        enum BarStyle {
            case horizontal
            case vertical

            // MARK: Internal

            mutating func toggle() {
                switch self {
                case .horizontal:
                    self = .vertical
                case .vertical:
                    self = .horizontal
                }
            }
        }

        @Binding
        var barStyle: NFTTabScreen.CollectionBar.BarStyle
        @Binding
        var listStyle: String

        var body: some View {
            VStack {
                if listStyle == "List" {
                    HStack {
                        Image(.Image.Logo.collection3D)
                        Text("collections".localized)
                            .font(.LL.largeTitle2)
                            .semibold()

                        Spacer()
                        Button {
                            barStyle.toggle()
                        } label: {
                            Image(
                                barStyle == .horizontal ? .Image.Logo.gridHLayout : .Image.Logo
                                    .gridHLayout
                            )
                        }
                    }
                    .foregroundColor(.LL.text)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                } else {
                    HStack {}
                        .frame(height: 0)
                }
            }
            .padding(.top, 36)
            .background(
                Color.LL.Neutrals.background
            )
        }
    }
}

// MARK: - NFTTabScreen_Previews

struct NFTTabScreen_Previews: PreviewProvider {
    static var previews: some View {
        NFTTabScreen()
    }
}
