//
//  EventTrackName.swift
//  FRW
//
//  Created by cat on 10/22/24.
//

import Foundation

protocol EventTrackNameProtocol {
    var name: String { get }
}

//MARK: General
extension EventTrack {
    enum General: String, EventTrackNameProtocol {
        case rpcError = "script_error"
        case delegationCreated = "delegation_created"
        case rampClicked = "on_ramp_clicked"
        case securityTool = "security_tool"
        
        var name: String {
            return self.rawValue
        }
    }

}

//MARK: Backup
extension EventTrack {
    enum Backup: String, EventTrackNameProtocol {
        case multiCreated = "multi_backup_created"
        case multiCreationFailed = "multi_backup_creation_failed"
        
        var name: String {
            return self.rawValue
        }
    }
}

//MARK: Transaction
extension EventTrack {
    enum Transaction: String, EventTrackNameProtocol {
        
        case flowSigned = "cadence_transaction_signed"
        case evmSigned = "evm_transaction_signed"
        case FTTransfer = "ft_transfer"
        case NFTTransfer = "nft_transfer"
        
        var name: String {
            self.rawValue
        }
    }
}

//MARK: Account
extension EventTrack {
    enum Account: String, EventTrackNameProtocol {
        
        case created = "account_created"
        case createdTime = "account_creation_time"
        case recovered = "account_recovered"
        
        var name: String {
            self.rawValue
        }
    }
}
