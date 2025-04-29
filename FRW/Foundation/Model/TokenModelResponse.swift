//
//  TokenModelResponse.swift
//  FRW
//
//  Created by cat on 4/28/25.
//

import Foundation

struct TokenModelResponse: Codable {
    var result: [TokenModel]?
    var storage: TokenStorage?
}

struct TokenStorage: Codable {
    var storageUsedInMB: String?
    var storageAvailableInMB: String?
    var storageCapacityInMB: String?
    var lockedFLOWforStorage: String?
    var availableBalanceToUse: String?
}
