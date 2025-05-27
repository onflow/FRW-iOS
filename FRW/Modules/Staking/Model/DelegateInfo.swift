//
//  DelegateInfo.swift
//  FRW
//
//  Created by cat on 5/27/25.
//

import Foundation

struct DelegateInfo: Codable {
    // MARK: Internal

    let id: String
    let delegatorID: UInt32
    let nodeID: String
    let tokensCommitted: Double
    let tokensStaked: Double
    let tokensUnstaking: Double
    let tokensRewarded: Double
    let tokensUnstaked: Double
    let tokensRequestedToUnstake: Double
}
