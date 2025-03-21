//
//  MoveNFTsViewModel.swift
//  FRW
//
//  Created by cat on 2024/5/17.
//

import Combine
import Flow
import Foundation
import Kingfisher
import SwiftUI

// MARK: - MoveNFTsViewModel

final class MoveNFTsViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        loadUserInfo()
        checkForInsufficientStorage()

        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterNFTs(query: searchText)
            }
            .store(in: &cancellables)
        $nfts
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.filterNFTs(query: self.searchText)
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    @Published
    private(set) var selectedCollection: CollectionMask?
    // NFTModel
    @Published
    private(set) var nfts: [MoveNFTsViewModel.NFT] = []

    @Published
    private(set) var showHint = false
    @Published
    private(set) var showFee = false

    @Published
    private(set) var buttonState: VPrimaryButtonState = .disabled

    let limitCount = 10

    @Published var searchText: String = ""
    @Published var loadingState: NFTLoadingState = .idle
    @Published var filteredNFTItems: [MoveNFTsViewModel.NFT] = []
    private var cancellables = Set<AnyCancellable>()
    @Published var loadedCount: Int = 0
    @Published var totalCount: Int = 0

    @Published
    private(set) var fromContact = Contact(
        address: "",
        avatar: "",
        contactName: "",
        contactType: nil,
        domain: nil,
        id: -1,
        username: nil
    ) {
        didSet {
            // Handle same account selection on from and to account
            // If so, we swap them
            if fromContact == toContact {
                toContact = oldValue
            }

            Task {
                await fetchCollection()
            }
        }
    }

    @Published
    private(set) var toContact = Contact(
        address: "",
        avatar: "",
        contactName: "",
        contactType: nil,
        domain: nil,
        id: -1,
        username: nil
    ) {
        didSet {
            // Handle same account selection on from and to account
            // If so, we swap them
            if toContact == fromContact {
                fromContact = oldValue
            }
        }
    }

    var selectedCount: Int {
        nfts.filter { $0.isSelected }.count
    }

    var moveButtonTitle: String {
        if selectedCount > 0 {
            return "move_nft_x".localized(String(selectedCount))
        }
        return "move_nft".localized
    }

    func updateToContact(_ contact: Contact) {
        toContact = contact
        updateFee()
        checkForInsufficientStorage()
    }

    func moveAction() {
        guard let collection = selectedCollection else {
            return
        }
        buttonState = .loading
        Task {
            do {
                guard let identifier = collection.maskFlowIdentifier ?? nfts.first?.model
                    .maskFlowIdentifier
                else {
                    HUD.error(MoveError.invalidateIdentifier)
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

                guard let nftCollection = collection as? NFTCollection else {
                    HUD.error(MoveError.invalidateNftCollectionInfo)
                    return
                }

                let nftCollectionInfo = nftCollection.collection

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

                var tid: Flow.ID?
                switch (fromContact.walletType, toContact.walletType) {
                case (.flow, .evm):
                    tid = try await FlowNetwork.bridgeNFTToEVM(
                        identifier: identifier,
                        ids: ids,
                        fromEvm: false
                    )
                case (.evm, .flow):
                    tid = try await FlowNetwork.bridgeNFTToEVM(
                        identifier: identifier,
                        ids: ids,
                        fromEvm: true
                    )
                case (.flow, .link):
                    tid = try await FlowNetwork.batchMoveNFTToChild(
                        childAddr: toAddress,
                        identifier: identifier,
                        ids: ids,
                        collection: nftCollectionInfo
                    )
                case (.link, .flow):
                    tid = try await FlowNetwork.batchMoveNFTToParent(
                        childAddr: fromAddress,
                        identifier: identifier,
                        ids: ids,
                        collection: nftCollectionInfo
                    )
                case (.link, .link):
                    tid = try await FlowNetwork.batchSendChildNFTToChild(
                        fromAddress: fromAddress,
                        toAddress: toAddress,
                        identifier: identifier,
                        ids: ids,
                        collection: nftCollectionInfo
                    )
                case (.link, .evm):
                    tid = try await FlowNetwork
                        .batchBridgeChildNFTToCoa(
                            nft: identifier,
                            ids: ids,
                            child: fromAddress
                        )
                case (.evm, .link):
                    tid = try await FlowNetwork
                        .batchBridgeChildNFTFromCoa(
                            nft: identifier,
                            ids: ids,
                            child: toAddress
                        )
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
        let vm = SelectCollectionViewModel(
            selectedItem: selectedCollection,
            list: collectionList
        ) { [weak self] item in
            DispatchQueue.main.async {
                self?.updateCollection(item: item)
            }
        }
        Router.route(to: RouteMap.NFT.selectCollection(vm))
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

    func fetchNFTs(_: Int = 0) async {
        guard let collection = selectedCollection else {
            return
        }
        guard let from = FWAddressDector.create(address: fromContact.address) else {
            return
        }

        await MainActor.run {
            self.buttonState = .loading
            self.loadingState = .loading
        }

        do {
            let result = try await TokenBalanceHandler.shared.getAllNFTsUnderCollection(address: from, collectionIdentifier: collection.maskId) { cur, total in
                runOnMain {
                    self.loadedCount = cur
                    self.totalCount = total
                }
            }

            await MainActor.run {
                self.nfts = result.map { MoveNFTsViewModel.NFT(isSelected: false, model: $0) }
                self.loadingState = .success
                self.resetButtonState()
            }
        } catch {
            await MainActor.run {
                self.nfts = []
                self.loadingState = .failure(error)
                self.resetButtonState()
            }
            log.error("[MoveAsset] fetch NFTs failed:\(error)")
        }
    }

    func handleFromContact(_: Contact) {
        let model = MoveAccountsViewModel(
            selected: fromContact.address ?? ""
        ) { newContact in
            if let contact = newContact {
                self.fromContact = contact
            }
        }
        Router.route(to: RouteMap.Wallet.chooseChild(model))
    }

    func handleToContact(_: Contact) {
        let model = MoveAccountsViewModel(
            selected: toContact.address ?? ""
        ) { newContact in
            if let contact = newContact {
                self.toContact = contact
            }
        }
        Router.route(to: RouteMap.Wallet.chooseChild(model))
    }

    func handleSwap() {
        Task { @MainActor in
            (self.fromContact, self.toContact) = (self.toContact, self.fromContact)
        }
    }

    // MARK: Private

    private var collectionList: [CollectionMask] = []
    private var _insufficientStorageFailure: InsufficientStorageFailure?

    private func loadUserInfo() {
        guard let primaryAddr = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress()
        else {
            return
        }
        if let account = ChildAccountManager.shared.selectedChildAccount {
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
            .selectedAccount != nil
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

        updateFee()
    }

    private func updateFee() {
        showFee = !(fromContact.walletType == .link || toContact.walletType == .link)
    }

    private func updateCollection(item: CollectionMask) {
        if item.maskId == selectedCollection?.maskId,
           item.maskContractName == selectedCollection?.maskContractName
        {
            return
        }
        selectedCollection = item

        nfts = []
        Task {
            await fetchNFTs()
        }
    }

    private func resetButtonState() {
        buttonState = selectedCount > 0 ? .enabled : .disabled
        showHint = selectedCount >= limitCount
    }

    private func fetchCollection() async {
        do {
            guard let from = FWAddressDector.create(address: fromContact.address) else {
                return
            }

            await MainActor.run {
                self.loadingState = .loading
            }

            let list = try await TokenBalanceHandler.shared.getNFTCollections(address: from)

            if list.isEmpty {
                await MainActor.run {
                    self.nfts = []
                    self.loadingState = .success
                    self.resetButtonState()
                }
                return
            }

            await MainActor.run {
                self.collectionList = list
                self.selectedCollection = self.collectionList.first
            }

            await fetchNFTs()

        } catch {
            log.error("[MoveAsset] fetch Collection failed:\(error)")
        }
    }
}

// MARK: InsufficientStorageToastViewModel

extension MoveNFTsViewModel: InsufficientStorageToastViewModel {
    var variant: InsufficientStorageFailure? { _insufficientStorageFailure }

    private func checkForInsufficientStorage() {
        _insufficientStorageFailure = insufficientStorageCheckForMove(
            token: .nft(nil),
            from: fromContact.walletType,
            to: toContact.walletType
        )
    }
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
        isFirst ? fromContact.displayName : toContact.displayName
    }

    func accountAddress(isFirst: Bool) -> String {
        (isFirst ? fromContact.address : toContact.address) ?? ""
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

// MARK: MoveNFTsViewModel.NFT

extension MoveNFTsViewModel {
    struct NFT: Identifiable {
        let id: UUID = .init()
        var isSelected: Bool
        var model: NFTMask

        var imageUrl: String {
            model.maskLogo
        }

        static func mock() -> MoveNFTsViewModel.NFT {
            MoveNFTsViewModel.NFT(isSelected: false, model: NFTResponse.mock())
        }
    }
}

extension MoveNFTsViewModel {
    private func filterNFTs(query: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                if query.isEmpty {
                    self.filteredNFTItems = self.nfts
                } else {
                    self.filteredNFTItems = self.nfts.filter {
                        let name = $0.model.maskSearchContent
                        return name.lowercased().contains(query.lowercased())
                    }
                    log.debug("\(self.filteredNFTItems)")
                }
            }
        }
    }

    func retry() {
        Task {
            await fetchNFTs()
        }
    }
}
