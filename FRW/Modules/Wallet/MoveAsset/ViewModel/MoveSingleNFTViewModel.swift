//
//  MoveSingleNFTViewModel.swift
//  FRW
//
//  Created by cat on 2024/5/22.
//

import Flow
import Foundation
import SwiftUI

class MoveSingleNFTViewModel: ObservableObject {
    var nft: NFTModel
    var fromChildAccount: ChildAccount?
    var callback: () -> Void

    @Published var fromContact = Contact(address: "", avatar: "", contactName: "", contactType: nil, domain: nil, id: -1, username: nil)
    @Published var toContact = Contact(address: "", avatar: "", contactName: "", contactType: nil, domain: nil, id: -1, username: nil)
    @Published var buttonState: VPrimaryButtonState = .enabled

    var accountCount: Int = 0

    init(nft: NFTModel, fromChildAccount: ChildAccount? = nil, callback: @escaping () -> Void) {
        self.nft = nft
        self.fromChildAccount = fromChildAccount
        self.callback = callback
        loadUserInfo()

        let accountViewModel = MoveAccountsViewModel(selected: "") { _ in }
        accountCount = accountViewModel.list.count
    }

    private func loadUserInfo() {
        guard let primaryAddr = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress() else {
            return
        }
        if let account = fromChildAccount {
            fromContact = Contact(address: account.showAddress, avatar: account.icon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
        } else if let account = ChildAccountManager.shared.selectedChildAccount {
            fromContact = Contact(address: account.showAddress, avatar: account.icon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
        } else if let account = EVMAccountManager.shared.selectedAccount {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            fromContact = Contact(address: account.showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, user: user, walletType: .evm)
        } else {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            fromContact = Contact(address: primaryAddr, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .flow)
        }

        if ChildAccountManager.shared.selectedChildAccount != nil || EVMAccountManager.shared.selectedAccount != nil || fromChildAccount != nil {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            toContact = Contact(address: primaryAddr, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .flow)
        } else if let account = EVMAccountManager.shared.accounts.first {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            toContact = Contact(address: account.showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, user: user, walletType: .evm)
        } else if let account = ChildAccountManager.shared.childAccounts.first {
            toContact = Contact(address: account.showAddress, avatar: account.icon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
        }
    }

    func closeAction() {
        Router.dismiss()
        callback()
    }

    func moveAction() {
        guard let nftId = UInt64(nft.response.id) else {
            HUD.error(title: "invalid data")
            return
        }
        buttonState = .loading
        Task {
            if fromContact.walletType == .link || toContact.walletType == .link {
                await moveForLinkedAccount(nftId: nftId)
            } else {
                let identifier = nft.collection?.flowIdentifier ?? nft.response.maskFlowIdentifier
                guard let identifier = identifier else {
                    log.error("Empty identifier on NFT>collection>")
                    HUD.debugError(title: "Empty identifier on NFT>collection>")
                    DispatchQueue.main.async {
                        self.buttonState = .enabled
                    }
                    return
                }

                await moveForEVM(identifier: identifier, nftId: nftId)
            }
            DispatchQueue.main.async {
                self.buttonState = .enabled
            }
        }
    }

    private func moveForEVM(identifier: String, nftId: UInt64) async {
        do {
            let ids: [UInt64] = [nftId]
            let fromEvm = EVMAccountManager.shared.selectedAccount != nil
            let tid = try await FlowNetwork.bridgeNFTToEVM(identifier: identifier, ids: ids, fromEvm: fromEvm)
            let holder = TransactionManager.TransactionHolder(id: tid, type: .moveAsset)
            TransactionManager.shared.newTransaction(holder: holder)
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
            log.error("[NFT] nft \(nft.collectionName) not found")
            return
        }
        let identifier = nft.publicIdentifier
        do {
            var tid = Flow.ID(hex: "")
            switch (fromContact.walletType, toContact.walletType) {
            case (.flow, .link):
                tid = try await FlowNetwork.moveNFTToChild(nftId: nftId, childAddress: toContact.address ?? "", identifier: identifier, collection: collection)
            case (.link, .flow):
                tid = try await FlowNetwork.moveNFTToParent(nftId: nftId, childAddress: fromContact.address ?? "", identifier: identifier, collection: collection)
            case (.link, .link):
                tid = try await FlowNetwork.sendChildNFTToChild(nftId: nftId, childAddress: fromContact.address ?? "", toAddress: toContact.address ?? "", identifier: identifier, collection: collection)
            case (.link, .evm):
                guard let nftIdentifier = nft.response.flowIdentifier else {
                    return
                }
                tid = try await FlowNetwork
                    .bridgeChildNFTToEvm(
                        nft: nftIdentifier,
                        id: nftId,
                        child: fromContact
                            .address ?? "")
            case (.evm, .link):
                guard let nftIdentifier = nft.response.flowIdentifier else {   
                    return
                }
                tid = try await FlowNetwork
                    .bridgeChildNFTFromEvm(
                        nft: nftIdentifier,
                        id: nftId,
                        child: toContact
                            .address ?? "")
            default:
                log.info("===")
            }
            let holder = TransactionManager.TransactionHolder(id: tid, type: .moveAsset)
            TransactionManager.shared.newTransaction(holder: holder)
            closeAction()
        } catch {
            log.error("[Move NFT] Move NFT failed on Linked Account. ")
            log.error(error)
        }
    }

    func updateToContact(_ contact: Contact) {
        toContact = contact
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
        !(fromContact.walletType == .link || toContact.walletType == .link)
    }
    
    var isFeeFree: Bool {
        fromContact.walletType == toContact.walletType
    }
}
