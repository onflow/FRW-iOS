//
//  ManagerTokensItemView.swift
//  FRW
//
//  Created by cat on 5/6/25.
//

import Kingfisher
import SwiftUI

private let CoinIconHeight: CGFloat = 44
private let CoinCellHeight: CGFloat = 76

struct ManagerTokensItemView: View {
    let item: ManagerTokensViewModel.Item
    var callback: (TokenModel, Bool) -> Void

    var body: some View {
        VStack {
            Toggle(isOn: .init(get: { item.isOpen }, set: { callback(item.token, $0) })) {
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 18) {
                        KFImage.url(item.token.iconURL)
                            .placeholder {
                                Image("placeholder")
                                    .resizable()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: CoinIconHeight, height: CoinIconHeight)
                            .clipShape(Circle())

                        HStack(spacing: 0) {
                            Text(item.token.name)
                                .foregroundColor(Color.Theme.Text.text1)
                                .font(.inter(size: 14, weight: .bold))
                            Image("icon-token-valid")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .visibility(item.token.isVerifiedValue ? .visible : .gone)
                            Spacer()
                        }
                    }
                    .frame(minHeight: CoinCellHeight)
                }
                .background(.clear)
            }
            .padding(2)
            Divider()
        }
    }
}

#Preview {
    ManagerTokensItemView(item: .init(token: .mock(), isOpen: true)) { _, _ in
    }
//    .padding()
    .background(Color.red)
}
