//
//  NFTUIKitCache.swift
//  Flow Wallet
//
//  Created by Selina on 16/8/2022.
//

import UIKit
import WidgetKit

// MARK: - NFTUIKitCache

class NFTUIKitCache {
    // MARK: Lifecycle

    init() {
        createFolderIfNeeded()
        loadFavCache()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willReset),
            name: .willResetWallet,
            object: nil
        )
    }

    // MARK: Internal

    static let cache = NFTUIKitCache()

    private(set) var favList: [NFTModel] = []

    // MARK: Private

    private lazy var rootFolder = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
    ).first!.appendingPathComponent("nft_uikit_cache")

    private lazy var collectionFolder = rootFolder.appendingPathComponent("collection")
    private lazy var collectionCacheFile = collectionFolder
        .appendingPathComponent("collection_cache_file")

    private lazy var nftFolder = rootFolder.appendingPathComponent("nft")

    private lazy var gridFolder = rootFolder.appendingPathComponent("grid")
    private lazy var gridCacheFile = gridFolder.appendingPathComponent("grid_cache_file")

    private lazy var favFolder = rootFolder.appendingPathComponent("fav")
    private lazy var favCacheFile = gridFolder.appendingPathComponent("fav_cache_file")

    private var favIsRequesting: Bool = false

    @objc
    private func willReset() {
        favList = []
        removeCollectionCache()
        removeAllNFTs()
        removeGridCache()
        removeFavCache()
    }

    private func createFolderIfNeeded() {
        do {
            if !FileManager.default.fileExists(atPath: rootFolder.relativePath) {
                try FileManager.default.createDirectory(
                    at: rootFolder,
                    withIntermediateDirectories: true
                )
            }

            if !FileManager.default.fileExists(atPath: collectionFolder.relativePath) {
                try FileManager.default.createDirectory(
                    at: collectionFolder,
                    withIntermediateDirectories: true
                )
            }

            if !FileManager.default.fileExists(atPath: nftFolder.relativePath) {
                try FileManager.default.createDirectory(
                    at: nftFolder,
                    withIntermediateDirectories: true
                )
            }

            if !FileManager.default.fileExists(atPath: gridFolder.relativePath) {
                try FileManager.default.createDirectory(
                    at: gridFolder,
                    withIntermediateDirectories: true
                )
            }

            if !FileManager.default.fileExists(atPath: favFolder.relativePath) {
                try FileManager.default.createDirectory(
                    at: favFolder,
                    withIntermediateDirectories: true
                )
            }
        } catch {
            debugPrint("NFTUIKitCache -> createFolderIfNeeded error: \(error)")
        }
    }
}

// MARK: - Grid

extension NFTUIKitCache {
    func saveGridToCache(_ nfts: [NFTResponse]) {
        if nfts.isEmpty {
            removeGridCache()
            return
        }

        do {
            let data = try JSONEncoder().encode(nfts)
            try data.write(to: gridCacheFile)
        } catch {
            debugPrint("NFTUIKitCache -> saveGridToCache: error: \(error)")
            removeGridCache()
        }
    }

    func removeGridCache() {
        if FileManager.default.fileExists(atPath: gridCacheFile.relativePath) {
            do {
                try FileManager.default.removeItem(at: gridCacheFile)
            } catch {
                debugPrint("NFTUIKitCache -> removeGridCache error: \(error)")
            }
        }
    }

    func getGridNFTs() -> [NFTResponse]? {
        if !FileManager.default.fileExists(atPath: gridCacheFile.relativePath) {
            return nil
        }

        do {
            let data = try Data(contentsOf: gridCacheFile)
            let nfts = try JSONDecoder().decode([NFTResponse].self, from: data)
            return nfts
        } catch {
            debugPrint("NFTUIKitCache -> getGridNFTs error: \(error)")
            return nil
        }
    }
}

// MARK: - Collection

extension NFTUIKitCache {
    func saveCollectionToCache(_ collections: [NFTCollection]) {
        if collections.isEmpty {
            removeCollectionCache()
            return
        }

        let count = collections.reduce(0) { partialResult, nftc in
            partialResult + nftc.count
        }

        do {
            let data = try JSONEncoder().encode(collections)
            try data.write(to: collectionCacheFile)

            DispatchQueue.main.async {
                LocalUserDefaults.shared.nftCount = count
            }
        } catch {
            debugPrint("NFTUIKitCache -> saveCollectionToCache: error: \(error)")
            removeCollectionCache()
        }
    }

    func removeCollectionCache() {
        if FileManager.default.fileExists(atPath: collectionCacheFile.relativePath) {
            do {
                try FileManager.default.removeItem(at: collectionCacheFile)
            } catch {
                debugPrint("NFTUIKitCache -> removeCollectionCache error: \(error)")
            }
        }

        DispatchQueue.main.async {
            LocalUserDefaults.shared.nftCount = 0
        }
    }

    func getCollections() -> [NFTCollection]? {
        if !FileManager.default.fileExists(atPath: collectionCacheFile.relativePath) {
            return nil
        }

        do {
            let data = try Data(contentsOf: collectionCacheFile)
            let collections = try JSONDecoder().decode([NFTCollection].self, from: data)
            return collections
        } catch {
            debugPrint("NFTUIKitCache -> getCollections error: \(error)")
            return nil
        }
    }
}

// MARK: - NFTs

extension NFTUIKitCache {
    func saveNFTsToCache(_ nfts: [NFTResponse], collectionId: String) {
        if nfts.isEmpty {
            removeNFTs(collectionId: collectionId)
            return
        }

        let md5 = collectionId.md5
        let fileURL = nftFolder.appendingPathComponent(md5)

        do {
            let data = try JSONEncoder().encode(nfts)
            try data.write(to: fileURL)
        } catch {
            debugPrint("NFTUIKitCache -> saveNFTsToCache: error: \(error)")
            removeNFTs(collectionId: collectionId)
        }
    }

    func removeNFTs(collectionId: String) {
        let md5 = collectionId.md5
        let fileURL = nftFolder.appendingPathComponent(md5)

        if FileManager.default.fileExists(atPath: fileURL.relativePath) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                debugPrint("NFTUIKitCache -> removeNFTs: error: \(error)")
            }
        }
    }

    func removeAllNFTs() {
        if FileManager.default.fileExists(atPath: nftFolder.relativePath) {
            do {
                try FileManager.default.removeItem(at: nftFolder)
                try FileManager.default.createDirectory(
                    at: nftFolder,
                    withIntermediateDirectories: true
                )
            } catch {
                debugPrint("NFTUIKitCache -> removeAllNFTs error: \(error)")
            }
        }
    }

    func getNFTs(collectionId: String) -> [NFTResponse]? {
        let md5 = collectionId.md5
        let fileURL = nftFolder.appendingPathComponent(md5)

        if !FileManager.default.fileExists(atPath: fileURL.relativePath) {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let nfts = try JSONDecoder().decode([NFTResponse].self, from: data)
            return nfts
        } catch {
            debugPrint("NFTUIKitCache -> getNFTs: \(collectionId) error: \(error)")
            return nil
        }
    }
}

// MARK: - Fav

extension NFTUIKitCache {
    private func loadFavCache() {
        guard WalletManager.shared.selectedChildAccount == nil else {
            favList = []
            return
        }
        if !FileManager.default.fileExists(atPath: favCacheFile.relativePath) {
            return
        }

        do {
            let data = try Data(contentsOf: favCacheFile)
            let nfts = try JSONDecoder().decode([NFTModel].self, from: data)
            favList = nfts
        } catch {
            debugPrint("NFTUIKitCache -> loadFavCache error: \(error)")
        }
    }

    private func saveCurrentFavToCache() {
        do {
            let data = try JSONEncoder().encode(favList)
            try data.write(to: favCacheFile)

            updateAppGroupFav()

            NotificationCenter.default.post(name: .nftFavDidChanged, object: nil)
        } catch {
            debugPrint("NFTUIKitCache -> saveCurrentFavToCache error: \(error)")
        }
    }

    private func updateAppGroupFav() {
        let oldFav = groupUserDefaults()?.url(forKey: FirstFavNFTImageURL)

        if let firstFav = favList.first {
            if oldFav == firstFav.imageURL {
                return
            }

            groupUserDefaults()?.set(firstFav.imageURL, forKey: FirstFavNFTImageURL)
        } else {
            groupUserDefaults()?.set(nil, forKey: FirstFavNFTImageURL)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    func removeFavCache() {
        if !FileManager.default.fileExists(atPath: favCacheFile.relativePath) {
            return
        }

        do {
            try FileManager.default.removeItem(at: favCacheFile)
        } catch {
            debugPrint("NFTUIKitCache -> removeFavCache error: \(error)")
        }

//        // TODO: Test
//        Task {
//            do {
//                let request = NFTUpdateFavRequest(ids: "")
//                let _: Network.EmptyResponse = try await Network.requestWithRawModel(FRWAPI.NFT.updateFav(request))
//            } catch {
//                debugPrint("NFTUIKitCache -> removeFav error: \(error)")
//            }
//        }
    }

    func isFav(id: String) -> Bool {
        if WalletManager.shared.selectedChildAccount != nil {
            return false
        }
        for nft in favList {
            if nft.id == id {
                return true
            }
        }

        return false
    }

    func addFav(nft: NFTModel) {
        if WalletManager.shared.isSelectedChildAccount {
            log.error("child account can not add fav")
            return
        }

        guard var address = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress(),
              let collectionId = nft.response.collectionID
        else {
            return
        }

        if let _ = favList.firstIndex(where: { $0.id == nft.id }) {
            return
        }

        favList.insert(nft, at: 0)
        saveCurrentFavToCache()

        let tokenId = nft.response.id

        let request = NFTAddFavRequest(address: address, contract: collectionId, ids: tokenId)
        Task {
            do {
                let _: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.NFT.addFav(request))
            } catch {
                debugPrint("NFTUIKitCache -> addFav error: \(error)")
            }
        }
    }

    func removeFav(id: String) {
        if let index = favList.firstIndex(where: { $0.id == id }) {
            favList.remove(at: index)
            saveCurrentFavToCache()

            let ids = generateFavUpdateStrings()
            Task {
                do {
                    let request = NFTUpdateFavRequest(ids: ids)
                    let _: Network.EmptyResponse = try await Network
                        .requestWithRawModel(FRWAPI.NFT.updateFav(request))
                } catch {
                    debugPrint("NFTUIKitCache -> removeFav error: \(error)")
                }
            }
        }
    }

    private func generateFavUpdateStrings() -> String {
        var array = [String]()
        for nft in favList {
            if let collectionId = nft.response.collectionID {
                let tokenId = nft.response.id
                array.append("\(collectionId)-\(tokenId)")
            }
        }

        let str = array.joined(separator: ",")
        return str
    }

    func requestFav() {
        guard WalletManager.shared.selectedChildAccount == nil else {
            favList = []
            return
        }
        if favIsRequesting {
            return
        }

        guard let address = WalletManager.shared
            .getWatchAddressOrChildAccountAddressOrPrimaryAddress()
        else {
            return
        }

        favIsRequesting = true

        Task {
            do {
                let request: Network.Response<NFTFavListResponse> = try await Network
                    .requestWithRawModel(FRWAPI.NFT.favList(address))

                DispatchQueue.main.async {
                    self.favIsRequesting = false

                    guard let nfts = request.data?.nfts, request.httpCode == 200 else {
                        // empty
                        debugPrint("NFTUIKitCache -> requestFav is empty")
                        self.favList.removeAll()
                        self.saveCurrentFavToCache()
                        return
                    }
                    let filterNFTs = nfts.filter { $0.postMedia != nil }
                    let models = filterNFTs.map { NFTModel($0, in: nil) }
                    self.favList = models
                    self.saveCurrentFavToCache()
                }
            } catch {
                DispatchQueue.main.async {
                    self.favIsRequesting = false
                    self.favList = []
                    debugPrint("NFTUIKitCache -> requestFav error: \(error)")
                }
            }
        }
    }
}

// MARK: - Modify

extension NFTUIKitCache {
    func transferedNFT(_ nft: NFTResponse) {
        guard let collectionId = nft.collectionID else {
            return
        }

        // check gird cache
        if var gridCache = getGridNFTs() {
            gridCache.removeAll { $0.uniqueId == nft.uniqueId }
            saveGridToCache(gridCache)
        }

        // check list cache
        if var listNFTs = getNFTs(collectionId: collectionId) {
            listNFTs.removeAll { $0.uniqueId == nft.uniqueId }
            saveNFTsToCache(listNFTs, collectionId: collectionId)

            // remove collection if needed
            if var collections = getCollections(),
               let index = collections.firstIndex(where: { $0.collection.id == collectionId })
            {
                if listNFTs.isEmpty {
                    collections.removeAll { $0.collection.id == collectionId }
                } else {
                    var collection = collections[index]
                    collection.count -= 1
                    if var ids = collection.ids {
                        ids.removeAll { $0 == nft.id }
                        collection.ids = ids
                    }

                    collections.remove(at: index)
                    collections.insert(collection, at: index)
                }

                saveCollectionToCache(collections)
            }
        }

        // check fav cache
        if isFav(id: nft.uniqueId) {
            favList.removeAll { $0.id == nft.uniqueId }
            saveCurrentFavToCache()
        }

        NotificationCenter.default.post(name: .nftCacheDidChanged, object: nil)
    }
}
