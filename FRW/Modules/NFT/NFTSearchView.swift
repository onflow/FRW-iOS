//
//  NFTSearchView.swift
//  FRW
//
//  Created by cat on 3/13/25.
//

import SwiftUI

struct NFTSearchView: RouteableView {
    @StateObject private var viewModel: NFTSearchViewModel
    @State private var isSearchFocused: Bool = false
    @Namespace private var imageEffect

    var childAccount: ChildAccount?

    var title: String {
        return ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    init(collection: NFTCollectionInfo) {
        _viewModel = StateObject(wrappedValue: NFTSearchViewModel(collection))
    }

    var body: some View {
        VStack(spacing: 20) {
            searchBar

            if viewModel.loadingState == .success && !viewModel.nftItems.isEmpty {
                nftCountView
            }

            if case .failure = viewModel.loadingState {
                errorView
            } else if viewModel.loadingState == .loading {
                loadingStateView
            } else {
                nftGridView
                    .animation(.easeInOut, value: viewModel.searchText)
            }
        }
        .applyRouteable(self)
        .tracedView(self)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    var nftCountView: some View {
        HStack {
            Text(viewModel.filteredNFTItems.count == viewModel.totalCount ? "All::message".localized : "result".localized)
                .font(.inter(weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black3)
            Spacer()
            Text("\(viewModel.filteredNFTItems.count) \("NFTs::message".localized)")
                .font(.inter(weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black3)
        }
    }

    @ViewBuilder
    var loadingStateView: some View {
        NFTLoadingView(loadedCount: viewModel.loadedCount, totalCount: viewModel.totalCount)
    }

    @ViewBuilder
    var searchBar: some View {
        HStack(spacing: 8) {
            SearchBar(placeholder: "search_nft_name".localized, searchText: $viewModel.searchText, isFocused: $isSearchFocused)

            Button(action: {
                viewModel.searchText = ""
                isSearchFocused = false
                Router.pop()
            }) {
                Text("Cancel")
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(Color.Theme.Text.black)
            }
            .padding(.leading, 4)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }

    @ViewBuilder
    var nftGridView: some View {
        ScrollView {
            NFTListView(
                list: viewModel.filteredNFTItems,
                imageEffect: imageEffect,
                fromChildAccount: childAccount
            )
            .environmentObject(NFTTabViewModel())
            .animation(.easeInOut(duration: 0.3), value: viewModel.searchText)
        }
        .overlay {
            if viewModel.filteredNFTItems.isEmpty {
                CollectionEmptyView()
            }
        }
    }

    @ViewBuilder
    var errorView: some View {
        ErrorWithTryView(
            message: .check,
            retryAction: viewModel.retry
        )
    }
}

#Preview {
    NFTSearchView(collection: .init(id: "", name: nil, contractName: nil, address: nil, logo: nil, banner: nil, officialWebsite: nil, description: nil, path: nil, evmAddress: nil, flowIdentifier: nil))
}
