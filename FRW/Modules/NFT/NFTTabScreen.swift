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
        NFTCollectionsView(vm: NFTCollectionsViewModel(tabVM: viewModel))
    }
}
 
// MARK: - NFTTabScreen_Previews

struct NFTTabScreen_Previews: PreviewProvider {
    static var previews: some View {
        NFTTabScreen()
    }
}
