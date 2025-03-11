//
//  NFTCollectionsView.swift
//  FRW
//
//  Created by Marty Ulrich on 3/7/25.
//

import SwiftUI
import Combine

// MARK: - Protocols

protocol NFTCollectionsDataFetcher {
    func refreshCollections() async throws -> [CollectionItem]
}

extension NFTUIKitListNormalDataModel: NFTCollectionsDataFetcher {
    func refreshCollections() async throws -> [CollectionItem] {
        try await refreshCollectionAction()
        return items
    }
}

// MARK: - ViewModel

@MainActor
final class NFTCollectionsViewModel: ObservableObject {
    @Published private(set) var collections: [CollectionItem] = []
    @Published var isListView: Bool = true
    @Published var isRefreshing: Bool = false
    @Published var tabVM: NFTTabViewModel
    
    lazy var dataModel: NFTUIKitListNormalDataModel = {
        let dm = NFTUIKitListNormalDataModel()
        dm.reloadCallback = { [weak self] in
            Task {
                await self?.refresh()
            }
        }
        
        return dm
    }()
    
    private let dataFetcher: NFTCollectionsDataFetcher
    
    init(dataFetcher: NFTCollectionsDataFetcher, tabVM: NFTTabViewModel) {
        self.dataFetcher = dataFetcher
        self.tabVM = tabVM
    }
    
    func refresh() async {
        if isRefreshing {
            return
        }
        do {
            isRefreshing = true
            let fetched = try await dataFetcher.refreshCollections()
            collections = fetched
            isRefreshing = false
        } catch {
            // Handle error appropriately or rethrow
        }
    }
    
    func toggleViewStyle() {
        isListView.toggle()
    }
    
    func onAddButtonTap() {
        Router.route(to: RouteMap.NFT.addCollection)
    }
    
    func onCollectionSelection(_ collection: CollectionItem) {
        Router.route(to: RouteMap.NFT.collection(tabVM, collection))
    }
}

// MARK: - Mock Fetcher & Mock VM (for Preview)

struct MockNFTCollectionsFetcher: NFTCollectionsDataFetcher {
    func refreshCollections() async throws -> [CollectionItem] {
        [
            CollectionItem.mock(),
            CollectionItem.mock()
        ]
    }
}

// MARK: - Main View

struct NFTCollectionsView: View {
    @StateObject var vm: NFTCollectionsViewModel
    @State private var headerHeight: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            content
        }
        .task {
            await vm.refresh()
        }
        .backgroundFill(.LL.Neutrals.background)
    }
    
    @ViewBuilder
    private var topBar: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("NFT Collections")
                .font(.inter(size: 20, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? Color(hex: "FFFFFF") : Color.Theme.Text.black8)
            
            Spacer()
            
            Button {
                vm.onAddButtonTap()
            } label: {
                Image("plus").resizable()
            }
            .buttonStyle(ActionButtonStyle())
            .hidden(ChildAccountManager.shared.selectedChildAccount != nil)
            
            Button {
                vm.toggleViewStyle()
            } label: {
                Image(vm.isListView ? "tabler-icon-grid" : "tabler-icon-list")
                    .resizable()
                    .padding(1)
            }
            .buttonStyle(ActionButtonStyle())
        }
        .padding(.leading, 24)
        .padding(.trailing, 18)
        .padding(.vertical, 24)
        .background(.clear)
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            if vm.dataModel.items.isEmpty {
                EmptyView()
            } else if vm.isListView {
                listView
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
            } else {
                gridView
                    .padding(.top, -20)
                    .background(.clear)
            }
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        NFTBlurImageView(
            colors: [.red, .blue] //vm.tabVM.state
//                .colorsMap[vm.collection.iconURL.absoluteString] ?? []
        )
        .ignoresSafeArea()
        .offset(y: -4)
    }
    
    @ViewBuilder
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.collections) { item in
                    NFTCollectionListCell(item: item) {
                        vm.onCollectionSelection(item)
                    }
                }
            }
            .sn_introspectScrollView { scrollView in
                scrollView.setRefreshingAction {
                    Task {
                        await vm.refresh()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var gridView: some View {
        NFTUIKitListView(vm: vm.tabVM)
    }
}

// MARK: - Row View

extension NFTCollectionsView {
    struct NFTCollectionListCell: View {
        let item: CollectionItem
        let action: () -> ()
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Button {
                action()
            } label: {
                HStack {
                    iconView
                        .frame(width: 40, height: 40)
                        .cornerRadius(20)
                        .padding(.leading, 16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.showName)
                                .font(.inter(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: colorScheme == .dark ? "ffffff" : "333333"))
                            Image("flow")
                                .foregroundStyle(Color.Theme.Accent.green)
                        }
                        
                        Text("\(item.count) Collectibles")
                            .font(.inter(size: 16, weight: .regular))
                            .foregroundStyle(Color(hex: colorScheme == .dark ? "ffffff" : "000000"))
                            .opacity(colorScheme == .dark ? 0.4 : 0.3)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Image("tabler-icon-arrow-narrow-right")
                        .padding(.trailing, 16)
                        .foregroundStyle(Color.Theme.Accent.green)
                }
                .padding(.vertical, 17)
                .borderStyle()
            }
        }
        
        private var iconView: some View {
            AsyncImage(url: item.iconURL) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit()
                } else {
                    Image("placeholder")
                        .resizable()
                        .scaledToFit()
                }
            }
        }
    }
}

struct ActionButtonStyle: SwiftUI.ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 24, height: 24)
            .foregroundStyle(.white)
            .padding(4)
            .background(colorScheme == .dark ? .white.opacity(0.3) : .Theme.Foreground.black3.opacity(0.24))
            .opacity(configuration.isPressed ? 0.5 : 1)
            .clipShape(Circle())
    }
}

// MARK: - Preview

#Preview {
    let nft = TabBarPageModel<AppTabType?>(
        tag: NFTTabScreen.tabTag(),
        iconName: NFTTabScreen.iconName(),
        title: NFTTabScreen.title()
    ) {
        AnyView(NFTCollectionsView(vm: NFTCollectionsViewModel(dataFetcher: MockNFTCollectionsFetcher(), tabVM: NFTTabViewModel())))
    }
    TabBarView<AppTabType?>(
        current: .nft,
        pages: [nft],
        maxWidth: UIScreen.main.bounds.width
    )
}

#Preview {
    NFTCollectionsView.NFTCollectionListCell(
        item: CollectionItem.mock(), action: {}
    )
}
