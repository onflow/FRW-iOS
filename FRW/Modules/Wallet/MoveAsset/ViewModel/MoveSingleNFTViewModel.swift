//
//  MoveSingleNFTViewModel.swift
//  FRW
//
//  Created by cat on 2024/5/22.
//

import Flow
import Foundation
import SwiftUI

// MARK: - MoveSingleNFTViewModel

final class MoveSingleNFTViewModel: ObservableObject {
    // MARK: Lifecycle

    init(nft: NFTModel, fromChildAccount: ChildAccount? = nil, callback: @escaping () -> Void) {
        self.nft = nft
        self.fromChildAccount = fromChildAccount
        self.callback = callback
        loadUserInfo()

        let accountViewModel = MoveAccountsViewModel(selected: "") { _ in }
        accountCount = accountViewModel.list.count
        checkForInsufficientStorage()
    }

    // MARK: Internal

    private(set) var nft: NFTModel
    private(set) var fromChildAccount: ChildAccount?
    private(set) var callback: () -> Void

    @Published
    private(set) var fromContact = Contact(
        address: "",
        avatar: "",
        contactName: "",
        contactType: nil,
        domain: nil,
        id: -1,
        username: nil
    )
    @Published
    private(set) var toContact = Contact(
        address: "",
        avatar: "",
        contactName: "",
        contactType: nil,
        domain: nil,
        id: -1,
        username: nil
    )
    @Published
    private(set) var buttonState: VPrimaryButtonState = .enabled

    private(set) var accountCount: Int = 0

    func closeAction() {
        Router.dismiss()
        callback()
    }

    func moveAction() {
        defer {
            runOnMain {
                self.buttonState = .enabled
            }
        }

        guard let nftId = UInt64(nft.response.id) else {
            HUD.error(title: "invalid data")
            return
        }

        Task {
            await MainActor.run {
                self.buttonState = .loading
            }

            if fromContact.walletType == .link || toContact.walletType == .link {
                await moveForLinkedAccount(nftId: nftId)
                return
            }

            guard let identifier = nft.collection?.flowIdentifier ?? nft.response.maskFlowIdentifier else {
                HUD.error(MoveError.invalidateIdentifier)
                return
            }

            await moveForEVM(identifier: identifier, nftId: nftId)
        }
    }

    func updateToContact(_ contact: Contact) {
        toContact = contact
        checkForInsufficientStorage()
    }

    // MARK: Private

    private var _insufficientStorageFailure: InsufficientStorageFailure?

    private func loadUserInfo() {
        guard let primaryAddr = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress()
        else {
            return
        }
        if let account = fromChildAccount {
            fromContact = Contact(
                address: account.showAddress,
                avatar: account.icon,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName,
                walletType: .link
            )
        } else if let account = ChildAccountManager.shared.selectedChildAccount {
            fromContact = Contact(
                address: account.showAddress,
                avatar: account.icon,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName,
                walletType: .link
            )
        } else if let account = EVMAccountManager.shared.selectedAccount {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            fromContact = Contact(
                address: account.showAddress,
                avatar: nil,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName,
                user: user,
                walletType: .evm
            )
        } else {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            fromContact = Contact(
                address: primaryAddr,
                avatar: nil,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: user.name,
                user: user,
                walletType: .flow
            )
        }

        if ChildAccountManager.shared.selectedChildAccount != nil || EVMAccountManager.shared
            .selectedAccount != nil || fromChildAccount != nil
        {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            toContact = Contact(
                address: primaryAddr,
                avatar: nil,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: user.name,
                user: user,
                walletType: .flow
            )
        } else if let account = EVMAccountManager.shared.accounts.first {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            toContact = Contact(
                address: account.showAddress,
                avatar: nil,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName,
                user: user,
                walletType: .evm
            )
        } else if let account = ChildAccountManager.shared.childAccounts.first {
            toContact = Contact(
                address: account.showAddress,
                avatar: account.icon,
                contactName: nil,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName,
                walletType: .link
            )
        }
    }

    private func moveForEVM(identifier: String, nftId: UInt64) async {
        do {
            let ids: [UInt64] = [nftId]
            let fromEvm = EVMAccountManager.shared.selectedAccount != nil
            let tid = try await FlowNetwork.bridgeNFTToEVM(
                identifier: identifier,
                ids: ids,
                fromEvm: fromEvm
            )
            let holder = TransactionManager.TransactionHolder(id: tid, type: .moveAsset)
            TransactionManager.shared.newTransaction(holder: holder)
            EventTrack.Transaction
                .NFTTransfer(
                    from: fromContact.address ?? "",
                    to: toContact.address ?? "",
                    identifier: nft.response.flowIdentifier ?? "",
                    txId: tid.hex,
                    fromType: fromContact.walletType?.trackName ?? "",
                    toType: toContact.walletType?.trackName ?? "",
                    isMove: true
                )
            closeAction()
        } catch {
            log.error(" Move NFT =====")
            log.error(error)
        }
    }

    private func moveForLinkedAccount(nftId: UInt64) async {
        var collection = nft.collection
        if collection == nil {
            collection = NFTCatalogCache.cache
                .find(by: nft.collectionName)?.collection
        }

        guard let collection = collection else {
            HUD.error(MoveError.invalidateNftCollectionInfo)
            return
        }

        guard let toAddress = toContact.address else {
            HUD.error(MoveError.invalidateToAddress)
            return
        }

        guard let fromAddress = fromContact.address else {
            HUD.error(MoveError.invalidateFromAddress)
            return
        }

        guard let identifier = nft.response.flowIdentifier ?? nft.publicIdentifier else {
            HUD.error(MoveError.invalidateIdentifier)
            return
        }

        do {
            var tid: Flow.ID? = nil
            switch (fromContact.walletType, toContact.walletType) {
            case (.flow, .link):
                tid = try await FlowNetwork.moveNFTToChild(
                    nftId: nftId,
                    childAddress: toAddress,
                    identifier: identifier,
                    collection: collection
                )
            case (.link, .flow):
                tid = try await FlowNetwork.moveNFTToParent(
                    nftId: nftId,
                    childAddress: fromAddress,
                    identifier: identifier,
                    collection: collection
                )
            case (.link, .link):
                tid = try await FlowNetwork.sendChildNFTToChild(
                    nftId: nftId,
                    childAddress: fromAddress,
                    toAddress: toAddress,
                    identifier: identifier,
                    collection: collection
                )
            case (.link, .evm):
                tid = try await FlowNetwork
                    .bridgeChildNFTToEvm(
                        nft: identifier,
                        id: nftId,
                        child: fromAddress
                    )
            case (.evm, .link):
                tid = try await FlowNetwork
                    .bridgeChildNFTFromEvm(
                        nft: identifier,
                        id: nftId,
                        child: toAddress
                    )
            default:
                log.info("===")
            }

            guard let tid else {
                HUD.error(MoveError.failedToSubmitTransaction)
                return
            }

            let holder = TransactionManager.TransactionHolder(id: tid, type: .moveAsset)
            TransactionManager.shared.newTransaction(holder: holder)
            EventTrack.Transaction
                .NFTTransfer(
                    from: fromAddress,
                    to: toAddress,
                    identifier: identifier,
                    txId: tid.hex,
                    fromType: fromContact.walletType?.trackName ?? "",
                    toType: toContact.walletType?.trackName ?? "",
                    isMove: true
                )

            closeAction()
        } catch {
            log.error("[Move NFT] Move NFT failed on Linked Account. ")
            log.error(error)
            HUD.error(title: error.localizedDescription)
        }
    }
}

// MARK: - InsufficientStorageToastViewModel

extension MoveSingleNFTViewModel: InsufficientStorageToastViewModel {
    var variant: InsufficientStorageFailure? { _insufficientStorageFailure }

    private func checkForInsufficientStorage() {
        _insufficientStorageFailure = insufficientStorageCheckForMove(token: .nft(nft), from: fromContact.walletType, to: toContact.walletType)
    }
}

extension MoveSingleNFTViewModel {
    var fromIsEVM: Bool {
        EVMAccountManager.shared.accounts.contains { $0.showAddress == fromContact.address }
    }

    var toIsEVM: Bool {
        EVMAccountManager.shared.accounts.contains { $0.showAddress == toContact.address }
    }

    func logo() -> Image {
        let isSelectedEVM = EVMAccountManager.shared.selectedAccount != nil
        return isSelectedEVM ? Image("icon_qr_evm") : Image("Flow")
    }

    var showFee: Bool {
        guard !RemoteConfigManager.shared.coverBridgeFee else {
            return false
        }
        return !(fromContact.walletType == .link || toContact.walletType == .link)
    }

    var isFeeFree: Bool {
        fromContact.walletType == toContact.walletType
    }
}
