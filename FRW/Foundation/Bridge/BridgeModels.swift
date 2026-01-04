//
//  BridgeModels.swift
//  FRW
//
//  Auto-generated from TypeScript bridge types
//  Do not edit manually
//

import Foundation

enum RNBridge {
    enum AccountType: String, Codable {
        case main = "main"
        case child = "child"
        case evm = "evm"
        case eoa = "eoa"
    }

    enum ScreenType: String, Codable {
        case sendAsset = "send-asset"
        case tokenDetail = "token-detail"
        case onboarding = "onboarding"
        case receive = "receive"
    }

    enum AccountTypeType: String, Codable {
        case full = "full"
        case hardware = "hardware"
        case null = "null"
    }

    struct EmojiInfo: Codable {
        let emoji: String
        let name: String
        let color: String
    }

    struct Contact: Codable {
        let id: String
        let name: String
        let address: String
        let avatar: String?
        let username: String?
        let contactName: String?
    }

    struct AddressBookContact: Codable {
        let id: String
        let name: String
        let address: String
        let avatar: String?
        let username: String?
        let contactName: String?
    }

    struct WalletAccount: Codable {
        let id: String
        let name: String
        let address: String
        let emojiInfo: EmojiInfo?
        let parentEmoji: EmojiInfo?
        let parentAddress: String?
        let avatar: String?
        let isActive: Bool
        let type: AccountType?
        let balance: String?
        let nfts: String?
    }

    struct RecentContactsResponse: Codable {
        let contacts: [Contact]
    }

    struct WalletAccountsResponse: Codable {
        let accounts: [WalletAccount]
    }

    struct WalletProfile: Codable {
        let name: String
        let avatar: String?
        let uid: String
        let accounts: [WalletAccount]
    }

    struct WalletProfilesResponse: Codable {
        let profiles: [WalletProfile]
    }

    struct AddressBookResponse: Codable {
        let contacts: [AddressBookContact]
    }

    struct SendToConfig: Codable {
        let selectedToken: TokenModel?
        let fromAccount: WalletAccount?
        let selectedNFTs: [NFTModel]?
        let targetAddress: String?
    }

    struct InitialProps: Codable {
        let screen: ScreenType
        let sendToConfig: String?
    }

    struct EnvironmentVariables: Codable {
        let NODE_API_URL: String
        let GO_API_URL: String
        let INSTABUG_TOKEN: String
    }

    struct Currency: Codable {
        let name: String
        let symbol: String
        let rate: String
    }

    struct SaveMnemonicResponse: Codable {
        let success: Bool
        let error: String
    }

    struct CreateAccountResponse: Codable {
        let success: Bool
        let address: String
        let username: String
        let accountType: AccountTypeType
        let txId: String
        let error: String
    }

    struct CreateEOAAccountResponse: Codable {
        let success: Bool
        let address: String
        let username: String
        let mnemonic: String
        let phrase: String
        let accountType: AccountTypeType
        let error: String
    }

    struct AccountKey: Codable {
        let publicKey: String
        let hashAlgoStr: String
        let signAlgoStr: String
        let weight: Int
        let hashAlgo: Int
        let signAlgo: Int
    }

    struct SeedPhraseGenerationResponse: Codable {
        let mnemonic: String
        let accountKey: AccountKey
        let drivepath: String
        let evmAddress: String?
    }

    struct SPResponse: Codable {
        let mnemonic: String
        let accountKey: AccountKey
        let drivepath: String
        let evmAddress: String?
    }

    struct DeviceInfo: Codable {
        let device_id: String?
        let name: String?
        let type: String?
        let user_agent: String?
        let ip: String?
        let city: String?
        let country: String?
        let countryCode: String?
        let continent: String?
        let continentCode: String?
        let regionName: String?
        let district: String?
        let zip: String?
        let lat: Int?
        let lon: Int?
        let isp: String?
        let org: String?
        let currency: String?
    }

    enum InitialRoute: String, Codable {
        case get_started = "GetStarted"
        case profile_type_selection = "ProfileTypeSelection"
        case import_profile = "ImportProfile"
        case select_tokens = "SelectTokens"
        case send_to = "SendTo"
        case send_tokens = "SendTokens"
        case home = "Home"
    }

    enum NativeScreenName: String, Codable {
        case multi_backup = "multiBackup"
        case device_backup = "deviceBackup"
        case seed_phrase_backup = "seedPhraseBackup"
        case backup_options = "backupOptions"
        case wallet_restore = "walletRestore"
        case recovery_phrase_restore = "recoveryPhraseRestore"
        case key_store_restore = "keyStoreRestore"
        case private_key_restore = "privateKeyRestore"
        case google_drive_restore = "googleDriveRestore"
        case icloud_restore = "icloudRestore"
        case multi_restore = "multiRestore"
    }

    enum ScreenName: String, Codable {
        case get_started = "GetStarted"
        case profile_type_selection = "ProfileTypeSelection"
        case recovery_phrase = "RecoveryPhrase"
        case confirm_recovery_phrase = "ConfirmRecoveryPhrase"
        case secure_enclave = "SecureEnclave"
        case import_profile = "ImportProfile"
        case import_other_methods = "ImportOtherMethods"
        case confirm_import_profile = "ConfirmImportProfile"
        case notification_preferences = "NotificationPreferences"
        case select_tokens = "SelectTokens"
        case send_to = "SendTo"
        case send_tokens = "SendTokens"
        case send_summary = "SendSummary"
        case nft_list = "NFTList"
        case nft_detail = "NFTDetail"
    }

    struct NFTModel: Codable {
        let id: String?
        let name: String?
        let description: String?
        let thumbnail: String?
        let externalURL: String?
        let collectionName: String?
        let collectionContractName: String?
        let contractAddress: String?
        let evmAddress: String?
        let address: String?
        let contractName: String?
        let collectionDescription: String?
        let collectionSquareImage: String?
        let collectionBannerImage: String?
        let collectionExternalURL: String?
        let flowIdentifier: String?
        let postMedia: NFTPostMedia?
        let contractType: String?
        let amount: String?
        let type: WalletType
    }

    struct NFTPostMedia: Codable {
        let image: String?
        let isSvg: Bool?
        let description: String?
        let title: String?
    }

    struct FlowPath: Codable {
        let domain: String?
        let identifier: String?
    }

    struct TokenModel: Codable {
        let type: WalletType
        let name: String
        let symbol: String?
        let description: String?
        let balance: String?
        let contractAddress: String?
        let contractName: String?
        let storagePath: FlowPath?
        let receiverPath: FlowPath?
        let balancePath: FlowPath?
        let identifier: String?
        let isVerified: Bool?
        let logoURI: String?
        let priceInUSD: String?
        let balanceInUSD: String?
        let priceInFLOW: String?
        let balanceInFLOW: String?
        let currency: String?
        let priceInCurrency: String?
        let balanceInCurrency: String?
        let displayBalance: String?
        let availableBalanceToUse: String?
        let change: String?
        let decimal: Int?
        let evmAddress: String?
        let website: String?
    }

    enum WalletType: String, Codable {
        case flow = "flow"
        case evm = "evm"
    }

}
