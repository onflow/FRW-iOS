//
//  FlowModel+NFT.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Foundation

extension FlowModel {
    struct Path: Codable, Equatable, Hashable {
        let domain: String
        let identifier: String
    }

    struct Serial: Codable {
        let number: String
    }

    struct Thumbnail: Codable, Equatable, Hashable {
        let url: String
    }

    struct Display: Codable, Equatable, Hashable {
        let name: String
        let description: String?
//        let thumbnail: FlowModel.Thumbnail
    }

    struct ExternalUrl: Codable {
        let url: String
    }

    struct Socials: Codable {
        struct Item: Codable {
            let url: String
        }

        let twitter: Socials.Item?
    }

    struct CollectionDisplay: Codable {
        let name: String
        let description: String
        let externalURL: FlowModel.ExternalUrl
        let squareImage: FlowModel.Media
        let bannerImage: FlowModel.Media
    }

    struct CollectionInfo: Codable, Equatable, Hashable {
        let collectionData: CollectionData
    }

    struct CollectionData: Codable, Equatable, Hashable {
        let storagePath: FlowModel.Path?
        let publicPath: FlowModel.Path?
        let privatePath: FlowModel.Path?
//        let serial: FlowModel.Serial?
        let display: FlowModel.Display?
//        let tokenId: String?
//        let externalURL: FlowModel.ExternalUrl?
//        let traits: NFTTrait?
    }
}

struct ChildAccessibleCollectionModel: Codable {
    let id: String
    let idList: [UInt64]
    let display: AccessibleCollectionDisplay?
}

struct AccessibleCollectionDisplay: Codable {
    let name: String
    let squareImage: FlowModel.Media?
}
