//
//  EventTrackName.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation

// MARK: - EventTrackNameProtocol

protocol EventTrackNameProtocol {
    var name: String { get }
}

// MARK: - EventTrack.General

extension EventTrack {
    enum General: String, EventTrackNameProtocol {
        case rpcError = "script_error"
        case delegationCreated = "delegation_created"
        case rampClicked = "on_ramp_clicked"
        case coaCreation = "coa_creation"
        case securityTool = "security_tool"

        // MARK: Internal

        var name: String {
            rawValue
        }
    }
}

// MARK: - EventTrack.Backup

extension EventTrack {
    enum Backup: String, EventTrackNameProtocol {
        case multiCreated = "multi_backup_created"
        case multiCreationFailed = "multi_backup_creation_failed"

        // MARK: Internal

        var name: String {
            rawValue
        }
    }
}

// MARK: - EventTrack.Transaction

extension EventTrack {
    enum Transaction: String, EventTrackNameProtocol {
        case flowSigned = "cadence_transaction_signed"
        case evmSigned = "evm_transaction_signed"
        case FTTransfer = "ft_transfer"
        case NFTTransfer = "nft_transfer"
        case result = "transaction_result"

        // MARK: Internal

        var name: String {
            rawValue
        }
    }
}

// MARK: - EventTrack.Account

extension EventTrack {
    enum Account: String, EventTrackNameProtocol {
        case created = "account_created"
        case createdTime = "account_creation_time"
        case recovered = "account_recovered"

        // MARK: Internal

        var name: String {
            rawValue
        }
    }
}

extension EventTrack {
    enum Dev: String, EventTrackNameProtocol {
        case restoreLogin = "restore_login"
        case deviceBackup = "device_backup"

        var name: String {
            rawValue
        }
    }
}
