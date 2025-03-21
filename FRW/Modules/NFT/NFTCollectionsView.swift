//
//  NFTCollectionsView.swift
//  FRW
//
//  Created by Marty Ulrich on 3/7/25.
//

import SwiftUI
import Combine

struct NFTCollectionsView: View {
    @StateObject var vm: NFTCollectionsViewModel
    @State private var headerHeight: CGFloat = 0
    @AppStorage("isListView") var isListView: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            topBar
            
            content
        }
        .task {
            await vm.refresh()
        }
        .if(vm.dataModel.items.isEmpty) { view in
            return view.backgroundFill(NFTEmptyView())
        }
    }
    
    @ViewBuilder
    private var topBar: some View {
        HStack(alignment: .center, spacing: 16) {
            Text("nft_collections".localized)
                .font(.inter(size: 20, weight: .semibold))
                .foregroundStyle(Color.Theme.Text.text1)
            
            Spacer()
            
            Button {
                vm.onAddButtonTap()
            } label: {
                Image("plus").resizable()
            }
            .buttonStyle(ActionButtonStyle())
            .hidden(ChildAccountManager.shared.selectedChildAccount != nil)
            
            Button {
                isListView.toggle()
            } label: {
                Image(isListView ? "tabler-icon-grid" : "tabler-icon-list")
                    .resizable()
                    .padding(1)
            }
            .buttonStyle(ActionButtonStyle())
        }
        .padding(.leading, 24)
        .padding(.trailing, 18)
        .padding(.vertical, 8)
        .background(.clear)
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            if isListView || vm.dataModel.items.isEmpty {
                listView
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
            } else {
                gridView
                    .padding(.top, -10)
                    .zIndex(-999)
            }
        }
        .background(.clear)
    }
    
    @ViewBuilder
    private var emptyView: some View {
        NFTEmptyView()
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.dataModel.items) { item in
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
                                .foregroundStyle(Color.Theme.Text.text1)
                            Image("flow")
                                .foregroundStyle(Color.Theme.Accent.green)
                        }
                        
                        Text("\(item.count) Collectibles")
                            .font(.inter(size: 16, weight: .regular))
                            .foregroundStyle(Color.Theme.Text.text4)
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 24, height: 24)
            .foregroundStyle(.white)
            .padding(4)
            .background(Color.Theme.Foreground.black3.opacity(0.4))
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
        AnyView(NFTCollectionsView(vm: NFTCollectionsViewModel(tabVM: NFTTabViewModel())))
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
