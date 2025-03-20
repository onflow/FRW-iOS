//
//  NFTEmptyView.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/13.
//

import SwiftUI

struct NFTEmptyView: View {
    var body: some View {
        VStack {
            Image("nft_empty_image")
                .padding(.bottom, 10)
            
            Text("collection_ready_to_shine".localized)
                .font(.Montserrat(size: 16))
                .fontWeight(.bold)
                .foregroundColor(Color.Theme.Text.black3)
                .padding(6)
            
            Text("start_exploring_nfts".localized)
                .font(.inter(size: 14))
                .foregroundColor(Color.Theme.Text.black3)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(Image("nft_empty_bg").resizable().frame(maxWidth: .infinity, maxHeight: .infinity))
    }
}

#Preview {
    NFTEmptyView()
}
