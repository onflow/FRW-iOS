//
//  Error.swift
//  Flow Wallet
//
//  Created by Selina on 8/6/2022.
//

import Foundation

// MARK: - BaseError Protocol

protocol BaseError: Error, CaseIterable, RawRepresentable, Equatable where RawValue == String {
    var baseCode: Int { get }
    var errorCode: Int { get }
    var errorMessage: String { get }
}

extension BaseError {
    var errorCode: Int {
        // Get index from CaseIterable
        guard let index = Self.allCases.firstIndex(of: self) as? Int else {
            return 999 // Default error code for unkn as! Intown cases
        }
        return baseCode + index + 1 // Adding 1 to avoid 0-based index
    }

    var errorLog: String {
        "\(String(describing: Self.self)) - Code: \(errorCode), RawValue:\(rawValue)"
    }

    var errorMessage: String {
        // Convert camelCase to space-separated words
        return rawValue.replacingOccurrences(of: "([A-Z])", with: " $1", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .capitalized
    }
}

// MARK: - LLError

enum LLError: String, BaseError {
    case aesKeyEncryptionFailed
    case aesEncryptionFailed
    case missingUserInfoWhilBackup
    case emptyiCloudBackup
    case alreadyHaveWallet
    case emptyWallet
    case decryptBackupFailed
    case incorrectPhrase
    case emptyEncryptKey
    case restoreLoginFailed
    case accountNotFound
    case fetchUserInfoFailed
    case invalidAddress
    case invalidCadence
    case signFailed
    case decodeFailed
    case cannotFindFlowAccount
    case unknown

    var baseCode: Int { 1000 }
}

// MARK: - WalletError

enum WalletError: String, BaseError {
    case fetchFailed
    case fetchBalanceFailed
    case existingMnemonicMismatch
    case storeAndActiveMnemonicFailed
    case mnemonicMissing
    case emptyPublicKey
    case insufficientBalance
    case securityVerifyFailed
    case collectionIsNil
    case noPrimaryWalletAddress
    case emptyKeyProvider
    case emptyAccountKey
    case invalidMnemonic
    case invaildPublicKey
    case invaildAddress
    case fetchLinkedAccountsFailed
    case emptyAddress
    case emptyScript

    var baseCode: Int { 2000 }
}

// MARK: - BackupError

enum BackupError: String, BaseError {
    case missingUserName
    case missingMnemonic
    case missingUid
    case hexStringToDataFailed
    case decryptMnemonicFailed
    case topVCNotFound
    case fileIsNotExistOnCloud
    case cloudFileData
    case unauthorized
    case invaildPublicKey

    var baseCode: Int { 3000 }
}

// MARK: - GoogleBackupError

enum GoogleBackupError: String, BaseError {
    case missingLoginUser
    case noDriveScope
    case createFileError

    var baseCode: Int { 4000 }
}

// MARK: - iCloudBackupError

enum iCloudBackupError: String, BaseError {
    case initError
    case invalidLoadData
    case checkFileUploadedStatusError
    case openFileError
    case opendFileDataIsNil
    case noDataToSave
    case saveToDataFailed
    case fileIsNotExist

    var baseCode: Int { 5000 }
}

// MARK: - NFTError

enum NFTError: String, BaseError {
    case noCollectionInfo
    case invalidTokenId
    case sendInvalidAddress

    var baseCode: Int { 6000 }
}

// MARK: - StakingError

enum StakingError: String, BaseError {
    case stakingDisabled
    case stakingNeedSetup
    case stakingSetupFailed
    case stakingCreateDelegatorIdFailed
    case unknown

    var baseCode: Int { 7000 }
}

// MARK: - EVMError

enum EVMError: String, BaseError {
    case addressError
    case rpcError
    case createAccount
    case findAddress
    case transactionResult

    var baseCode: Int { 8000 }
}

// MARK: - CadenceError

enum CadenceError: String, BaseError {
    case none
    case empty
    case transactionFailed
    case invaildArgument
    case contractNameIsEmpty
    case tokenAddressEmpty
    case storagePathEmpty

    var baseCode: Int { 9000 }
}

// MARK: - MoveError

enum MoveError: String, BaseError {
    case invalidateIdentifier
    case invalidateFromAddress
    case invalidateToAddress
    case invalidateNftCollectionInfo
    case failedToSubmitTransaction

    var baseCode: Int { 10000 }
}

// MARK: - Errors

enum TokenBalanceProviderError: String, BaseError {
    case collectionNotFound

    var baseCode: Int { 11000 }
}


// MARK: - Account

enum AccountError: String, BaseError {
    case switchAccountFailed

    var baseCode: Int { 12000 }
}
