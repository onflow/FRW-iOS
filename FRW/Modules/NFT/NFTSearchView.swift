//
//  NFTSearchView.swift
//  FRW
//
//  Created by cat on 3/13/25.
//

import SwiftUI

struct NFTSearchView: RouteableView {
    @StateObject private var viewModel: NFTSearchViewModel
    @FocusState private var isSearchFocused: Bool
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

            if !viewModel.isLoading && !viewModel.filteredNFTItems.isEmpty {
                nftCountView
            }

            if case .failure = viewModel.loadingState {
                errorView
            } else if viewModel.isLoading {
                loadingStateView
            } else {
                nftGridView
                    .animation(.easeInOut, value: viewModel.searchText)
            }
        }
        .applyRouteable(self)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    var nftCountView: some View {
        HStack {
            Text(viewModel.filteredNFTItems.count == viewModel.totalCount ? "All" : "Result")
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
            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.gray)

                TextField("Search NFT Name", text: $viewModel.searchText)
                    .font(.inter())
                    .foregroundStyle(Color.Theme.Text.black3)
                    .focused($isSearchFocused)

                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        withAnimation {
                            viewModel.searchText = ""
                        }
                    }) {
                        Image("icon_close_circle_gray")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(16)
            .background(Color.Theme.Fill.fill1)
            .cornerRadius(16)

            Button(action: {
                viewModel.searchText = ""
                isSearchFocused = false
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
            .animation(.easeInOut(duration: 0.3), value: viewModel.searchText)
        }
    }

    @ViewBuilder
    var errorView: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Error, please check your internet or refresh.")
                .font(.inter(weight: .semibold))
                .foregroundStyle(Color.Theme.Text.black6)
                .multilineTextAlignment(.center)

            Button(action: {
                viewModel.retry()
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Refresh::message".localized)
                        .font(.inter(weight: .semibold))
                        .foregroundStyle(Color.Theme.Text.black6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(Color.Theme.Text.black, lineWidth: 1)
                )
            }
            .foregroundColor(.primary)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    NFTSearchView(collection: .init(id: "", name: nil, contractName: nil, address: nil, logo: nil, banner: nil, officialWebsite: nil, description: nil, path: nil, evmAddress: nil, flowIdentifier: nil))
}
