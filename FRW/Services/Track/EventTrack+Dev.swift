//
//  EventTrack+Dev.swift
//  FRW
//
//  Created by cat on 12/9/24.
//

import Foundation

extension EventTrack.Dev {
    static func restoreLogin(userId: String) {
        EventTrack.send(event: EventTrack.Dev.develop,
                        properties: [
                            "user_id": userId,
                            .Track.module: EventTrack.Dev.Module.restoreLogin,
                        ])
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
        EventTrack.send(event: EventTrack.Dev.develop, properties: [
            .Track.module: EventTrack.Dev.Module.deviceBackup,
            .Track.progress: progress.rawValue,
            .Track.message: message,
        ])
    }
}

// All Cadence
extension EventTrack.Dev {
    static func cadence(_ error: Error, message: String) {
        EventTrack.send(event: EventTrack.Dev.develop, properties: [
            .Track.module: EventTrack.Dev.Module.cadence,
            .Track.error: error.localizedDescription,
            .Track.message: message,
        ])
    }
}
