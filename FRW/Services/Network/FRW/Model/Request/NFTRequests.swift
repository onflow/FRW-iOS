//
//  NFTRequests.swift
//  Flow Wallet
//
//  Created by Selina on 9/8/2022.
//

import Foundation

// MARK: - NFTGridDetailListRequest

struct NFTGridDetailListRequest: Codable {
    var address: String = "0x050aa60ac445a061"
    var offset: Int = 0
    var limit: Int = 24
}

// MARK: - NFTCollectionDetailListRequest

struct NFTCollectionDetailListRequest: Codable {
    var address: String = "0x050aa60ac445a061"
    var collectionIdentifier: String
    var offset: String = "0"
    var limit: Int = 24
}

// MARK: - NFTAddFavRequest

struct NFTAddFavRequest: Codable {
    var address: String = "0x050aa60ac445a061"
    var contract: String
    var ids: String
}

// MARK: - NFTUpdateFavRequest

struct NFTUpdateFavRequest: Codable {
    var ids: String
}
