//
//  NFTSearchViewModel.swift
//  FRW
//
//  Created by cat on 3/13/25.
//

import Combine
import Foundation
import SwiftUI

enum NFTLoadingState: Equatable {
    case idle
    case loading
    case success
    case failure(Error)

    static func == (lhs: NFTLoadingState, rhs: NFTLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.success, .success):
            return true
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}

@MainActor
class NFTSearchViewModel: ObservableObject {
    let collectionInfo: NFTCollectionInfo
    @Published var searchText: String = ""
    @Published var loadedCount: Int = 0
    @Published var totalCount: Int = 0
    @Published var nftItems: [NFTModel] = []
    @Published var filteredNFTItems: [NFTModel] = []
    @Published var loadingState: NFTLoadingState = .idle
    @Published var errorMessage: String?

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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                if query.isEmpty {
                    self.filteredNFTItems = self.nftItems
                } else {
                    self.filteredNFTItems = self.nftItems.filter {
                        $0.searchText.lowercased().contains(query.lowercased())
                    }
                }
            }
        }
    }

    func loadNFTs() {
        // reset status
        loadingState = .loading
        errorMessage = nil
        nftItems = []
        loadedCount = 0
        currentBatch = 0

        // begin fetch
        fetchNextBatch()
    }

    private func fetchNextBatch() {
        guard let addr = WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
              let address = FWAddressDector.create(address: addr)
        else {
            loadingState = .failure(LLError.invalidAddress)
            return
        }
        Task {
            do {
                let result = try await TokenBalanceHandler.shared.getAllNFTsUnderCollection(address: address, collectionIdentifier: collectionInfo.id) { cur, total in
                    runOnMain {
                        self.loadedCount = cur
                        self.totalCount = total
                    }
                }
                await MainActor.run {
                    self.nftItems = result
                    self.loadingState = .success
                }
            } catch {
                loadingState = .failure(error)
                self.nftItems = []
            }
        }
    }

    func retry() {
        loadNFTs()
    }
}
