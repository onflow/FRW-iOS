//
//  ExploreTabScreen.swift
//  Flow Wallet
//
//  Created by Hao Fu on 21/8/2022.
//

import FancyScrollView
import Kingfisher
import SwiftUI
import SwiftUIX

private let BookmarkCellWidth: CGFloat = 56

// MARK: - ExploreTabScreen + AppTabBarPageProtocol

extension ExploreTabScreen: AppTabBarPageProtocol {
    static func tabTag() -> AppTabType {
        .explore
    }

    static func iconName() -> String {
        "tabler-icon-brand-safari"
    }
    
    static func title() -> String {
        "explore".localized
    }
}

// MARK: - ExploreTabScreen

struct ExploreTabScreen: View {
    @StateObject
    private var vm = ExploreTabViewModel()

    @State
    var text: String = ""

    var bookmarkColumns: [GridItem] = Array(
        repeating: .init(.fixed(BookmarkCellWidth), spacing: 14),
        count: 5
    )

    var header: some View {
        Button {
            Router.route(to: RouteMap.Explore.searchExplore)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.LL.bgForIcon)
                    .frame(height: 52)

                HStack(alignment: .center, spacing: 12) {
                    Image("icon-search")
                        .renderingMode(.template)
                        .foregroundColor(.Theme.Text.text4)
                        .frame(width: 24, height: 24)

                    Text("search_name_url".localized)
                        .font(.inter(size: 14))
                        .foregroundColor(.Theme.Text.text4)

                    Spacer()

                    Button {
                        ScanHandler.scan()
                    } label: {
                        Image("icon-wallet-scan")
                            .renderingMode(.template)
                            .foregroundColor(.Theme.Text.text4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            }
        }
        .padding(.horizontal, 16)
    }

    var body: some View {
        VStack(spacing: 12) {
            header

            if vm.state.list.isEmpty && vm.webBookmarkList.isEmpty {
                Spacer()
                ExploreEmptyScreen()
                    .background(.Theme.BG.bg1)
                Spacer()
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 8) {
                        VStack(spacing: 18) {
                            bookmarkHeader
                            bookmarkGrid
                        }
                        .visibility(vm.webBookmarkList.isEmpty ? .gone : .visible)

                        dAppHeader
                            .visibility(vm.state.list.isEmpty ? .gone : .visible)
                        dAppCategory
                            .visibility(vm.state.list.isEmpty ? .gone : .visible)
                        dappList
                            .visibility(vm.state.list.isEmpty ? .gone : .visible)
                    }
                    .background(.Theme.BG.bg1)
                    .padding(.bottom, 18)
                    .padding(.horizontal, 18)
                }
                .background(.Theme.BG.bg1)
                .listStyle(.plain)
            }
        }
        .task {
            vm.trigger(.fetchList)
        }
        .onChange(of: LocalUserDefaults.shared.flowNetwork, perform: { _ in
            vm.trigger(.fetchList)
        })
        .background(
            Color.Theme.BG.bg1.ignoresSafeArea()
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }

    var dAppHeader: some View {
        HStack {
            Text("explore".localized)
                .font(.inter(size: 20, weight: .semibold))
            Spacer()

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    var dAppCategory: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 4) {
                ForEach(vm.state.categoryList, id: \.self) { category in
                    Button {
                        vm.changeCategory(category)
                    } label: {
                        let tintColor = vm.state
                            .selectedCategory == category ? Color.Theme.Accent.green :
                            Color.Theme.Text.text4
                        
                        Text(category.uppercased())
                            .font(.inter(size: 14, weight: .semibold))
                            .foregroundColor(tintColor)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .roundedBg(
                                cornerRadius: 18,
                                fillColor: .clear,
                                strokeColor: tintColor,
                                strokeLineWidth: 1.5
                            )
                            .contentShape(Rectangle())
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .padding(.bottom, 12)
    }

    var dappList: some View {
        ForEach(vm.state.filterdList, id: \.name) { dApp in
            Button {
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
                feedbackGenerator.impactOccurred()

                if LocalUserDefaults.shared.flowNetwork == .testnet,
                   let url = dApp.testnetURL {
                    Router.route(to: RouteMap.Explore.browser(url))
                } else {
                    Router.route(to: RouteMap.Explore.browser(dApp.url))
                }

            } label: {
                HStack(alignment: .top) {
                    KFImage
                        .url(dApp.logo)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44, alignment: .center)
                        .cornerRadius(22)
                        .clipped()
                        .padding(.leading, 8)
                        .padding(.trailing, 16)
                    VStack(alignment: .leading) {
                        HStack {
                            Text(dApp.name)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.LL.text)

                            Spacer()

                            Text(dApp.category.uppercased())
                                .font(.LL.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.LL.outline.opacity(0.2))
                                .foregroundColor(Color.LL.Neutrals.neutrals9)
                                .cornerRadius(20)
                        }

                        Text(dApp.description + "\n")
                            .font(.LL.footnote)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.LL.Neutrals.neutrals7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 12)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 12)
                .background(.clear)
                .cornerRadius(16)
                .borderStyle()
            }
            .buttonStyle(ScaleButtonStyle())
            
        }
    }
}

extension ExploreTabScreen {
    var bookmarkHeader: some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .font(.LL.caption)
            Text("browser_bookmark".localized)
                .bold()

            Spacer()

            Button {
                Router.route(to: RouteMap.Explore.bookmark)
            } label: {
                HStack(spacing: 5) {
                    Text("browser_bookmark_view".localized)
                        .font(.inter(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#7D7AFF"))

                    Image("icon-search-arrow")
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 11)
                        .foregroundColor(Color(hex: "#C2C3F2"))
                }
                .contentShape(Rectangle())
            }
        }
    }

    var bookmarkGrid: some View {
        LazyVGrid(columns: bookmarkColumns, alignment: .center, spacing: 16) {
            ForEach(vm.webBookmarkList, id: \.id) { bookmark in
                createBookmarkItemView(bookmark: bookmark)
            }
        }
    }

    func createBookmarkItemView(bookmark: WebBookmark) -> some View {
        Button {
            if let url = URL(string: bookmark.url) {
                Router.route(to: RouteMap.Explore.browser(url))
            }
        } label: {
            KFImage.url(bookmark.url.toFavIcon())
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: BookmarkCellWidth, height: BookmarkCellWidth)
                .cornerRadius(28)
        }
    }
}

// MARK: - ExploreTabScreen_Previews

struct ExploreTabScreen_Previews: PreviewProvider {
    static var previews: some View {
        ExploreTabScreen()
    }
}
