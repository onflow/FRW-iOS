//
//  TransactionManager.swift
//  Flow Wallet
//
//  Created by Selina on 25/8/2022.
//

import Flow
import SwiftUI
import UIKit
import Combine

extension Flow.Transaction.Status {
    var progressPercent: CGFloat {
        switch self {
        case .unknown:
            return 0.01
        case .pending:
            return 0.33
        case .finalized:
            return 0.66
        case .executed:
            return 1.0
        case .sealed:
            return 1.0
        default:
            return 0
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

extension TransactionManager {
    enum TransactionType: Int, Codable {
        case common
        case transferCoin
        case addToken
        case addCollection
        case transferNFT
        case fclTransaction
        case claimDomain
        case stakeFlow
        case unlinkAccount
        case editChildAccount
        case moveAsset
    }

    enum InternalStatus: Int, Codable {
        case pending
        case success
        case failed

        // MARK: Internal

        var statusColor: UIColor {
            switch self {
            case .pending:
                return UIColor.LL.Primary.salmonPrimary
            case .success:
                return UIColor.LL.Success.success3
            case .failed:
                return UIColor.LL.Warning.warning3
            }
        }
    }

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
                .sink { _ in
                } receiveValue: { value in
                    flow.websocket.unsubscribe(subscriptionId: value.subscriptionId)
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

        private func postNotification() {
            debugPrint("TransactionHolder -> postNotification status: \(status)")
            NotificationCenter.default.post(name: .transactionStatusDidChanged, object: self)
        }
    }
}

// MARK: - TransactionManager

class TransactionManager: ObservableObject {
    // MARK: Lifecycle

    init() {
        addNotification()
        start()
        flow.websocket.isDebug = true
    }

    // MARK: Internal

    static let shared = TransactionManager()

    private var cancellables = Set<AnyCancellable>()
    
    @Published
    private(set) var holders: [TransactionHolder] = []

    // MARK: Private

    private func addNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willReset),
            name: .willResetWallet,
            object: nil
        )
    }
    
    private func start() {
        flow.publisher.transactionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (id, txResult) in
                self?.onHolderChanged(txId: id, result: txResult)
            }
            .store(in: &cancellables)
    }

    @objc
    private func willReset() {
        holders = []
    }

    private func onHolderChanged(txId: Flow.ID, result: Flow.TransactionResult) {
        log.info("TX Status Changed: \(result.status) - \(txId) - \(Date.now)")
        guard let holder = holders.first(where: { $0.transactionId == txId }) else {
            return
        }
        
        holder.status = result.status
        
        if result.status < .executed {
            holder.internalStatus = .pending
            return
        }
        
        holder.internalStatus = result.isFailed ? .failed : .success
        
        if result.isFailed {
            removeTransaction(id: txId)
            HUD.error(title: holder.errorHUDMessage)
            return
        }

        HUD.success(title: holder.successHUDMessage, message: nil, preset: .done, haptic: .none)

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        feedbackGenerator.impactOccurred()

        removeTransaction(id: holder.transactionId)

        switch holder.type {
        case .claimDomain:
            DispatchQueue.main.async {
                UserManager.shared.isMeowDomainEnabled = true
            }
        case .transferCoin:
            Task {
                // TODO: Reload Balance
//                try? await WalletManager.shared.fetchBalance()
            }
        case .addToken:
            Task {
                try? await WalletManager.shared.fetchWalletDatas()
            }
        case .addCollection:
            NotificationCenter.default.post(name: .nftCollectionsDidChanged, object: nil)
        case .transferNFT:
            if let model = holder.decodedObject(NFTTransferModel.self) {
                NFTUIKitCache.cache.transferedNFT(model.nft.response)
            }
            NotificationCenter.default.post(name: .nftDidChangedByMoving, object: nil)
        case .stakeFlow:
            StakingManager.shared.refresh()
        case .unlinkAccount:
            if let model = holder.decodedObject(ChildAccount.self) {
                ChildAccountManager.shared.didUnlinkAccount(model)
            }
        case .common:
            Task {
                try? await WalletManager.shared.fetchWalletDatas()
            }
        case .moveAsset:
            NotificationCenter.default.post(name: .nftDidChangedByMoving, object: nil)
        default:
            break
        }
    }

    private func startCheckIfNeeded() {
        for holder in holders {
            holder.start()
        }
    }

    private func postDidChangedNotification() {
        DispatchQueue.syncOnMain {
            NotificationCenter.default.post(name: .transactionManagerDidChanged, object: nil)
        }
    }
}

// MARK: - Public

extension TransactionManager {
    func newTransaction(holder: TransactionManager.TransactionHolder) {
        holders.insert(holder, at: 0)
        postDidChangedNotification()
        holder.start()
    }

    func removeTransaction(id: Flow.ID) {
        holders.removeAll { $0.transactionId == id }
        postDidChangedNotification()
    }

    func isExist(tid: String) -> Bool {
        return holders.map { $0.transactionId.hex }.contains(tid.removePrefix("0x"))
    }

    func isTokenEnabling(symbol: String) -> Bool {
        for holder in holders {
            if holder.type == .addToken, let token = holder.decodedObject(TokenModel.self),
               token.symbol == symbol
            {
                return true
            }
        }

        return false
    }

    func isCollectionEnabling(contractName: String) -> Bool {
        for holder in holders {
            if holder.type == .addCollection,
               let collection = holder.decodedObject(NFTCollectionInfo.self),
               collection.contractName == contractName
            {
                return true
            }
        }

        return false
    }

    func isNFTTransfering(id: String) -> Bool {
        for holder in holders {
            if holder.type == .transferNFT, let model = holder.decodedObject(NFTTransferModel.self),
               model.nft.id == id
            {
                return true
            }
        }

        return false
    }
}

// MARK: - Cache

private extension String {
    func trimError() -> String {
        let result = removePrefix("Optional(").removeSuffix(")")
        return result
    }
}
