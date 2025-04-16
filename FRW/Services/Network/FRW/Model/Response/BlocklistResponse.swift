//
//  BlocklistResponse.swift
//  FRW
//
//  Created by cat on 4/8/25.
//

import Foundation

struct BlocklistResponse: Codable {
    let flow: [String]
    let evm: [String]

    static var empty: BlocklistResponse {
        .init(flow: [], evm: [])
    }
}
