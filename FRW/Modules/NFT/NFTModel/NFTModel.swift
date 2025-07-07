//
//  NFTModel.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/18.
//

import Flow
import Foundation
import SwiftUI

let placeholder: String = AppPlaceholder.image
// TODO: which filter?
let filterMetadata = ["uri", "img", "description"]

// MARK: - NFTCollection

struct NFTCollection: Codable {
    let collection: NFTCollectionInfo
    var count: Int
    var ids: [String]?

    var evmNFTs: [NFTModel]?

    static func mock() -> NFTCollection {
        NFTCollection(collection: NFTCollectionInfo.mock(), count: 13)
    }
}

// MARK: - EVMNFTCollectionResponse

struct EVMNFTCollectionResponse: Codable {
    let tokens: [NFTCollectionInfo]?
    let chainId: Int?
    let network: String?
}

// MARK: - NFTCollectionInfo

struct NFTCollectionInfo: Codable, Hashable, Mockable {
    let id: String
    let name: String?
    let contractName: String?
    let address: String?

    let logo: String?
    let banner: String?
    let officialWebsite: String?
    let description: String?

    let path: ContractPath?

    let evmAddress: String?
//    var socials: NFTCollectionInfo.Social?
    let flowIdentifier: String?
    var externalURL: String? = nil
    var nftTypeId: String? = nil
    var contractType: String? = nil

    var logoURL: URL {
        if let logoString = logo {
            if logoString.hasSuffix("svg") {
                return logoString.convertedSVGURL() ?? URL(string: placeholder)!
            }
            return URL(string: logoString) ?? URL(string: placeholder)!
        }

        return URL(string: placeholder)!
    }

    var bannerURL: URL {
        if let bannerString = banner {
            return URL(string: bannerString) ?? URL(string: placeholder)!
        }

        return URL(string: placeholder)!
    }

    static func mock() -> NFTCollectionInfo {
        NFTCollectionInfo(
            id: randomString(),
            name: randomString(),
            contractName: randomString(),
            address: randomString(),
            logo: randomString(),
            banner: randomString(),
            officialWebsite: randomString(),
            description: randomString(),
            path: ContractPath.mock(),
            evmAddress: nil,
            flowIdentifier: nil
        )
    }
}

extension NFTCollectionInfo {
    struct Social: Codable, Hashable {
        let twitter: SocialItem?
    }

    struct SocialItem: Codable, Hashable {
        let url: String?
    }
}

// MARK: - ContractPath

struct ContractPath: Codable, Hashable, Mockable {
    let storagePath: String
    let publicPath: String
    let privatePath: String?
    let publicCollectionName: String?
    let publicType: String?
    let privateType: String?

    static func mock() -> ContractPath {
        ContractPath(
            storagePath: randomString(),
            publicPath: randomString(),
            privatePath: "",
            publicCollectionName: randomString(),
            publicType: randomString(),
            privateType: randomString()
        )
    }

    func storagePathId() -> String {
        let list = storagePath.components(separatedBy: "/")
        if !list.isEmpty {
            return list.last ?? storagePath
        }
        return storagePath
    }
}

// MARK: - NFTModel

struct NFTModel: Codable, Hashable, Identifiable {
    // MARK: Lifecycle

    init(
        _ response: NFTResponse,
        in collection: NFTCollectionInfo?,
        from _: FlowModel.CollectionInfo? = nil
    ) {
        if let imgUrl = response.postMedia?.image, let url = URL(string: imgUrl) {
            if response.postMedia?.isSvg == true {
                image = URL(string: imgUrl) ?? URL(string: placeholder)!
                isSVG = true
            } else if let svgStr = imgUrl.parseBase64ToSVG() {
                imageSVGStr = svgStr.decodeBase64WithFixed()
                isSVG = true
                image = URL(string: placeholder)!
            } else {
                if imgUrl.hasPrefix("https://lilico.infura-ipfs.io/ipfs/") {
                    let newImgURL = imgUrl
                        .replace(
                            by: [
                                "https://lilico.infura-ipfs.io/ipfs/": "https://lilico.app/api/ipfs/",
                            ]
                        )
                    image = URL(string: newImgURL)!
                } else {
                    image = url
                }

                isSVG = false
            }
        } else {
            image = URL(string: placeholder)!
        }

        if let videoUrl = response.postMedia?.video {
            video = URL(string: videoUrl)
        }

        subtitle = response.postMedia?.description ?? ""
        title = response.postMedia?.title ?? response.collectionName ?? ""
        self.collection = collection
        self.response = response
    }

    // MARK: Internal

    let image: URL
    var video: URL?
    let title: String
    let subtitle: String
    var isSVG: Bool = false
    var response: NFTResponse
    var collection: NFTCollectionInfo?

    var imageSVGStr: String? = nil

    var id: String {
        response.uniqueId
    }

    var imageURL: URL {
        if isSVG {
            return image.absoluteString.convertedSVGURL() ?? URL(string: placeholder)!
        } else {
            return image
        }
    }

    var isNBA: Bool {
        collection?.contractName?.trim() == "TopShot"
    }

    var declare: String {
        if let dec = response.postMedia?.description {
            return dec
        }
        return response.description ?? ""
    }

    var logoUrl: URL {
        if let logoString = collection?.logo {
            if logoString.hasSuffix("svg") {
                return logoString.convertedSVGURL() ?? URL(string: placeholder)!
            }
            return URL(string: logoString) ?? URL(string: placeholder)!
        }
        if let logoString = response.collectionSquareImage {
            return URL(string: logoString) ?? URL(string: placeholder)!
        }
        return URL(string: placeholder)!
    }

    var collectionName: String {
        if let name = collection?.name {
            return name
        }
        if let name = response.collectionContractName {
            return name
        }
        return ""
    }

    var tags: [NFTTrait] {
        guard let traits = response.traits else {
            return []
        }

        return traits.filter { trait in
            !filterMetadata.contains(trait.name?.lowercased() ?? "") && !(trait.value ?? "")
                .isEmpty && !(trait.value ?? "").hasPrefix("https://")
        }
    }

    var isDomain: Bool {
        if response.collectionContractName != "Domains" {
            return false
        }

        let name = response.name ?? ""
        let url = response.externalURL ?? ""

        return name.hasSuffix(".meow") || url.hasSuffix(".meow")
    }

    var publicIdentifier: String? {
        guard let path = collection?.path?.privatePath,
              let identifier = path.split(separator: "/").last
        else {
            return nil
        }
        return String(identifier)
    }

    var ERCType: FlowProvider.ABIType {
        guard let value = response.contractType?.lowercased() else {
            return .erc721
        }
        return FlowProvider.ABIType(rawValue: value) ?? .erc721
    }
}

// MARK: - CollectionItem

class CollectionItem: Identifiable, ObservableObject {
    // MARK: Internal

    var address: String = ""
    var id = UUID()
    var name: String = ""
    var collectionId: String = ""
    var count: Int = 0
    var collection: NFTCollectionInfo?
    @Published
    var nfts: [NFTModel] = []
    var loadCallback: ((Bool) -> Void)?
    var loadCallback2: ((Bool) -> Void)?

    var isEnd: Bool = false
    var isRequesting: Bool = false

    var showName: String {
        collection?.name ?? ""
    }

    var iconURL: URL {
        if let logoString = collection?.logo {
            if logoString.hasSuffix("svg") {
                return logoString.convertedSVGURL() ?? URL(string: placeholder)!
            }

            return URL(string: logoString) ?? URL(string: placeholder)!
        }

        return URL(string: placeholder)!
    }

    static func mock() -> CollectionItem {
        let item = CollectionItem()
        item.isEnd = true
        item.nfts = [0, 1, 2, 3].map { _ in
            NFTModel(
                NFTResponse(
                    id: "",
                    name: "",
                    description: "",
                    thumbnail: "",
                    externalURL: "",
                    contractAddress: "",
                    evmAddress: "",
                    address: "",
                    collectionID: "",
                    collectionName: "",
                    collectionDescription: "",
                    collectionSquareImage: "",
                    collectionExternalURL: "",
                    collectionContractName: "",
                    collectionBannerImage: "",
                    traits: [],
                    postMedia: NFTPostMedia(title: "", description: "", video: "", isSvg: false)
                ),
                in: nil
            )
        }
        return item
    }

    func loadFromCache() {
        if let cachedNFTs = NFTUIKitCache.cache.getNFTs(collectionId: collectionId) {
            let models = cachedNFTs.map { NFTModel($0, in: self.collection) }
            nfts = models
        }
    }

    func load(address _: String? = nil) {
        if isRequesting || isEnd {
            return
        }

        isRequesting = true

        let limit = 24
        Task {
            do {
                let response = try await requestCollectionListDetail(
                    offset: nfts.count,
                    limit: limit
                )
                await MainActor.run {
                    self.isRequesting = false

                    guard let list = response.nfts, !list.isEmpty else {
                        self.isEnd = true
                        self.loadCallback?(true)
                        self.loadCallback2?(true)
                        return
                    }

                    let nftModels = list.map { NFTModel($0, in: self.collection) }
                    self.appendNFTsNoDuplicated(nftModels)

                    if list.count != limit {
                        self.isEnd = true
                    }

                    self.saveNFTsToCache()

                    self.loadCallback?(true)
                    self.loadCallback2?(true)
                }
            } catch {
                log.error("[NFT] load NFTs of \(name): \(error)")
                await MainActor.run {
                    self.isRequesting = false
                    self.loadCallback?(false)
                    self.loadCallback2?(false)
                }
            }
        }
    }

    // MARK: Private

    private func appendNFTsNoDuplicated(_ newNFTs: [NFTModel]) {
        for nft in newNFTs {
            let exist = nfts.first { $0.id == nft.id }

            if exist == nil {
                nfts.append(nft)
            }
        }
    }

    private func requestCollectionListDetail(
        offset: Int,
        limit: Int = 24,
        fromAddress: String? = nil
    ) async throws -> NFTListResponse {
        guard let addr = fromAddress ?? WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress(),
              let address = FWAddressDector.create(address: addr)
        else {
            throw LLError.invalidAddress
        }
        let request = NFTCollectionDetailListRequest(
            address: addr,
            collectionIdentifier: collection?.id ?? "",
            offset: String(offset),
            limit: limit
        )
        let from: VMType = address.type
        let response: NFTListResponse = try await Network.request(FRWAPI.NFT.collectionDetailList(
            request,
            from
        ))
        return response
    }

    private func saveNFTsToCache() {
        let models = nfts.map { $0.response }
        NFTUIKitCache.cache.saveNFTsToCache(models, collectionId: collectionId)
    }
}

extension String {
    func parseBase64ToSVG() -> String? {
        if contains("data:image/svg+xml;base64,") {
            if let baseStr = components(separatedBy: "base64,").last {
                return baseStr
            }
        }
        return nil
    }

    func decodeBase64WithFixed() -> String? {
        let cleanedBase64String = trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^A-Za-z0-9+/=]", with: "", options: .regularExpression)

        let requiredPadding = cleanedBase64String.count % 4
        let paddingLength = (4 - requiredPadding) % 4
        let paddedBase64String = cleanedBase64String + String(repeating: "=", count: paddingLength)

        if let data = Data(base64Encoded: paddedBase64String) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}
