//
//  ThingsNeedKnowViewModel.swift
//  FRW
//
//  Created by cat on 2024/9/23.
//

import Flow
import FlowWalletKit
import Foundation
import KeychainAccess
import UIKit
import WalletCore

class ThingsNeedKnowViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        keyProvider = try? SeedPhraseKey.createBackup()
    }

    // MARK: Internal

    func onCreate() {
        guard let keyProvider = keyProvider else {
            HUD.error(title: "init keyProvider failed.")
            return
        }
        guard let publicKey = keyProvider.publicKey(signAlgo: signAlgo)?.hexString else {
            HUD.error(title: "fetch public key failed.")
            return
        }
        HUD.loading()
        Task {
            do {
                let addStatus = try await addKeyToFlow(publicKey: publicKey)
                if !addStatus {
                    HUD.error(title: "add key failed.")
                    HUD.dismissLoading()
                    return
                }
                try await addKeyToService(publicKey: publicKey)
                try addKeyToLocal()
                await MainActor.run {
                    HUD.dismissLoading()
                    Router.route(to: RouteMap.Backup.showRecoveryPhraseBackup(keyProvider.hdWallet.mnemonic))
                }
            } catch {
                HUD.dismissLoading()
                HUD.error(title: "\(error.localizedDescription)")
            }
        }
    }

    // MARK: Private

    private var keyProvider: SeedPhraseKey?
    private var signAlgo: Flow.SignatureAlgorithm = .ECDSA_SECP256k1

    private func addKeyToFlow(publicKey: String) async throws -> Bool {
        let address = WalletManager.shared.address

        let flowKey = flowKey(with: publicKey)
        let flowId = try await FlowNetwork.addKeyToAccount(
            address: address,
            accountKey: flowKey,
            signers: WalletManager.shared.defaultSigners
        )
        guard let data = try? JSONEncoder().encode(publicKey) else {
            return false
        }
        let holder = TransactionManager.TransactionHolder(id: flowId, type: .common, data: data)
        TransactionManager.shared.newTransaction(holder: holder)
        let result = try await flowId.onceSealed()
        if result.isFailed {
            return false
        }
        return true
    }

    private func addKeyToService(publicKey: String) async throws {
        let type = BackupType.fullWeightSeedPhrase
        let backupName = type.title
        let flowKey = flowKey(with: publicKey)
        let deviceInfo = SyncInfo.DeviceInfo(
            accountKey: flowKey.toCodableModel(),
            deviceInfo: IPManager.shared.toParams(),
            backupInfo: BackupInfoModel(createTime: nil, name: backupName, type: type.rawValue)
        )

        do {
            let response: Network.EmptyResponse = try await Network
                .requestWithRawModel(FRWAPI.User.syncDevice(deviceInfo))
            if response.httpCode != 200 {
                log.info("sync key to server failed.\(response.httpCode): \(response.message)")
            }
        } catch {
            log.error("sync account error \(error.localizedDescription)")
        }
    }

    private func flowKey(with publicKey: String) -> Flow.AccountKey {
        let flowPublicKey = Flow.PublicKey(hex: publicKey)
        let flowKey = Flow.AccountKey(
            publicKey: flowPublicKey,
            signAlgo: signAlgo,
            hashAlgo: .SHA2_256,
            weight: 1000
        )
        return flowKey
    }

    private func fetchKeyIndex(publicKey: String) async throws -> Int {
        let address = WalletManager.shared.getPrimaryWalletAddress() ?? ""
        let accounts = try await FlowNetwork.getAccountAtLatestBlock(address: address)
        let model = accounts.keys.first { $0.publicKey.description == publicKey }
        guard let accountModel = model else {
            return 0
        }
        return accountModel.index
    }

    private func addKeyToLocal() throws {
        guard let uid = UserManager.shared.activatedUID else {
            throw BackupError.missingUid
        }
        do {
            try keyProvider?.storeBackup(id: uid)
        } catch {
            log.error("[Back] create 12 Phrase backup failed.\(error.localizedDescription)")
        }
    }
}
