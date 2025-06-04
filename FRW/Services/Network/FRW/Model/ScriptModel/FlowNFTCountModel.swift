//
//  FlowNFTCountModel.swift
//  FRW
//
//  Created by cat on 6/4/25.
//

import Foundation

struct FlowNFTCountModel: Codable {
    let flowBalance: Double
    let nftCounts: UInt

    static var empty = FlowNFTCountModel(flowBalance: 0, nftCounts: 0)
}
