//
//  NFTUIKitListDataSource.swift
//  Flow Wallet
//
//  Created by Selina on 15/8/2022.
//

import UIKit

class NFTUIKitListGridDataModel {
    var nfts: [NFTModel] = []
    var isEnd: Bool = false
    var reloadCallback: (() -> Void)?

    init() {
        loadCache()
        NotificationCenter.default.addObserver(self, selector: #selector(onCacheChanged), name: .nftCacheDidChanged, object: nil)
    }

    @objc private func onCacheChanged() {
        loadCache()
        reloadCallback?()
    }

    private func loadCache() {
        if let cachedNFTs = NFTUIKitCache.cache.getGridNFTs() {
            let models = cachedNFTs.map { NFTModel($0, in: nil) }
            nfts = models
        } else {
            nfts = []
        }
    }

    func requestGridAction(offset: Int) async throws {
        DispatchQueue.syncOnMain {
            self.nfts.removeAll()
        }
        let limit = 24
        let nfts = try await requestGrid(offset: offset, limit: limit)
        DispatchQueue.syncOnMain {
            if offset == 0 {
                self.nfts.removeAll()
            }

            self.appendGridNFTsNoDuplicated(nfts)
            self.isEnd = nfts.count < limit
            self.saveToCache()
        }
    }

    private func requestGrid(offset: Int, limit: Int = 24) async throws -> [NFTModel] {
        guard let address = WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() else {
            return []
        }

//        if EVMAccountManager.shared.selectedAccount != nil {
//            let response: [EVMCollection] =  try await Network.request(FRWAPI.EVM.nfts(address))
//            let list = response.map { $0.toNFTCollection() }
//            let nfts = list.compactMap { $0.evmNFTs }
//            return Array(nfts.joined())
//        }

        let request = NFTGridDetailListRequest(address: address, offset: offset, limit: limit)
        let from: FRWAPI.From = EVMAccountManager.shared.selectedAccount != nil ? .evm : .main
        let response: Network.Response<NFTListResponse> = try await Network.requestWithRawModel(FRWAPI.NFT.gridDetailList(request, from))

        guard let nfts = response.data?.nfts else {
            return []
        }

        let models = nfts.map { NFTModel($0, in: nil) }
        return models
    }

    private func appendGridNFTsNoDuplicated(_ newNFTs: [NFTModel]) {
        for nft in newNFTs {
            let exist = nfts.first { $0.id == nft.id }

            if exist == nil {
                nfts.append(nft)
            }
        }
    }

    private func saveToCache() {
        let array = nfts.map { $0.response }
        NFTUIKitCache.cache.saveGridToCache(array)
    }
}

class NFTUIKitListNormalDataModel {
    var items: [CollectionItem] = []
    var selectedIndex = 0
    var isCollectionListStyle: Bool = false
    var reloadCallback: (() -> Void)?

    init() {
        loadCache()
        NotificationCenter.default.addObserver(self, selector: #selector(onCacheChanged), name: .nftCacheDidChanged, object: nil)
    }

    @objc private func onCacheChanged() {
        loadCache()

        if items.isEmpty {
            selectedIndex = 0
        } else if selectedIndex >= items.count {
            selectedIndex -= 1
        }

        reloadCallback?()
    }

    private func loadCache() {
        if var cachedCollections = NFTUIKitCache.cache.getCollections(), let address = WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() {
            cachedCollections.sort {
                if $0.count == $1.count {
                    return ($0.collection.contractName ?? "") < ($1.collection.contractName ?? "")
                }

                return $0.count > $1.count
            }

            var items = [CollectionItem]()
            for collection in cachedCollections {
                let item = CollectionItem()
                item.address = address
                item.name = collection.collection.contractName ?? ""
                item.collectionId = collection.collection.id
                item.count = collection.count
                item.collection = collection.collection

                item.loadFromCache()

                items.append(item)
            }

            self.items = items
        } else {
            items = []
        }
    }

    var selectedCollectionItem: CollectionItem? {
        if selectedIndex >= items.count {
            return nil
        }

        return items[selectedIndex]
    }

    func refreshCollectionAction() async throws {
        DispatchQueue.syncOnMain {
            self.items = []
        }
        var collecitons = try await requestCollections()

        removeAllCache()

        guard let address = WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() else {
            DispatchQueue.syncOnMain {
                self.items = []
            }
            return
        }

        collecitons.sort {
            if $0.count == $1.count {
                return ($0.collection.contractName ?? "") < ($1.collection.contractName ?? "")
            }

            return $0.count > $1.count
        }

        NFTUIKitCache.cache.saveCollectionToCache(collecitons)

        var items = [CollectionItem]()
        for collection in collecitons {
            let item = CollectionItem()
            item.address = address
            item.name = collection.collection.contractName ?? ""
            item.collectionId = collection.collection.id
            item.count = collection.count
            item.collection = collection.collection
            if let list = collection.evmNFTs {
                item.nfts = list
            }
            items.append(item)
        }

        DispatchQueue.syncOnMain {
            self.items = items
        }
    }

    private func requestCollections() async throws -> [NFTCollection] {
        guard let address = WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() else {
            return []
        }

        let from: FRWAPI.From = EVMAccountManager.shared.selectedAccount != nil ? .evm : .main
        let response: Network.Response<[NFTCollection]> = try await Network.requestWithRawModel(FRWAPI.NFT.userCollection(address, FRWAPI.Offset(start: 0, length: 100), from))
        if let list = response.data {
            return list
        } else {
            return []
        }
    }

    private func removeAllCache() {
        NFTUIKitCache.cache.removeCollectionCache()
        NFTUIKitCache.cache.removeAllNFTs()
    }
}
