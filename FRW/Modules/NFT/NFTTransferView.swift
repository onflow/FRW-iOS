//
//  NFTTransferView.swift
//  Flow Wallet
//
//  Created by Selina on 25/8/2022.
//

import BigInt
import Flow
import Kingfisher
import SwiftUI
import Web3Core
import web3swift

// MARK: - NFTTransferViewModel

class NFTTransferViewModel: ObservableObject {
    
    enum AccountType {
        case flow
        case coa
        case eoa
        case linked

        var trackName: String {
            switch self {
            case .flow:
                "flow"
            case .coa:
                "coa"
            case .eoa:
                "evm"
            case .linked:
                "child"
            }
        }
    }
    
    // MARK: Lifecycle

    init(nft: NFTModel, targetContact: Contact, fromChildAccount: ChildAccount? = nil) {
        self.nft = nft
        self.targetContact = targetContact
        self.fromChildAccount = fromChildAccount
        checkNFTReachable()
        checkForInsufficientStorage()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onHolderChanged(noti:)),
            name: .transactionStatusDidChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Internal

    @Published
    var nft: NFTModel
    @Published
    var targetContact: Contact
    @Published
    var isValidNFT = true
    @Published
    var isEmptyTransation = true

    var fromChildAccount: ChildAccount?

    var fromTargetContent: Contact {
        if let account = fromChildAccount {
            let contact = Contact(
                address: account.showAddress,
                avatar: account.icon,
                contactName: account.aName,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName
            )
            return contact
        } else if let account = EVMAccountManager.shared.selectedAccount {
            let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
            let contact = Contact(
                address: account.showAddress,
                avatar: nil,
                contactName: user.name,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName,
                user: user
            )
            return contact
        } else if let account = ChildAccountManager.shared.selectedChildAccount {
            let contact = Contact(
                address: account.showAddress,
                avatar: account.icon,
                contactName: account.aName,
                contactType: .user,
                domain: nil,
                id: UUID().hashValue,
                username: account.showName
            )
            return contact
        } else {
            return UserManager.shared.userInfo!.toContactWithCurrentUserAddress()
        }
    }

    func checkNFTReachable() {
        guard let toAddress = targetContact.address else {
            return
        }
        if fromTargetContent.address == toAddress {
            isValidNFT = true
            return
        }
        if EVMAccountManager.shared.selectedAccount != nil,
           let identifier = nft.response.flowIdentifier {
            isValidNFT = true
            return
        }
        //TODO: get status result from toAddress by call `checkCollectionEnable`, and check state from `nft` on result list
//        let result = NFTCollectionStateManager.share.isTokenAdded(toAddress)
//        isValidNFT = result
    }

    func sendAction() {
        if TransactionManager.shared.isNFTTransfering(id: nft.id) {
            // TODO: show bottom sheet
            return
        }
        sendLogic()
//        Task {
//            let result = await SecurityManager.shared.SecurityVerify()
//            if result {
//                sendLogic()
//            }
//        }
    }

    func sendLogic() {
        if isRequesting {
            return
        }

        guard let toAddress = targetContact.address,
              let primaryAddress = WalletManager.shared.getPrimaryWalletAddress(),
              let currentAddress = WalletManager.shared
              .getWatchAddressOrChildAccountAddressOrPrimaryAddress()
        else {
            return
        }

        let failedBlock = {
            DispatchQueue.main.async {
                self.isRequesting = false
                HUD.error(title: "send_nft_failed".localized)
            }
        }

        isRequesting = true

        Task {
            do {
                var fromAccountType = WalletManager.shared.isSelectedEVMAccount ? AccountType.coa
                    :
                    (
                        ChildAccountManager.shared.selectedChildAccount == nil ? AccountType
                            .flow : AccountType.linked
                    )
                if fromChildAccount != nil {
                    fromAccountType = .linked
                }

                var toAccountType = toAddress.isEVMAddress ? AccountType.coa : AccountType.flow
                if toAccountType == .flow {
                    let isChild = ChildAccountManager.shared.childAccounts
                        .contains { $0.addr == toAddress }
                    if isChild {
                        toAccountType = .linked
                    }
                }

                if toAccountType == .coa,
                   toAddress != EVMAccountManager.shared.accounts.first?.showAddress {
                    toAccountType = .eoa
                }

                var tid: Flow.ID?
                switch (fromAccountType, toAccountType) {
                case (.flow, .flow):
                    tid = try await FlowNetwork.transferNFT(
                        to: Flow.Address(hex: toAddress),
                        nft: nft
                    )
                case (.flow, .coa):
                    let nftId = nft.response.id
                    let identifier = self.nft.collection?.flowIdentifier ?? nft.response
                        .flowIdentifier
                    guard let identifier, let IdInt = UInt64(nftId) else {
                        throw NFTError.sendInvalidAddress
                    }
                    tid = try await FlowNetwork.bridgeNFTToEVM(
                        identifier: identifier,
                        ids: [IdInt],
                        fromEvm: false
                    )
                case (.flow, .eoa):
                    log.debug("[NFT] flow to eoa send")
                    let nftId = nft.response.id
                    guard let nftAddress = self.nft.collection?.address,
                          let identifier = nft.collection?.flowIdentifier ?? nft.response
                          .flowIdentifier,
                          let toAddress = targetContact.address?.stripHexPrefix()
                    else {
                        throw NFTError.sendInvalidAddress
                    }
                    tid = try await FlowNetwork
                        .bridgeNFTToAnyEVM(
                            identifier: identifier,
                            id: nftId,
                            toAddress: toAddress
                        )
                case (.coa, .flow):
                    let nftId = nft.response.id
                    guard let identifier = nft.collection?.flowIdentifier ?? nft.response
                        .flowIdentifier
                    else {
                        throw NFTError.noCollectionInfo
                    }
                    if primaryAddress.lowercased() == toAddress.lowercased() {
                        guard let IdInt = UInt64(nftId) else {
                            throw NFTError.sendInvalidAddress
                        }

                        tid = try await FlowNetwork.bridgeNFTToEVM(
                            identifier: identifier,
                            ids: [IdInt],
                            fromEvm: true
                        )
                    } else {
                        tid = try await FlowNetwork.bridgeNFTFromEVMToAnyFlow(
                            identifier: identifier,
                            id: nftId,
                            receiver: toAddress
                        )
                    }
                case (.coa, .eoa):
                    // sendTransaction

                    let erc721 = try await FlowProvider.Web3.erc721NFTContract()
                    let nftId = nft.response.id
                    guard let coaAddress = EVMAccountManager.shared.accounts.first?.showAddress,
                          let evmContractAddress = self.nft.collection?.evmAddress
                    else {
                        throw NFTError.sendInvalidAddress
                    }
                    guard let data = erc721?.contract.method(
                        "safeTransferFrom",
                        parameters: [coaAddress, toAddress, nftId],
                        extraData: nil
                    ) else {
                        throw NFTError.sendInvalidAddress
                    }
                    log.debug("[NFT] nftID: \(nftId)")
                    log.debug("[NFT] data:\(data.hexString)")
                    tid = try await FlowNetwork.sendTransaction(
                        amount: "0",
                        data: data,
                        toAddress: evmContractAddress.stripHexPrefix(),
                        gas: WalletManager.defaultGas
                    )
                    log.debug("[NFT] tix:\(String(describing: tid))")
                case (.flow, .linked):
                    // parent to child user move 'transferNFTToChild'
                    guard let nftId = UInt64(nft.response.id),
                          let collection = nft.collection
                    else { throw NFTError.sendInvalidAddress }
                    guard let identifier = nft.response.flowIdentifier ?? nft.publicIdentifier else {
                        HUD.error(MoveError.invalidateIdentifier)
                        return
                    }
                    tid = try await FlowNetwork.moveNFTToChild(
                        nftId: nftId,
                        childAddress: toAddress,
                        identifier: identifier,
                        collection: collection
                    )
                case (.linked, .flow):
                    guard let nftId = UInt64(nft.response.id),
                          let collection = nft.collection
                    else { throw NFTError.sendInvalidAddress }
                    guard let identifier = nft.response.flowIdentifier ?? nft.publicIdentifier else {
                        HUD.error(MoveError.invalidateIdentifier)
                        return
                    }
                    let childAddr = fromChildAccount?.addr ?? currentAddress
                    if toAddress.lowercased() == primaryAddress.lowercased() {
                        tid = try await FlowNetwork.moveNFTToParent(
                            nftId: nftId,
                            childAddress: childAddr,
                            identifier: identifier,
                            collection: collection
                        )
                    } else {
                        tid = try await FlowNetwork.sendChildNFT(
                            nftId: nftId,
                            childAddress: childAddr,
                            toAddress: toAddress,
                            identifier: identifier,
                            collection: collection
                        )
                    }
                case (.linked, .linked):
                    guard let nftId = UInt64(nft.response.id),
                          let collection = nft.collection
                    else { throw NFTError.sendInvalidAddress }
                    guard let identifier = nft.response.flowIdentifier ?? nft.publicIdentifier else {
                        HUD.error(MoveError.invalidateIdentifier)
                        return
                    }
                    let childAddr = fromChildAccount?.addr ?? currentAddress
                    tid = try await FlowNetwork.sendChildNFTToChild(
                        nftId: nftId,
                        childAddress: childAddr,
                        toAddress: toAddress,
                        identifier: identifier,
                        collection: collection
                    )
                case (.linked, .coa):
                    guard let nftIdentifier = nft.response.flowIdentifier,
                          let nftId = UInt64(nft.response.id)
                    else {
                        return
                    }
                    let childAddr = fromChildAccount?.addr ?? currentAddress
                    tid = try await FlowNetwork
                        .bridgeChildNFTToEvm(
                            nft: nftIdentifier,
                            id: nftId,
                            child: childAddr
                        )
                case (.coa, .linked):
                    guard let nftIdentifier = nft.response.flowIdentifier,
                          let nftId = UInt64(nft.response.id)
                    else {
                        return
                    }
                    let childAddr = fromChildAccount?.addr ?? toAddress
                    tid = try await FlowNetwork
                        .bridgeChildNFTFromEvm(
                            nft: nftIdentifier,
                            id: nftId,
                            child: childAddr
                        )
                default:
                    failedBlock()
                    return
                }
                EventTrack.Transaction
                    .NFTTransfer(
                        from: currentAddress,
                        to: toAddress,
                        identifier: nft.response.flowIdentifier ?? "",
                        txId: tid?.hex ?? "",
                        fromType: fromAccountType.trackName,
                        toType: toAccountType.trackName,
                        isMove: false
                    )
                let model = NFTTransferModel(
                    nft: nft,
                    target: self.targetContact,
                    from: primaryAddress
                )
                guard let data = try? JSONEncoder().encode(model), let tid = tid else {
                    failedBlock()
                    return
                }

                DispatchQueue.main.async {
                    let holder = TransactionManager.TransactionHolder(
                        id: tid,
                        type: .transferNFT,
                        data: data
                    )
                    TransactionManager.shared.newTransaction(holder: holder)
                    HUD.dismissLoading()
                    Router.dismiss()
                    Router.pop()
                }
            } catch {
                debugPrint("NFTTransferViewModel -> sendAction error: \(error)")
                self.isRequesting = false
                failedBlock()
            }
        }
    }

    func checkTransaction() {
        isEmptyTransation = TransactionManager.shared.holders.count == 0
    }

    // MARK: Private

    private var isRequesting: Bool = false
    private var _insufficientStorageFailure: InsufficientStorageFailure?

    @objc
    private func onHolderChanged(noti _: Notification) {
        checkTransaction()
    }
}

// MARK: - InsufficientStorageToastViewModel

extension NFTTransferViewModel: InsufficientStorageToastViewModel {
    var variant: InsufficientStorageFailure? { _insufficientStorageFailure }
    
    private func checkForInsufficientStorage() {
        self._insufficientStorageFailure = insufficientStorageCheckForTransfer(token: .nft(self.nft))
    }
}

// MARK: - NFTTransferView

struct NFTTransferView: View {
    // MARK: Lifecycle

    init(nft: NFTModel, target: Contact, fromChildAccount: ChildAccount? = nil) {
        _vm = StateObject(wrappedValue: NFTTransferViewModel(
            nft: nft,
            targetContact: target,
            fromChildAccount: fromChildAccount
        ))
    }

    // MARK: Internal

    struct SendConfirmProgressView: View {
        // MARK: Internal

        var body: some View {
            HStack(spacing: 12) {
                ForEach(0..<totalNum, id: \.self) { index in
                    if step == index {
                        Image("icon-right-arrow-1")
                            .renderingMode(.template)
                            .foregroundColor(.Theme.Accent.green)
                    } else {
                        switch index {
                        case 0:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.Theme.Accent.green)
                        case 1:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.Theme.Accent.green)
                        case 2:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.Theme.Accent.green)
                        default:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.Theme.Accent.green)
                        }
                    }
                }
            }
            .onReceive(timer) { _ in
                DispatchQueue.main.async {
                    if step < totalNum - 1 {
                        step += 1
                    } else {
                        step = 0
                    }
                }
            }
        }

        // MARK: Private

        private let totalNum: Int = 7
        @State
        private var step: Int = 0
        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }

    @StateObject
    var vm: NFTTransferViewModel

    var body: some View {
        VStack(spacing: 0) {
            SheetHeaderView(title: "send_nft".localized)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    fromToView
                    NFTTransferView.SendConfirmProgressView()
                        .padding(.bottom, 37)
                }

                detailView
                    .padding(.top, 37)
                CalloutView(
                    corners: [.bottomLeading, .bottomTrailing],
                    content: "nft_send_collection_empty".localized
                )
                .padding(.horizontal, 12)
                .visibility(vm.isValidNFT ? .gone : .visible)
                .transition(.move(edge: .top))

                Spacer()

                sendActionView
            }
            .padding(.horizontal, 28)
        }
        .backgroundFill(Color.LL.Neutrals.background)
    }

    var fromToView: some View {
        HStack(spacing: 16) {
            contactView(contact: vm.fromTargetContent)
            Spacer()
            contactView(contact: vm.targetContact)
        }
    }

    var detailView: some View {
        HStack(alignment: .center, spacing: 13) {
            KFImage.url(vm.nft.imageURL)
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 8) {
                Text(vm.nft.title)
                    .foregroundColor(.LL.Neutrals.text)
                    .font(.inter(size: 14, weight: .bold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    KFImage.url(vm.nft.collection?.logoURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .cornerRadius(10)

                    Text(vm.nft.collection?.name ?? "")
                        .foregroundColor(.LL.Neutrals.neutrals7)
                        .font(.inter(size: 14, weight: .regular))

                    Image("flow")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 12, height: 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.LL.bgForIcon)
        .cornerRadius(16)
    }

    var sendActionView: some View {
        VStack(spacing: 0) {
            InsufficientStorageToastView<NFTTransferViewModel>()
                .environmentObject(self.vm)
            
            WalletSendButtonView(allowEnable: $vm.isEmptyTransation) {
                if vm.isEmptyTransation {
                    vm.sendAction()
                }
            }
        }
    }

    func contactView(contact: Contact) -> some View {
        VStack(spacing: 5) {
            // avatar
            ZStack {
                if contact.user?.emoji != nil {
                    contact.user?.emoji.icon(size: 44)
                } else if let avatar = contact.avatar?.convertedAvatarString(),
                          avatar.isEmpty == false {
                    KFImage.url(URL(string: avatar))
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                } else if contact.needShowLocalAvatar {
                    Image(contact.localAvatar ?? "")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                } else if let user = contact.user {
                    user.emoji.icon(size: 44)
                } else {
                    Text(String((contact.contactName?.first ?? "A").uppercased()))
                        .foregroundColor(.Theme.Accent.grey)
                        .font(.inter(size: 24, weight: .semibold))
                }
            }
            .frame(width: 44, height: 44)
            .background(.Theme.Accent.grey.opacity(0.16))
            .clipShape(Circle())

            // contact name
            Text(contact.user?.name ?? contact.contactName ?? contact.displayName)
                .foregroundColor(.LL.Neutrals.neutrals1)
                .font(.inter(size: 14, weight: .semibold))
                .lineLimit(1)

            // address
            Text(contact.address ?? "0x")
                .foregroundColor(.LL.Neutrals.note)
                .font(.inter(size: 12, weight: .regular))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}
