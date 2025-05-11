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
        case .unknown, .pending:
            return 0.33
        case .finalized:
            return 0.66
        case .executed, .sealed:
            return 1.0
        default:
            return 0
        }
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
