//
//  EventTrack+Dev.swift
//  FRW
//
//  Created by cat on 12/9/24.
//

import Foundation

extension EventTrack.Dev {
    static func restoreLogin(userId: String) {
        EventTrack.send(event: EventTrack.Dev.restoreLogin, properties: ["user_id": userId])
    }
}

// Device Backup
extension EventTrack.Dev {
    enum DeviceBackupProgress: String {
        case connect
        case accountInfo
        case addKeyToChain
        case addKeyToBackend
        case login
    }

    static func deviceBackup(progress: DeviceBackupProgress, message: String) {
        EventTrack.send(event: EventTrack.Dev.deviceBackup, properties: [
            .Track.progress: progress.rawValue,
            .Track.message: message,
        ])
    }
}
