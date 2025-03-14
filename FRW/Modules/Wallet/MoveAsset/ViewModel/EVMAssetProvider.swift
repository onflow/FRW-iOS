//
//  EVMAssetProvider.swift
//  FRW
//
//  Created by cat on 2024/5/21.
//

import Foundation

// MARK: - NFTMask

protocol NFTMask {
    var maskLogo: String { get }
    var maskId: String { get }
    var maskFlowIdentifier: String? { get }
    var maskName: String? { get }
}

// MARK: - CollectionMask

protocol CollectionMask {
    var maskAddress: String { get }
    var maskName: String { get }
    var maskContractName: String { get }
    var maskLogo: URL? { get }
    var maskId: String { get }
    var maskCount: Int { get }
    var maskFlowIdentifier: String? { get }
}

// MARK: - NFTResponse + NFTMask

extension NFTResponse: NFTMask {
    var maskLogo: String {
        if let media = postMedia {
            if let imgUrl = media.image, let url = URL(string: imgUrl), media.isSvg == true {
                if let result = url.absoluteString.convertedSVGURL()?.absoluteString {
                    return result
                }
            }
        }
        return cover() ?? thumbnail ?? ""
    }

    var maskId: String {
        id
    }

    var maskFlowIdentifier: String? {
        flowIdentifier
    }

    var maskName: String? {
        name
    }
}

// MARK: - NFTCollection + CollectionMask

extension NFTCollection: CollectionMask {
    var maskName: String {
        collection.name ?? ""
    }

    var maskAddress: String {
        collection.address ?? ""
    }

    var maskContractName: String {
        collection.contractName ?? ""
    }

    var maskId: String {
        collection.id
    }

    var maskLogo: URL? {
        collection.logoURL
    }

    var maskCount: Int {
        count
    }

    var maskFlowIdentifier: String? {
        collection.flowIdentifier
    }
}

extension NFTModel: NFTMask {
    var maskLogo: String {
        logoUrl.absoluteString
    }

    var maskId: String {
        response.id
    }

    var maskFlowIdentifier: String? {
        response.flowIdentifier
    }

    var maskName: String? {
        title
    }
}

// MARK: - EVMNFT + NFTMask

extension EVMNFT: NFTMask {
    var maskLogo: String {
        thumbnail
    }

    var maskId: String {
        id
    }

    var maskFlowIdentifier: String? {
        nil
    }

    var maskName: String? {
        name
    }
}

// MARK: - EVMCollection + CollectionMask

extension EVMCollection: CollectionMask {
    var maskAddress: String {
        guard let addr = flowIdentifier?.split(separator: ".")[1] else {
            return ""
        }
        return String(addr).addHexPrefix()
    }

    var maskName: String {
        name
    }

    var maskContractName: String {
        guard let name = flowIdentifier?.split(separator: ".")[2] else {
            return ""
        }
        return String(name)
    }

    var maskLogo: URL? {
        URL(string: logoURI)
    }

    var maskId: String {
        ""
    }

    var maskCount: Int {
        nfts.count
    }

    var maskFlowIdentifier: String? {
        flowIdentifier
    }
}
