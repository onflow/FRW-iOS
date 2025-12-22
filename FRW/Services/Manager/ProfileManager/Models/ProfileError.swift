//
//  ProfileError.swift
//  FRW
//
//  Created by cat on 9/24/25.
//  Moved to Models folder on 11/29/25.
//

import Foundation
import KeychainAccess

// MARK: - ProfileError

enum ProfileError: Error, LocalizedError {
    case keychainError(KeychainAccess.Status)
    case profileNotFound(String)
    case invalidData
    case deviceNotSupported
    case migrationFailed(Error)
    case encodingError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .profileNotFound(let userId):
            return "Profile not found for user: \(userId)"
        case .invalidData:
            return "Invalid profile data"
        case .deviceNotSupported:
            return "Device not supported"
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        case .encodingError:
            return "Failed to encode profile data"
        case .decodingError:
            return "Failed to decode profile data"
        }
    }
}
