//
//  EventTrack+Account.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation

extension EventTrack.Account {
    static func create(
        key: String,
    signAlgo: String,
        hashAlgo: String,
        isSecure: Bool = true,
        isSeed: Bool
     = false) {
         EventTrack
             .send(event: EventTrack.Account.created, properties: [
                "public_key": key,
                "is_secure_enclave": isSecure,
                "is_seed_phrase": isSeed,
                "sign_algo": signAlgo,
                "hash_algo": hashAlgo
             ])
    }
    
    static func createdTimeStart() {
        EventTrack.timeBegin(event: EventTrack.Account.createdTime)
    }
    
    static func createdTimeEnd() {
        EventTrack.timeEnd(event: EventTrack.Account.createdTime)
    }
    
    static func recovered(address: String, machanism: String, methods: [String]) {
        EventTrack
            .send(event: EventTrack.Account.recovered, properties: [
                "address": address,
                "mechanism": machanism,
                "methods": methods
            ])
    }
}
