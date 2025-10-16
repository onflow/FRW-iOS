//
//  PayerStatus.swift
//  FRW
//
//  Created by cat on 10/15/25.
//

import Foundation

// MARK: - PayerStatusData

struct PayerStatusData: Codable {
  let statusVersion: Int?
  let surge: PayerStatusData.Surge?
  let feePayer: PayerStatusData.Payer?
  let bridgePayer: PayerStatusData.Payer?
  let updatedAt: TimeInterval?
  
  var shouldUserPay: Bool {
    guard let active = surge?.active,
            let available = feePayer?.available else {
        return true
      }
      return active || !available
  }

}

// MARK: Codable

extension PayerStatusData {
  struct Surge: Codable {
    let active: Bool?
    let multiplier: String?
    let sampledAt: Int64?
    let expiresAt: Int64?
    let ttlSeconds: Int?
    let maxFee: Double?
    
    fileprivate var isSurged: Bool {
      active ?? true
    }
  }

  struct Payer: Codable {
    let available: Bool?
    let address: String?
    let keyIndex: Int?
    
    fileprivate var isOk: Bool {
      available ?? false
    }
  }
}
