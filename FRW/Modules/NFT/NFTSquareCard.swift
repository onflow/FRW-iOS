//
//  NFTSquareCard.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/16.
//

import Kingfisher
import SwiftUI

// MARK: - NFTSquareCard

struct NFTSquareCard: View {
    // MARK: Internal

    var nft: NFTModel
    var imageEffect: Namespace.ID
    var onClick: (NFTModel) -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                KFImage
                    .url(nft.imageURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.width, alignment: .center)
                    .cornerRadius(8)
                    .matchedGeometryEffect(id: nft.id, in: imageEffect)
                    .clipped()
                Text(nft.title)
                    .font(.LL.body)
                    .semibold()
                    .lineLimit(1)

                HStack {
                    Text("Inaccessible".localized)
                        .foregroundStyle(Color.LL.Primary.salmonPrimary)
                        .font(Font.inter(size: 10, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 5)
                        .background(.LL.Primary.salmon5.opacity(0.75))
                        .cornerRadius(4, style: .continuous)
                        .visibility(isAccessible() ? .gone : .visible)

                    Text(nft.subtitle)
                        .font(.LL.body)
                        .foregroundColor(.LL.note)
                        .lineLimit(1)
                        .visibility(isAccessible() ? .visible : .gone)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let amount = nft.response.amount, nft.ERCType == .erc1155 {
                    Text(amount)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.white9)
                        .frame(width: 22, height: 22)
                        .background(Color.Theme.Background.icon)
                        .clipShape(Circle())
                        .offset(x: -8, y: 8)
                }
            }
        }
        .onTapGesture {
            onClick(nft)
        }
    }

    // MARK: Private

    private func isAccessible() -> Bool {
        let nftAccessible = WalletManager.shared.accessibleManager.isAccessible(nft)
        guard let collection = nft.collection else {
            return nftAccessible
        }
        let collectionAccessible = WalletManager.shared.accessibleManager.isAccessible(collection)
        return collectionAccessible && nftAccessible
    }
}

// MARK: - NFTSquareCard_Previews

struct NFTSquareCard_Previews: PreviewProvider {
    @Namespace
    static var namespace

    static var previews: some View {
        NFTSquareCard(nft: NFTTabViewModel.testNFT(), imageEffect: namespace, onClick: { _ in

        })
        .frame(width: 160)
    }
}
