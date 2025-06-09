//
//  WalletConnect+SyncMultiAccount.swift
//  FRW
//
//  Created by cat on 6/9/25.
//

import Foundation
import WalletConnectSign

// sync multi-account
extension WalletConnectManager {
    func isMultiAccount(request: WalletConnectSign.Request,
                        with response: WalletConnectSign.Response) -> Bool
    {
        (request.method == FCLWalletConnectMethod.addMultiAccount.rawValue) &&
            (request.topic == response.topic)
    }

    func skipToSyncAction(source: SyncActionStatusView.Source) {
        Router.route(to: RouteMap.RestoreLogin.syncAction(source))
    }
}

// MARK: - handle Request & Reponse

extension WalletConnectManager {
    func handleSyncMultiAccount(_ sessionRequest: WalletConnectSign.Request) {
        Task {
            do {
                let param = try packageAccountsInfo()
                try await Sign.instance.respond(topic: sessionRequest.topic, requestId: sessionRequest.id, response: .response(param))
            } catch {
                log.error("[WC] multi-account \(error.localizedDescription)")
                rejectRequest(request: sessionRequest)
            }
        }
    }

    private func packageAccountsInfo() throws -> AnyCodable {
        // TODO: multi-account
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
