//
//  EventTrack+Account.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation
import FlowWalletKit

extension EventTrack.Account {
    static func create(
        key: String,
        signAlgo: String,
        hashAlgo: String,
        isSecure: Bool = true,
        isSeed: Bool
            = false
    ) {
        EventTrack
            .send(event: EventTrack.Account.created, properties: [
                "public_key": key,
                "is_secure_enclave": isSecure,
                "is_seed_phrase": isSeed,
                "sign_algo": signAlgo,
                "hash_algo": hashAlgo,
            ])
    }

    static func createdTimeStart() {
        EventTrack.timeBegin(event: EventTrack.Account.createdTime)
    }

    static func createdTimeEnd() {
        EventTrack.timeEnd(event: EventTrack.Account.createdTime)
    }

  static func recovered(address: String, mechanism: EventTrack.Account.Mechanism, methods: [String]) {
        EventTrack
            .send(event: EventTrack.Account.recovered, properties: [
                "address": address,
                "mechanism": mechanism.rawValue,
                "methods": methods,
            ])
    }
}

extension EventTrack.Account {
  enum Mechanism: String {
    case multiBackup = "multi-backup"
    case seedPhrase = "seed-phrase"
    case privatekey = "private_key"
    case keyStore = "KeyStore"
    case deviceBackup = "device_backup"
  }
}

extension KeyType {
  func toEventMechanism() -> EventTrack.Account.Mechanism? {
    switch self {
    case .secureEnclave:
      return nil
    case .seedPhrase:
      return .seedPhrase
    case .privateKey:
      return .privatekey
    case .keyStore:
      return .keyStore
    }
  }
}
