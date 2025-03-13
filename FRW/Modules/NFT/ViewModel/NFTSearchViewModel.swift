//
//  NFTSearchViewModel.swift
//  FRW
//
//  Created by cat on 3/13/25.
//

import Combine
import Foundation
import SwiftUI

enum NFTLoadingState {
    case idle
    case loading
    case success
    case failure(Error)
}

class NFTSearchViewModel: ObservableObject {
    let collectionInfo: NFTCollectionInfo
    @Published var searchText: String = ""
    @Published var isLoading: Bool = true
    @Published var loadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var nftItems: [NFTModel] = []
    @Published var filteredNFTItems: [NFTModel] = []
    @Published var loadingState: NFTLoadingState = .idle
    @Published var errorMessage: String?
    @Published var isSearching: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var currentBatch: Int = 0
    private let batchSize: Int = 50

    init(_ info: NFTCollectionInfo) {
        collectionInfo = info
        setupBindings()
        loadNFTs()
    }

    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterNFTs(query: searchText)
            }
            .store(in: &cancellables)

        $nftItems
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.filterNFTs(query: self.searchText)
            }
            .store(in: &cancellables)
    }

    private func filterNFTs(query: String) {
        isSearching = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                if query.isEmpty {
                    self.filteredNFTItems = self.nftItems
                } else {
                    self.filteredNFTItems = self.nftItems.filter {
                        $0.title.lowercased().contains(query.lowercased())
                    }
                }
            }

            self.isSearching = false
        }
    }

    func loadNFTs() {
        // reset status
        isLoading = true
        loadingState = .loading
        errorMessage = nil
        nftItems = []
        loadedCount = 0
        currentBatch = 0

        // begin fetch
        fetchNextBatch()
    }

    private func fetchNextBatch() {
        /*
         self.nftItems.append(contentsOf: newItems)

         // update progress
         self.loadedCount += currentBatchSize
         self.currentBatch += 1
         */
    }

    func retry() {
        loadNFTs()
    }
}
