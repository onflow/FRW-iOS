//
//  MoveNFTsViewModel.swift
//  FRW
//
//  Created by cat on 2024/5/17.
//

import Flow
import Foundation
import Kingfisher
import SwiftUI

class MoveNFTsViewModel: ObservableObject {
    @Published var selectedCollection: CollectionMask?
    private var collectionList: [CollectionMask] = []
    // NFTModel
    @Published var nfts: [MoveNFTsViewModel.NFT] = [
        MoveNFTsViewModel.NFT.mock(),
        MoveNFTsViewModel.NFT.mock(),
        MoveNFTsViewModel.NFT.mock(),
    ]
    @Published var isMock = true
    @Published var showHint = false
    @Published var showFee = false

    @Published var buttonState: VPrimaryButtonState = .disabled

    @Published var fromContact = Contact(address: "", avatar: "", contactName: "", contactType: nil, domain: nil, id: -1, username: nil)
    @Published var toContact = Contact(address: "", avatar: "", contactName: "", contactType: nil, domain: nil, id: -1, username: nil)

    let limitCount = 10

    init() {
        fetchNFTs(0)
        loadUserInfo()
    }

    private func loadUserInfo() {
        guard let primaryAddr = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress() else {
            return
        }
        if let account = ChildAccountManager.shared.selectedChildAccount {
            fromContact = Contact(address: account.showAddress, avatar: account.icon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
        } else if let account = EVMAccountManager.shared.selectedAccount {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            fromContact = Contact(address: account.showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, user: user, walletType: .evm)
        } else {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            fromContact = Contact(address: primaryAddr, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .flow)
        }

        if ChildAccountManager.shared.selectedChildAccount != nil || EVMAccountManager.shared.selectedAccount != nil {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            toContact = Contact(address: primaryAddr, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .flow)
        } else if let account = EVMAccountManager.shared.accounts.first {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            toContact = Contact(address: account.showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, user: user, walletType: .evm)
        } else if let account = ChildAccountManager.shared.childAccounts.first {
            toContact = Contact(address: account.showAddress, avatar: account.icon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
        }
        
        updateFee()
    }

    private func updateFee() {
        showFee =  !(fromContact.walletType == .link || toContact.walletType == .link)
    }
    func updateToContact(_ contact: Contact) {
        toContact = contact
        updateFee()
    }

    func moveAction() {
        guard let collection = selectedCollection else {
            return
        }
        buttonState = .loading
        Task {
            do {
                let identifier = collection.maskFlowIdentifier ?? nfts.first?.model.maskFlowIdentifier ?? nil
                let ids: [UInt64] = nfts.compactMap { nft in
                    if !nft.isSelected {
                        return nil
                    }
                    let nftId = nft.model.maskId
                    guard let resultId = UInt64(nftId) else {
                        return nil
                    }
                    return resultId
                }
                guard let identifier = identifier else {
                    return
                }
                var tid: Flow.ID?
                switch (fromContact.walletType, toContact.walletType) {
                case (.flow, .evm):
                    tid = try await FlowNetwork.bridgeNFTToEVM(identifier: identifier, ids: ids, fromEvm: false)
                case (.evm, .flow):
                    tid = try await FlowNetwork.bridgeNFTToEVM(identifier: identifier, ids: ids, fromEvm: true)
                case (.flow, .link):
                    if let coll = collection as? NFTCollection {
                        let identifier = coll.collection.path?.privatePath ?? ""
                        tid = try await FlowNetwork.batchMoveNFTToChild(childAddr: toContact.address ?? "", identifier: identifier, ids: ids, collection: coll.collection)
                    }
                case (.link, .flow):
                    if let coll = collection as? NFTCollection {
                        let identifier = coll.collection.path?.privatePath ?? ""
                        tid = try await FlowNetwork.batchMoveNFTToParent(childAddr: fromContact.address ?? "", identifier: identifier, ids: ids, collection: coll.collection)
                    }
                case (.link, .link):
                    if let coll = collection as? NFTCollection {
                        let identifier = coll.collection.path?.privatePath ?? ""
                        tid = try await FlowNetwork.batchSendChildNFTToChild(fromAddress: fromContact.address ?? "", toAddress: toContact.address ?? "", identifier: identifier, ids: ids, collection: coll.collection)
                    }
                case (.link, .evm):
                    if let coll = collection as? NFTCollection {
                        let identifier = coll.collection.path?.privatePath ?? ""
                        tid = try await FlowNetwork
                            .batchBridgeChildNFTToCoa(
                                nft: identifier,
                                ids: ids,
                                child: fromContact.address ?? "")
                    }
                case (.evm, .link):
                    if let coll = collection as? NFTCollection {
                        let identifier = coll.collection.path?.privatePath ?? ""
                        tid = try await FlowNetwork
                            .batchBridgeChildNFTFromCoa(
                                nft: identifier,
                                ids: ids,
                                child: toContact.address ?? ""
                            )
                    }
                default:
                    HUD.info(title: "Feature_Coming_Soon::message".localized)
                }
                if let txid = tid {
                    let holder = TransactionManager.TransactionHolder(id: txid, type: .moveAsset)
                    TransactionManager.shared.newTransaction(holder: holder)
                }
                closeAction()
            } catch {
                log.error(" Move NFTs =====")
                log.error(error)
                buttonState = .enabled
            }
        }
    }

    func selectCollectionAction() {
        let vm = SelectCollectionViewModel(selectedItem: selectedCollection, list: collectionList) { [weak self] item in
            DispatchQueue.main.async {
                self?.updateCollection(item: item)
            }
        }
        Router.route(to: RouteMap.NFT.selectCollection(vm))
    }

    private func updateCollection(item: CollectionMask) {
        if item.maskId == selectedCollection?.maskId, item.maskContractName == selectedCollection?.maskContractName {
            return
        }
        selectedCollection = item

        nfts = []
        fetchNFTs()
    }

    func closeAction() {
        Router.dismiss {
            MoveAssetsAction.shared.endBrowser()
        }
    }

    func toggleSelection(of nft: MoveNFTsViewModel.NFT) {
        if let index = nfts.firstIndex(where: { $0.id == nft.id }) {
            if !nfts[index].isSelected, selectedCount >= limitCount {
            } else {
                nfts[index].isSelected.toggle()
            }
        }

        resetButtonState()
    }

    var selectedCount: Int {
        nfts.filter { $0.isSelected }.count
    }

    private func resetButtonState() {
        buttonState = selectedCount > 0 ? .enabled : .disabled
        showHint = selectedCount >= limitCount
    }

    var moveButtonTitle: String {
        if selectedCount > 0 {
            return "move_nft_x".localized(String(selectedCount))
        }
        return "move_nft".localized
    }

    private func fetchCollection() {
        Task {
            do {
                let address = WalletManager.shared.selectedAccountAddress
                let offset = FRWAPI.Offset(start: 0, length: 100)
                let from: FRWAPI.From = EVMAccountManager.shared.selectedAccount != nil ? .evm : .main
                let response: Network.Response<[NFTCollection]> = try await Network.requestWithRawModel(FRWAPI.NFT.userCollection(address, offset, from))
                DispatchQueue.main.async {
                    self.collectionList = response.data?.sorted(by: { $0.count > $1.count }) ?? []
                    if self.selectedCollection == nil {
                        self.selectedCollection = self.collectionList.first
                    }
                    if self.selectedCollection != nil {
                        self.fetchNFTs()
                    } else {
                        DispatchQueue.main.async {
                            self.nfts = []
                            self.isMock = false
                            self.resetButtonState()
                        }
                    }
                }
            } catch {
                log.error("[MoveAsset] fetch Collection failed:\(error)")
            }
        }
    }

    func fetchNFTs(_ offset: Int = 0) {
        buttonState = .loading
        guard let collection = selectedCollection else {
            fetchCollection()
            return
        }
        Task {
            do {
                let isEVM = EVMAccountManager.shared.selectedAccount != nil
                let address = WalletManager.shared.selectedAccountAddress
                let request = NFTCollectionDetailListRequest(address: address, collectionIdentifier: collection.maskId, offset: offset, limit: 30)
                let response: NFTListResponse = try await Network.request(FRWAPI.NFT.collectionDetailList(request, isEVM ? .evm : .main))
                DispatchQueue.main.async {
                    if let list = response.nfts {
                        self.nfts = list.map { MoveNFTsViewModel.NFT(isSelected: false, model: $0) }
                    } else {
                        self.nfts = []
                    }
                    self.isMock = false
                    self.resetButtonState()
                }
            } catch {
                DispatchQueue.main.async {
                    self.nfts = []
                    self.isMock = false
                    self.resetButtonState()
                }
                log.error("[MoveAsset] fetch NFTs failed:\(error)")
            }
        }
    }
    /*
     private func fetchFlowNFTs(_ offset: Int = 0) {
         buttonState = .loading
         guard let collection = selectedCollection else {
             fetchCollection()
             return
         }
         Task {
             do {
                 let address = WalletManager.shared.selectedAccountAddress
                 let request = NFTCollectionDetailListRequest(address: address, collectionIdentifier: collection.maskId, offset: offset, limit: 30)
                 let response: NFTListResponse = try await Network.request(FRWAPI.NFT.collectionDetailList(request, .main))
                 DispatchQueue.main.async {
                     if let list = response.nfts {
                         self.nfts = list.map { MoveNFTsViewModel.NFT(isSelected: false, model: $0) }
                     }
                     else {
                         self.nfts = []
                     }
                     self.isMock = false
                     self.resetButtonState()
                 }
             }
             catch {
                 DispatchQueue.main.async {
                     self.nfts = []
                     self.isMock = false
                     self.resetButtonState()
                 }
                 log.error("[MoveAsset] fetch NFTs failed:\(error)")
             }
         }
     }

     private func fetchEVMNFTs() {
         buttonState = .loading
         Task {
             do {
                 guard let address = EVMAccountManager.shared.selectedAccount?.showAddress else {
                     DispatchQueue.main.async {
                         self.resetButtonState()
                     }
                     return
                 }
                 let response: [EVMCollection] =  try await Network.request(FRWAPI.EVM.nfts(address))
                 DispatchQueue.main.async {
                     self.nfts = []
                     let sortedList = response.sorted(by: { $0.nfts.count > $1.nfts.count })
                     self.collectionList = sortedList
                     let collection = sortedList.first
                     self.selectedCollection = collection
                     self.nfts = collection?.nfts.map{ MoveNFTsViewModel.NFT(isSelected: false, model: $0) } ?? []

                     self.isMock = false
                     self.resetButtonState()
                 }
             }catch {
                 DispatchQueue.main.async {
                     self.nfts = []
                     self.isMock = false
                     self.resetButtonState()
                 }
                 log.error("[MoveAsset] fetch EVM collection & NFTs failed:\(error)")
             }
         }
     }
     */
}

extension MoveNFTsViewModel {
    private func emojiAccount(isFirst: Bool) -> WalletAccount.User {
        let address = accountAddress(isFirst: isFirst)
        return WalletManager.shared.walletAccount.readInfo(at: address)
    }

    func accountIcon(isFirst: Bool) -> some View {
        let contact = isFirst ? fromContact : toContact
        return HStack {
            if contact.walletType == .flow || contact.walletType == .evm {
                emojiAccount(isFirst: isFirst).emoji.icon(size: 20)
            } else {
                KFImage.url(URL(string: contact.avatar ?? ""))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 20, height: 20)
                    .cornerRadius(10)
            }
        }
    }

    func accountName(isFirst: Bool) -> String {
        return isFirst ? fromContact.displayName : toContact.displayName
    }

    func accountAddress(isFirst: Bool) -> String {
        return (isFirst ? fromContact.address : toContact.address) ?? ""
    }

    func showEVMTag(isFirst: Bool) -> Bool {
        if isFirst {
            return fromContact.walletType == .evm
        }
        return toContact.walletType == .evm
    }

    func logo() -> Image {
        let isSelectedEVM = EVMAccountManager.shared.selectedAccount != nil
        return isSelectedEVM ? Image("icon_qr_evm") : Image("Flow")
    }
}

extension MoveNFTsViewModel {
    struct NFT: Identifiable {
        let id: UUID = .init()
        var isSelected: Bool
        var model: NFTMask

        var imageUrl: String {
            return model.maskLogo
        }

        static func mock() -> MoveNFTsViewModel.NFT {
            MoveNFTsViewModel.NFT(isSelected: false, model: NFTResponse.mock())
        }
    }
}
