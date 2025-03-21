//
//  NFTEmptyView.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/13.
//

import RiveRuntime
import SwiftUI

struct NFTEmptyView: View {
    var body: some View {
        ZStack {
//            Image("nft_empty_bg")
//                .resizable()
//                .aspectRatio(contentMode: .fill)

            Color.LL.background
                .ignoresSafeArea()

            RiveViewModel(fileName: "shapes").view()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .blur(radius: 30)
                .blendMode(.hardLight)

            Image("Spline")
                .blur(radius: 50)
                .offset(x: 200, y: 100)

//            VStack {
//                Text("nft_empty".localized)
//                    .font(.LL.mindTitle)
//                    .fontWeight(.bold)
//                    .foregroundColor(.LL.Neutrals.neutrals3)
//                    .padding(2)

//                Spacer()
//                    .frame(height: 18)
//                Button {} label: {
//                    Text("get_new_nft".localized)
//                        .foregroundColor(.LL.Primary.salmonPrimary)
//                }
//                .padding(.vertical, 10)
//                .padding(.horizontal, 44)
//                .background(Color.LL.Primary.salmonPrimary.opacity(0.08))
//                .cornerRadius(12)
//            }
        }
        .clipped()
    }
}

// struct EmptyNFTView_Previews: PreviewProvider {
//    static var previews: some View {
//        NFTEmptyView()
//    }
// }
