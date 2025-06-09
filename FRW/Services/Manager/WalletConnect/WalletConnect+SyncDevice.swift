//
//  WalletConnect+SyncDevice.swift
//  FRW
//
//  Created by cat on 2023/12/5.
//

import Flow
import FlowWalletKit
import Foundation
import WalletConnectPairing
import WalletConnectSign

// MARK: - SyncError

enum SyncError: Error {
    case emptyJSON
    case decode
    case userInfo
}

// MARK: - WalletConnectSyncDevice

enum WalletConnectSyncDevice {
    enum SyncResult {
        case success
        case failed(String)
    }

    static let nameDomain = "flow"

    static func createAndPair() async throws -> WalletConnectURI {
        let methods: Set<String> = [
            FCLWalletConnectMethod.accountInfo.rawValue,
            FCLWalletConnectMethod.addDeviceInfo.rawValue,
            FCLWalletConnectMethod.addMultiAccount.rawValue,
        ]
        let namespaces = Sign.FlowWallet.namespaces(methods)
        let uri = try await Sign.instance.connect(requiredNamespaces: namespaces)
        return uri
    }

    static func requestSyncAccount(in session: Session) async throws -> WalletConnectSign.Request? {
        log.info("[sync] send request for account info top:\(session.topic)")

        let methods: String = FCLWalletConnectMethod.addMultiAccount.rawValue
        let blockchain = Sign.FlowWallet.blockchain
        do {
            let request = try Request(
                topic: session.topic,
                method: methods,
                params: emptyParams(),
                chainId: blockchain
            )
            try await Sign.instance.request(params: request)
            return request
        } catch {
            log.error("[sync]-account: request error:\(error.localizedDescription) ")
            throw error
        }
    }

    static func isAccount(
        request: WalletConnectSign.Request,
        with response: WalletConnectSign.Response
    ) -> Bool {
        (request.method == FCLWalletConnectMethod.accountInfo.rawValue) &&
            (request.topic == response.topic)
    }

    static func parseAccount(data: AnyCodable) throws -> SyncInfo.User {
        guard let json = try? data.get(String.self) else {
            throw SyncError.emptyJSON
        }

        let jsonDecoder = JSONDecoder()
        let response = try jsonDecoder.decode(
            SyncInfo.SyncResponse<SyncInfo.User>.self,
            from: Data(json.utf8)
        )
        guard let user = response.data else {
            throw SyncError.userInfo
        }
        return user
    }

    static func packageUserInfo() throws -> AnyCodable {
        let address = WalletManager.shared.address.hex.addHexPrefix()
        guard let account = UserManager.shared.userInfo else { throw LLError.accountNotFound }

        let user = SyncInfo.User(
            userAvatar: account.avatar,
            userName: account.nickname,
            walletAddress: address,
            userId: UserManager.shared.activatedUID ?? ""
        )

        let model = SyncInfo.SyncResponse<SyncInfo.User>(
            method: FCLWalletConnectMethod.accountInfo.rawValue,
            status: "",
            message: "",
            data: user
        )
        let reuslt = try model.asJSONEncodedString()
        return AnyCodable(reuslt)
    }
}

// MARK: Device

extension WalletConnectSyncDevice {
    static func isDevice(
        request: WalletConnectSign.Request,
        with response: WalletConnectSign.Response
    ) -> Bool {
        (request.method == FCLWalletConnectMethod.addDeviceInfo.rawValue) &&
            (request.topic == response.topic)
    }

    static func packageDeviceInfo(userId: String, address: String?) async throws -> AnyCodable {
        if IPManager.shared.info == nil {
            await IPManager.shared.fetch()
        }
        let secureKey = try SecureEnclaveKey.create()
        let key = try secureKey.flowAccountKey()
        let requestParam = RegisterRequest(
            username: "",
            accountKey: key.toCodableModel(),
            deviceInfo: IPManager.shared.toParams()
        )
        let response = SyncInfo.SyncResponse<RegisterRequest>(
            method: FCLWalletConnectMethod.addDeviceInfo.rawValue,
            data: requestParam
        )
        try secureKey.store(id: userId)
        let storeUser = UserManager.StoreUser(publicKey: key.publicKey.description, address: address, userId: userId, keyType: .secureEnclave, account: nil, userInfo: nil)
        LocalUserDefaults.shared.addUser(user: storeUser)
        log.debug("[Sync] Public Key: \(key.publicKey.data.hexString)")
        return AnyCodable(response)
    }
}

// MARK: private fun

extension WalletConnectSyncDevice {
    private static func isFlowSession(_ session: Session) -> Bool {
        !session.namespaces.filter { $0.key == nameDomain }.isEmpty
    }

    private static func emptyParams() -> AnyCodable {
        AnyCodable([""])
    }
}
