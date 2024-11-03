//
//  EVMAssetProvider.swift
//  FRW
//
//  Created by cat on 2024/5/21.
//

import Foundation

protocol NFTMask {
    var maskLogo: String { get }
    var maskId: String { get }
    var maskFlowIdentifier: String? { get }
}

protocol CollectionMask {
    var maskAddress: String { get }
    var maskName: String { get }
    var maskContractName: String { get }
    var maskLogo: URL? { get }
    var maskId: String { get }
    var maskCount: Int { get }
    var maskFlowIdentifier: String? { get }
}

// MARK: NFTResponse

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
        return id
    }

    var maskFlowIdentifier: String? {
        flowIdentifier
    }
}

// MARK: NFTCollection

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
        return count
    }

    var maskFlowIdentifier: String? {
        collection.flowIdentifier
    }
}

// MARK: EVMNFT

extension EVMNFT: NFTMask {
    var maskLogo: String {
        return thumbnail
    }

    var maskId: String {
        id
    }

    var maskFlowIdentifier: String? {
        return nil
    }
}

// MARK: EVMCollection

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
