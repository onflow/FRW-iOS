//
//  FlowModel+NFT.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Foundation

extension FlowModel {
    struct Path: Codable {
        let domain: String
        let identifier: String
    }
    
    struct Serial:Codable {
        let number: String
    }
    
    struct Thumbnail: Codable {
        let url: String
    }
    
    struct Display: Codable {
        let name: String
        let description: String
        let thumbnail: FlowModel.Thumbnail
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
    
    struct CollectionData: Codable {
        let storagePath: FlowModel.Path
        let publicPath: FlowModel.Path
        let serial: FlowModel.Serial
        let display: FlowModel.Display
        let tokenId: String
        let externalURL: FlowModel.ExternalUrl?
        let traits: NFTTrait
    }
}