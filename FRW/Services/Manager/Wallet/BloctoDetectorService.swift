//
//  BloctoDetectorService.swift
//  FRW
//
//  Created by Codex.
//

import Foundation
import Flow

struct BloctoDetectionResult {
  let isBlocto: Bool
  let needRevoke: Bool
  let revokeKeyIndexes: [Int]
}

enum BloctoDetectorService {
  private static func cacheKey(for address: String) -> String {
    "blocto.detector.false.\(address.lowercased())"
  }

  static func detectBloctoKey(address: String) async throws -> BloctoDetectionResult {
    let normalized = address.lowercased()
    if UserDefaults.standard.bool(forKey: cacheKey(for: normalized)) {
      return BloctoDetectionResult(isBlocto: false, needRevoke: false, revokeKeyIndexes: [])
    }

    let account = try await FlowNetwork.getAccountAtLatestBlock(address: normalized)
    let keys = account.keys
    let candidateKeys = keys.filter {
      $0.signAlgo == .ECDSA_SECP256k1 && $0.hashAlgo == .SHA3_256
    }

    let hasWeight999 = candidateKeys.contains { $0.weight == 999 }
    let hasWeight1 = candidateKeys.contains { $0.weight == 1 }
    let isBlocto = hasWeight999 && hasWeight1
    let revokeKeyIndexes = candidateKeys
      .filter { !$0.revoked }
      .map { Int($0.index) }
    let needRevoke = isBlocto && !revokeKeyIndexes.isEmpty

    if !isBlocto {
      UserDefaults.standard.set(true, forKey: cacheKey(for: normalized))
    }

    return BloctoDetectionResult(
      isBlocto: isBlocto,
      needRevoke: needRevoke,
      revokeKeyIndexes: revokeKeyIndexes
    )
  }
}
