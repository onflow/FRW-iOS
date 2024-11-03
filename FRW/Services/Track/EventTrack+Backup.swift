//
//  EventTrack+Backup.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation

extension EventTrack.Backup {
    static func multiCreated(source: String) {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }
        EventTrack
            .send(event: EventTrack.Backup.multiCreated, properties: [
                "address": address,
                "providers": source,
            ])
    }
    
    static func multiCreatedFailed(source: String) {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            return
        }
        EventTrack
            .send(event: EventTrack.Backup.multiCreationFailed, properties: [
                "address": address,
                "providers": source,
            ])
    }
}
