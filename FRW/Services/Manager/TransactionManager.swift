//
//  TransactionManager.swift
//  Flow Wallet
//
//  Created by Selina on 25/8/2022.
//

import Flow
import SwiftUI
import UIKit

extension Flow.Transaction.Status {
    var progressPercent: CGFloat {
        switch self {
        case .pending, .unknown:
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
    var statusString: String {
        switch Flow.Transaction.Status(status) {
        case .unknown:
            return "Unknown"
        case .pending:
            return "Pending"
        case .finalized:
            return "Finalized"
        case .executed:
            return "Executed"
        case .sealed:
            return "Sealed"
        case .expired:
            return "Expired"
        }
    }

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
            status: statusString,
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

    class TransactionHolder: Codable {
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
            log.info("[Cadence] txi:\(id.hex)")
        }

        // MARK: Internal

        enum CodingKeys: String, CodingKey {
            case transactionId
            case createTime
            case status
            case type
            case data
            case internalStatus
        }

        var transactionId: Flow.ID
        var createTime: TimeInterval
        var status: Int = Flow.Transaction.Status.pending.rawValue
        var internalStatus: TransactionManager.InternalStatus = .pending
        var type: TransactionManager.TransactionType
        var data: Data = .init()
        var errorMsg: String?
        var scriptId: String?

        var flowStatus: Flow.Transaction.Status {
            Flow.Transaction.Status(status)
        }

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

        func startTimer() {
            stopTimer()

            if retryTimes > 5 {
                internalStatus = .failed
                postNotification()
                return
            }

            let timer = Timer(
                timeInterval: 2,
                target: self,
                selector: #selector(onCheck),
                userInfo: nil,
                repeats: false
            )
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer

            debugPrint("TransactionHolder -> startTimer")
        }

        func stopTimer() {
            if let timer = timer {
                timer.invalidate()
                self.timer = nil
                debugPrint("TransactionHolder -> stopTimer")
            }
        }

        // MARK: Private

        private var timer: Timer?
        private var retryTimes: Int = 0

        @objc
        private func onCheck() {
            debugPrint("TransactionHolder -> onCheck")

            Task {
                do {
                    let result = try await FlowNetwork.getTransactionResult(by: transactionId.hex)
                    debugPrint("TransactionHolder -> onCheck status: \(result.status)")

                    DispatchQueue.main.async { [self] in
                        if result.status == self.flowStatus, result.status < .sealed {
                            self.startTimer()
                            return
                        }

                        self.status = result.status.rawValue
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
                            log.error(CustomError.custom("\(errorCode)", "scriptId: " + (scriptId ?? "") + " ,txid: " + transactionId.description),
                                      group: .custom(group),
                                      report: true,
                                      reportUserAttribute: ["scriptId": scriptId ?? ""])
                            switch result.errorCode {
                            case .storageCapacityExceeded:
                                AlertViewController.showInsufficientStorageError(minimumBalance: WalletManager.shared.minimumStorageBalance.doubleValue)
                            default:
                                break
                            }
                        } else if result.isComplete {
                            self.internalStatus = .success
                            self.trackResult(
                                result: result,
                                fromId: self.transactionId.hex
                            )
                        } else {
                            self.internalStatus = .pending
                            self.startTimer()
                        }

                        self.postNotification()
                    }
                } catch {
                    debugPrint("TransactionHolder -> onCheck failed: \(error)")
                    await MainActor.run {
                        self.retryTimes += 1
                        self.startTimer()
                    }
                }
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
        checkFolder()
        addNotification()
        loadHoldersFromCache()
        startCheckIfNeeded()
    }

    // MARK: Internal

    static let shared = TransactionManager()

    @Published
    private(set) var holders: [TransactionHolder] = []

    // MARK: Private

    private lazy var rootFolder = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
    ).first!.appendingPathComponent("transaction_cache")
    private lazy var transactionCacheFile = rootFolder
        .appendingPathComponent("transaction_cache_file")

    private func addNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onHolderChanged(noti:)),
            name: .transactionStatusDidChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willReset),
            name: .willResetWallet,
            object: nil
        )
    }

    @objc
    private func willReset() {
        holders = []
        saveHoldersToCache()
        postDidChangedNotification()
    }

    @objc
    private func onHolderChanged(noti: Notification) {
        guard let holder = noti.object as? TransactionHolder else {
            return
        }

        if holder.internalStatus == .pending {
            return
        }

        if holder.internalStatus == .failed {
            removeTransaction(id: holder.transactionId.hex)
            HUD.error(title: holder.errorHUDMessage)
            return
        }

        HUD.success(title: holder.successHUDMessage, message: nil, preset: .done, haptic: .none)

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        feedbackGenerator.impactOccurred()

        removeTransaction(id: holder.transactionId.hex)

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
            holder.startTimer()
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
        saveHoldersToCache()
        postDidChangedNotification()

        holder.startTimer()
    }

    func removeTransaction(id: String) {
        for holder in holders {
            if holder.transactionId.hex == id {
                holder.stopTimer()
            }
        }

        holders.removeAll { $0.transactionId.hex == id }
        saveHoldersToCache()
        postDidChangedNotification()
    }

    func isExist(tid: String) -> Bool {
        for holder in holders {
            if holder.transactionId.hex == tid {
                return true
            }
        }

        return false
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

extension TransactionManager {
    private func checkFolder() {
        do {
            if !FileManager.default.fileExists(atPath: rootFolder.relativePath) {
                try FileManager.default.createDirectory(
                    at: rootFolder,
                    withIntermediateDirectories: true
                )
            }

        } catch {
            debugPrint("TransactionManager -> checkFolder error: \(error)")
        }
    }

    private func loadHoldersFromCache() {
        if !FileManager.default.fileExists(atPath: transactionCacheFile.relativePath) {
            return
        }

        do {
            let data = try Data(contentsOf: transactionCacheFile)
            let list = try JSONDecoder().decode(
                [TransactionManager.TransactionHolder].self,
                from: data
            )
            let filterdList = list.filter { $0.internalStatus == .pending }

            if !filterdList.isEmpty {
                holders = filterdList
            }
        } catch {
            debugPrint("TransactionManager -> loadHoldersFromCache error: \(error)")
        }
    }

    private func saveHoldersToCache() {
        let filterdHolders = holders.filter { $0.internalStatus == .pending }

        do {
            let data = try JSONEncoder().encode(filterdHolders)
            try data.write(to: transactionCacheFile)
        } catch {
            debugPrint("TransactionManager -> saveHoldersToCache error: \(error)")
        }
    }
}

private extension String {
    func trimError() -> String {
        let result = removePrefix("Optional(").removeSuffix(")")
        return result
    }
}
