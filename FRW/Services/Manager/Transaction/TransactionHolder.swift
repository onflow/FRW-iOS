//
//  TransactionHolder.swift
//  FRW
//
//  Created by Hao Fu on 9/5/2025.
//

import Foundation
import Flow
import Combine

extension TransactionManager {
    class TransactionHolder {
        // MARK: Lifecycle
        
        init(
            id: Flow.ID,
            createTime: TimeInterval = Date().timeIntervalSince1970,
            type: TransactionManager.TransactionType,
            data: Data = Data(),
            scriptId: String? = nil
        ) {
            transactionId = id
            self.createTime = createTime
            self.type = type
            self.data = data
            self.scriptId = scriptId
            if scriptId == nil {
                Task {
                    self.scriptId = await FlowNetwork.scriptId(id)
                    await FlowNetwork.removeScriptId(id)
                }
            }
            log.info("[Cadence] txId:\(id.hex)")
        }
        
        // MARK: Internal
        
        var transactionId: Flow.ID
        var createTime: TimeInterval
        var status: Flow.Transaction.Status = .unknown
        var internalStatus: TransactionManager.InternalStatus = .pending
        var type: TransactionManager.TransactionType
        var data: Data = .init()
        var errorMsg: String?
        var scriptId: String?
        
        var cancellables: Set<AnyCancellable> = []
        
        func decodedObject<T: Decodable>(_ type: T.Type) -> T? {
            try? JSONDecoder().decode(type, from: data)
        }
        
        func icon() -> URL? {
            switch type {
            case .transferCoin:
                guard let model = decodedObject(CoinTransferModel.self),
                      let token = WalletManager.shared.getToken(by: model.symbol)
                else {
                    return nil
                }
                
                return token.iconURL
            case .addToken:
                return decodedObject(TokenModel.self)?.iconURL
            case .addCollection:
                return decodedObject(NFTCollectionInfo.self)?.logoURL
            case .transferNFT:
                return decodedObject(NFTTransferModel.self)?.nft.logoUrl
            case .fclTransaction:
                guard let model = decodedObject(AuthzTransaction.self),
                      let urlString = model.url
                else {
                    return nil
                }
                
                return urlString.toFavIcon()
            case .unlinkAccount:
                guard let iconString = decodedObject(ChildAccount.self)?.icon,
                      let url = URL(string: iconString)
                else {
                    return nil
                }
                
                return url
            default:
                return nil
            }
        }
        
        func start() {
            let _ = flow.websocket.subscribeToTransactionStatus(txId: transactionId)
                .filter { $0.payload?.transactionResult.status ?? .unknown >= .sealed }
                .first()
                .sink { complete in
                    self.postNotification()
                } receiveValue: { [weak self] value in
                    flow.websocket.unsubscribe(subscriptionId: value.subscriptionId)
                    if let result = value.payload?.transactionResult {
                        self?.handleFinish(result)
                    }
                }.store(in: &cancellables)
            
        }
        
        private func postNotification() {
            debugPrint("TransactionHolder -> postNotification status: \(status)")
            NotificationCenter.default.post(name: .transactionStatusDidChanged, object: self)
        }
        
        private func handleFinish(_ result: Flow.TransactionResult) {
            if result.isFailed {
                self.errorMsg = result.errorMessage
                self.internalStatus = .failed
                
                self.trackResult(
                    result: result,
                    fromId: self.transactionId.hex
                )
                log.warning("TransactionHolder -> onCheck result failed: \(result.errorMessage)")
                
                let errorCode = String(describing: result.errorCode).trimError()
                let group = "\(scriptId ?? "empty")" + ".tx." + "\(errorCode)"
                log.error(CustomError.custom("\(errorCode)", "scriptId: " + (scriptId ?? "") + ", txid: " + transactionId.description),
                          group: .custom(group),
                          report: true,
                          reportUserAttribute: ["scriptId": scriptId ?? ""])
                switch result.errorCode {
                case .storageCapacityExceeded:
                    AlertViewController.showInsufficientStorageError(minimumBalance: WalletManager.shared.minimumStorageBalance.doubleValue)
                default:
                    break
                }
            } else {
                self.trackResult(
                    result: result,
                    fromId: self.transactionId.hex
                )
            }
        }
        
        private func trackResult(result: Flow.TransactionResult, fromId _: String) {
            EventTrack.Transaction
                .transactionResult(
                    txId: transactionId.hex,
                    successful: result.isComplete,
                    message: result.errorMessage
                )
        }

    }
}

extension TransactionManager.TransactionHolder {
    var successHUDMessage: String {
        switch type {
        case .claimDomain:
            return "claim_domain_success".localized
        default:
            return "transaction_success".localized
        }
    }

    var errorHUDMessage: String {
        switch type {
        case .claimDomain:
            return "claim_domain_failed".localized
        default:
            return "transaction_failed".localized
        }
    }

    var toFlowScanTransaction: FlowScanTransaction {
        let time = ISO8601Formatter.string(from: Date(timeIntervalSince1970: createTime))
        let model = FlowScanTransaction(
            authorizers: nil,
            contractInteractions: nil,
            error: errorMsg,
            eventCount: nil,
            hash: transactionId.hex,
            index: nil,
            payer: nil,
            proposer: nil,
            status: status.stringValue,
            time: time
        )
        return model
    }
}

// MARK: - Cache

private extension String {
    func trimError() -> String {
        let result = removePrefix("Optional(").removeSuffix(")")
        return result
    }
}
