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
                TokenInfoCell(token: item.token, isHidden: false)
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
