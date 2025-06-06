//
//  LinkedAccountDetailViewModel.swift
//  FRW
//
//  Created by cat on 6/5/25.
//

import FlowWalletKit
import Foundation
import UIKit

@MainActor
class LinkedAccountDetailViewModel: ObservableObject {
    // MARK: Lifecycle

    init(childAccount: FlowWalletKit.ChildAccount) {
        self.childAccount = childAccount
        fetchCollections()
    }

    // MARK: Internal

    @Published
    var childAccount: FlowWalletKit.ChildAccount
    @Published
    var isPresent: Bool = false
    @Published
    var accessibleItems: [ChildAccountAccessible] = []

    @Published
    var isLoading: Bool = true

    @Published
    var showEmptyCollection: Bool = true

    var accessibleEmptyTitle: String {
        let title = "None Accessible "
        if tabIndex == 0 {
            return title + "collections".localized
        }
        return title + "coins_cap".localized
    }

    func copyAction() {
        UIPasteboard.general.string = childAccount.infoAddress
        HUD.success(title: "copied".localized)
    }

    func unlinkConfirmAction() {
        if checkUnlinkingTransactionIsProcessing() {
            return
        }

        if isPresent {
            isPresent = false
        }

        isPresent = true
    }

    func switchTab(index: Int) {
        tabIndex = index
        if index == 0 {
            if var list = collections {
                if !showEmptyCollection {
                    list = list.filter { !$0.isEmpty }
                }
                accessibleItems = list
            } else {
                fetchCollections()
            }
        } else if index == 1 {
            if let list = coins {
                accessibleItems = list
            } else {
                fetchCoins()
            }
        }
    }

    func doUnlinkAction() {
        if isUnlinking {
            return
        }

        isUnlinking = true

        Task {
            do {
                let txId = try await FlowNetwork.unlinkChildAccount(childAccount.infoAddress)
                let data = try JSONEncoder().encode(self.childAccount)
                let holder = TransactionManager.TransactionHolder(
                    id: txId,
                    type: .unlinkAccount,
                    data: data
                )

                TransactionManager.shared.newTransaction(holder: holder)
                self.isUnlinking = false
                self.isPresent = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    Router.pop()
                }
            } catch {
                log.error("unlink failed", context: error)
                DispatchQueue.main.async {
                    self.isUnlinking = false
                    self.isPresent = false
                }

                HUD.error(title: "request_failed".localized)
            }
        }
    }

    func switchEmptyCollection() {
        showEmptyCollection.toggle()
        switchTab(index: tabIndex)
    }

    // MARK: Private

    private var isUnlinking: Bool = false

    private var tabIndex: Int = 0
    private var collections: [ChildAccountAccessible]?
    private var coins: [ChildAccountAccessible]?

    private func checkChildAcountExist() -> Bool {
        ChildAccountManager.shared.childAccounts.contains(where: { $0.addr == childAccount.infoAddress })
    }

    private func checkUnlinkingTransactionIsProcessing() -> Bool {
        for holder in TransactionManager.shared.holders {
            if holder.type == .unlinkAccount, holder.internalStatus == .pending,
               let holderModel = try? JSONDecoder().decode(ChildAccount.self, from: holder.data),
               holderModel.addr == self.childAccount.infoAddress
            {
                return true
            }
        }

        return false
    }

    private func fetchCollections() {
        accessibleItems = [FlowModel.NFTCollection].mock(1)
        isLoading = true

        Task {
            let childAddr = self.childAccount.infoAddress
            guard let parent = UserManager.shared.mainAccount(by: childAddr)?.infoAddress else {
                await MainActor.run {
                    self.collections = []
                    self.accessibleItems = []
                }
                return
            }

            do {
                let result = try await FlowNetwork.fetchChildAccessibleCollectionList(
                    parent: parent,
                    child: childAddr
                )
                let response: [NFTCollection] = try await Network
                    .request(FRWAPI.NFT.userCollection(
                        childAddr,
                        .cadence
                    ))
                let collectionList = response

                var resultList: [NFTCollection] = result.compactMap { item in

                    if let contractName = item.id.split(separator: ".")[safe: 2] {
                        if let model = NFTCatalogCache.cache.find(by: String(contractName)) {
                            return NFTCollection(collection: model.collection, count: item.idList.count)
                        }
                    }
                    return nil
                }

                #if DEBUG
                    resultList = response
                #endif

                let tmpList = resultList.map { model in
                    var model = model
                    let collectionItem = collectionList.first(where: { item in
                        item.maskContractName == model.maskContractName && item.maskAddress == model
                            .maskAddress
                    })
                    if let item = collectionItem {
                        model.ids = item.ids
                        model.count = item.ids?.count ?? 0
                    }
                    return model
                }
                let res = tmpList.sorted { $0.count > $1.count }

                self.collections = res
                self.accessibleItems = self.collections ?? []
                self.isLoading = false
            } catch {
                log.error("\(error)")
                print("Error")
            }
        }
    }

    private func fetchCoins() {
        accessibleItems = [FlowModel.TokenInfo].mock(1)
        isLoading = true

        Task {
            let childAddr = self.childAccount.infoAddress
            guard let parent = UserManager.shared.mainAccount(by: childAddr)?.infoAddress
            else {
                self.coins = []
                self.accessibleItems = []
                return
            }

            let result = try await FlowNetwork.fetchAccessibleFT(parent: parent, child: childAddr)
            self.coins = result
            self.accessibleItems = result
            self.isLoading = false
        }
    }
}
