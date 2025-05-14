//
//  BrowserBookmarkView.swift
//  Flow Wallet
//
//  Created by Selina on 10/10/2022.
//

import Kingfisher
import SwiftUI

struct BrowserBookmarkView: RouteableView {
    // MARK: Internal

    var title: String {
        "browser_bookmark".localized
    }

    var body: some View {
        List {
            ForEach(vm.bookmarkList, id: \.id) { bookmark in
                Button {
                    Router.dismiss {
                        if let url = URL(string: bookmark.url) {
                            Router.route(to: RouteMap.Explore.browser(url))
                        }
                    }
                } label: {
                    createCell(bookmark)
                }
                .swipeActions(allowsFullSwipe: false) {
                    Button {
                        vm.deleteBookmarkAction(bookmark)
                    } label: {
                        Text("delete".localized)
                    }
                    .tint(Color.systemRed)
                }
            }
        }
        .listStyle(.plain)
        .listRowInsets(.zero)
        .listRowBackground(Color.LL.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyRouteable(self)
        .tracedView(self)
    }

    func backButtonAction() {
        Router.dismiss()
    }

    func createCell(_ bookmark: WebBookmark) -> some View {
        HStack(spacing: 24) {
            KFImage.url(bookmark.url.toFavIcon())
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(bookmark.title)
                    .font(.Ukraine(size: 14, weight: .bold))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .lineLimit(1)

                Text(bookmark.host)
                    .font(.inter(size: 12, weight: .regular))
                    .foregroundColor(Color.LL.Neutrals.text3)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Private

    @StateObject
    private var vm = BrowserBookmarkViewModel()
}
