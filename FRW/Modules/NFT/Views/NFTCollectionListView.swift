//
//  NFTCollectionListView.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/30.
//

import Kingfisher
import SwiftUI

// MARK: - NFTCollectionListViewViewModel

class NFTCollectionListViewViewModel: ObservableObject {
    // MARK: Lifecycle

    convenience init(address: String, path: String) {
        let item = CollectionItem.mock()
        self.init(collection: item)
        self.address = address
        collectionPath = path
        isLoading = true
    }

    init(collection: CollectionItem) {
        self.collection = collection
        nfts = collection.nfts

        collection.loadCallback2 = { [weak self] result in
            guard let self = self else {
                return
            }

            if result {
                if let proxy = self.proxy {
                    proxy.scrollTo(999, anchor: .bottom)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.nfts = self.collection.nfts
                }
            }
        }

        if collection.nfts.isEmpty {
            collection.load(address: address)
        }
    }

    // MARK: Internal

    @Published
    var collection: CollectionItem
    @Published
    var nfts: [NFTModel] = []

    var address: String?
    var collectionPath: String?
    @Published
    var isLoading = false

    func load(address: String, path: String) {
        self.address = address
        collectionPath = path
        isLoading = true
        fetch()
    }

    func load(collection: CollectionItem) {
        self.collection = collection
        nfts = collection.nfts

        collection.loadCallback2 = { [weak self] result in
            guard let self = self else {
                return
            }

            if result {
                if let proxy = self.proxy {
                    proxy.scrollTo(999, anchor: .bottom)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.nfts = self.collection.nfts
                }
            }
        }

        if collection.nfts.isEmpty {
            collection.load()
        }
    }

    func fetch() {
        Task {
            guard let path = collectionPath else {
                return
            }

            do {
                let address = address ?? WalletManager.shared.selectedAccountAddress
                let from: VMType = EVMAccountManager.shared
                    .selectedAccount != nil ? .evm : .cadence
                let request = NFTCollectionDetailListRequest(
                    address: address,
                    collectionIdentifier: path,
                    offset: String(0),
                    limit: 24
                )
                let response: NFTListResponse = try await Network
                    .request(FRWAPI.NFT.collectionDetailList(
                        request,
                        from
                    ))

                await MainActor.run {
                    self.collection = response.toCollectionItem()
                    self.nfts = self.collection.nfts
                    self.isLoading = false
                }

            } catch {
                print(error)
            }
        }
    }

    func loadMoreAction(proxy: ScrollViewProxy) {
        self.proxy = proxy
        collection.load()
    }

    // MARK: Private

    private var proxy: ScrollViewProxy?
}

// MARK: - NFTCollectionListView

struct NFTCollectionListView: RouteableView {
    // MARK: Lifecycle

    init(viewModel: NFTTabViewModel, collection: CollectionItem) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _vm = StateObject(wrappedValue: NFTCollectionListViewViewModel(collection: collection))
    }

    init(address: String, path: String, from linkedAccount: ChildAccount?) {
        _viewModel = StateObject(wrappedValue: NFTTabViewModel())
        _vm = StateObject(wrappedValue: NFTCollectionListViewViewModel(
            address: address,
            path: path
        ))
        childAccount = linkedAccount
    }

    // MARK: Internal

    @StateObject
    var viewModel: NFTTabViewModel
    @StateObject
    var vm: NFTCollectionListViewViewModel

    @State
    var opacity: Double = 0
    @Namespace
    var imageEffect

    var childAccount: ChildAccount?

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                OffsetScrollViewWithAppBar(
                    title: vm.collection.showName,
                    loadMoreEnabled: true,
                    loadMoreCallback: {
                        if vm.collection.isRequesting || vm.collection.isEnd {
                            return
                        }

                        vm.loadMoreAction(proxy: proxy)
                    },
                    isNoData: vm.collection.isEnd
                ) {
                    Spacer()
                        .frame(height: 64)

                    if let collection = vm.collection.collection {
                        CalloutView(
                            type: .warning,
                            corners: [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading],
                            content: calloutTitle()
                        )
                        .padding(.bottom, 20)
                        .padding(.horizontal, 18)
                        .visibility(
                            WalletManager.shared.accessibleManager
                                .isAccessible(collection) ? .gone : .visible
                        )
                    }

                    InfoView(collection: vm.collection)
                        .padding(.bottom, 24)
                        .mockPlaceholder(vm.isLoading)
                    NFTListView(
                        list: vm.nfts,
                        imageEffect: imageEffect,
                        fromChildAccount: childAccount
                    )
                    .padding(.horizontal, 16)
                    .id(999)
                    .mockPlaceholder(vm.isLoading)
                } appBar: {
                    BackAppBar(rightButton: .search {
                        viewModel.trigger(.search(vm.collection))
                    }) {
                        viewModel.trigger(.back)
                    }
                }
            }
        }
        .background(
            NFTBlurImageView(
                colors: viewModel.state
                    .colorsMap[vm.collection.iconURL.absoluteString] ?? []
            )
            .ignoresSafeArea()
            .offset(y: -4)
        )
        .applyRouteable(self)
        .environmentObject(viewModel)
        .onAppear {
            vm.fetch()
        }
    }

    // MARK: Private

    private func calloutTitle() -> String {
        let token = vm.collection.name
        let account = WalletManager.shared.selectedAccountWalletName
        let desc = "accessible_not_x_x".localized(token, account)
        return desc
    }
}

// MARK: NFTCollectionListView.InfoView

extension NFTCollectionListView {
    struct InfoView: View {
        @EnvironmentObject
        private var viewModel: NFTTabViewModel

        var collection: CollectionItem

        var body: some View {
            HStack(spacing: 0) {
                KFImage
                    .url(collection.iconURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .onSuccess { _ in
                        viewModel.trigger(.fetchColors(collection.iconURL.absoluteString))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 108, height: 108, alignment: .center)
                    .cornerRadius(12)
                    .clipped()
                    .padding(.leading, 18)
                    .padding(.trailing, 20)

                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .center) {
                        Text(collection.name)
                            .font(.LL.largeTitle3)
                            .fontWeight(.w700)
                            .foregroundColor(.LL.Neutrals.text)
                        Image("Flow")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    .frame(height: 28)

                    Text("x_collections".localized(collection.count))
                        .font(.LL.body)
                        .fontWeight(.w400)
                        .foregroundColor(.LL.Neutrals.neutrals4)
                        .padding(.bottom, 18)
                        .frame(height: 20)

                    HStack(spacing: 8) {
//                        Button {
//
//                        } label: {
//                            Image("nft_button_share_inline")
//                            Text("share".localized)
//                                .font(.LL.body)
//                                .fontWeight(.w600)
//                                .foregroundColor(.LL.Neutrals.neutrals3)
//                        }
//                        .padding(.horizontal, 10)
//                        .frame(height: 38)
//                        .background(.thinMaterial)
//                        .cornerRadius(12)

                        Button {} label: {
                            Image("nft_button_explore")
                            Text("explore".localized)
                                .font(.LL.body)
                                .fontWeight(.w600)
                                .foregroundColor(.LL.Neutrals.neutrals3)
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(.thinMaterial)
                        .cornerRadius(12)
                    }
                }
                .background(Color.clear)
                Spacer()
            }
        }
    }
}

// MARK: - NFTCollectionListView_Previews

struct NFTCollectionListView_Previews: PreviewProvider {
    static var item = NFTTabViewModel.testCollection()

    static var previews: some View {
        NFTCollectionListView(viewModel: NFTTabViewModel(), collection: item)
    }
}
