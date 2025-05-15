//
//  SyncAddDeviceViewModel.swift
//  FRW
//
//  Created by cat on 2023/11/30.
//

import Flow
import Foundation
import WalletConnectSign
import WalletConnectUtils

// MARK: - SyncAddDeviceViewModel.Callback

extension SyncAddDeviceViewModel {
    typealias Callback = (Bool) -> Void
}

// MARK: - SyncAddDeviceViewModel

class SyncAddDeviceViewModel: ObservableObject {
    // MARK: Lifecycle

    init(with model: SyncInfo.DeviceInfo, callback: @escaping SyncAddDeviceViewModel.Callback) {
        self.model = model
        self.callback = callback
    }

    deinit {
        NotificationCenter().removeObserver(self)
    }

    // MARK: Internal

    var model: SyncInfo.DeviceInfo
    @Published
    var result: String = ""

    func addDevice() {
        Task {
            let address = WalletManager.shared.address
            let accountKey = Flow.AccountKey(
                publicKey: Flow.PublicKey(hex: model.accountKey.publicKey),
                signAlgo: Flow.SignatureAlgorithm(index: model.accountKey.signAlgo),
                hashAlgo: Flow.HashAlgorithm(cadence: model.accountKey.hashAlgo),
                weight: 1000
            )
            do {
                let flowAccount = try await findFlowAccount(at: WalletManager.shared.keyIndex)
                let sequenceNumber = flowAccount?.sequenceNumber ?? 0
                let flowId = try await FlowNetwork.addKeyWithMulti(
                    address: address,
                    keyIndex: WalletManager.shared.keyIndex,
                    sequenceNum: sequenceNumber,
                    accountKey: accountKey,
                    signers: WalletManager.shared.defaultSigners
                )
                guard let data = try? JSONEncoder().encode(model) else {
                    EventTrack.Dev.deviceBackup(progress: .addKeyToChain,
                                                message: "encoder failed")
                    return
                }
                let holder = TransactionManager.TransactionHolder(
                    id: flowId,
                    type: .addToken,
                    data: data
                )
                TransactionManager.shared.newTransaction(holder: holder)

                HUD.loading()
                let result = try await flowId.onceSealed()
                if result.isSealed {
                    sendSuccessStatus()
                } else {
                    EventTrack.Dev.deviceBackup(progress: .addKeyToChain,
                                                message: "transction failed.")
                    sendFaildStatus()
                }
                HUD.dismissLoading()
            } catch {
                EventTrack.Dev.deviceBackup(progress: .addKeyToChain,
                                            message: "error:\(error), publicKey:\(model.accountKey.publicKey.prefix(8))")
                HUD.dismissLoading()
                HUD.error(title: "restore_account_failed".localized)
            }
        }
    }

    func dismiss() {
        Router.dismiss()
    }

    func sendSuccessStatus() {
        Task {
            let publicKey = self.model.accountKey.publicKey
            do {
                let response: Network.EmptyResponse = try await Network
                    .requestWithRawModel(FRWAPI.User.syncDevice(self.model))
                if response.httpCode != 200 {
                    log.info("[Sync Device] add device failed. publicKey: \(publicKey)")
                    EventTrack.Dev.deviceBackup(progress: .addKeyToBackend, message: "code:\(response.httpCode), publicKey:\(publicKey.prefix(8))")
                    await MainActor.run {
                        self.result = "add device failed."
                    }
                    callback?(false)
                } else {
                    await MainActor.run {
                        self.dismiss()
                    }
                    callback?(true)
                }
            } catch {
                callback?(false)
                EventTrack.Dev.deviceBackup(progress: .addKeyToBackend, message: "error:\(error), publicKey:\(publicKey.prefix(8))")
                log.error("[sync account] error \(error.localizedDescription)")
            }
        }
    }

    func sendFaildStatus() {
        callback?(false)
    }

    func findFlowAccount(at index: Int) async throws -> Flow.AccountKey? {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }

        let account = try await FlowNetwork.getAccountAtLatestBlock(address: address)
        let sortedAccount = account.keys.filter { $0.index == index }
        let flowAccountKey = sortedAccount.first
        return flowAccountKey
    }

    // MARK: Private

    private var callback: BrowserAuthzViewModel.Callback?
}
