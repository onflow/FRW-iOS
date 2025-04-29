//
//  UserAddressV2Response.swift
//  FRW
//
//  Created by Hao Fu on 16/4/2025.
//

import Foundation

struct UserAddressV2Response: Codable {
    let txId: String
    
    enum CodingKeys: String, CodingKey {
        case txId = "txid"
    }
}
