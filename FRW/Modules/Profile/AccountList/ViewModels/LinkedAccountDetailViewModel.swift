//
//  LinkedAccountDetailViewModel.swift
//  FRW
//
//  Created by cat on 11/28/25.
//

import Combine
import Foundation
import SwiftUI

// MARK: - LinkedAccountDetailViewModel

@MainActor
class LinkedAccountDetailViewModel: ObservableObject {
    // MARK: Lifecycle

    init(account: Binding<WalletAccount>) {
        self._account = account
        fetchCollections()
    }

    // MARK: Internal

    @Binding
    var account: WalletAccount

    @Published
    var accessibleItems: [ChildAccountAccessible] = []

    @Published
    var isLoading: Bool = true

    @Published
    var showEmptyCollection: Bool = true

    @Published
    var tabIndex: Int = 0

    var accessibleEmptyTitle: String {
        let title = "None Accessible "
        if tabIndex == 0 {
            return title + "collections".localized
        }
        return title + "coins_cap".localized
    }

    var childAddress: String? {
        account.address
    }

    func copyAction() {
        UIPasteboard.general.string = account.address
        HUD.success(title: "copied".localized)
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

    func switchEmptyCollection() {
        showEmptyCollection.toggle()
        switchTab(index: tabIndex)
    }

    func onCollectionClick(_ item: ChildAccountAccessible) {
        guard let collectionInfo = item as? NFTCollection,
              !collectionInfo.isEmpty,
              let pathId = collectionInfo.collection.path?.storagePathId()
        else {
            return
        }

      let childAccount = ChildAccount(
        address: account.address,
        name: account.displayName,
        desc: account.childInfo?.desc,
        icon: NFTCatalogCache.cache
          .find(by: collectionInfo.collection.contractName ?? "")?.collection.logoURL.absoluteString,
        pinTime: 0
      )

        Router.route(to: RouteMap.NFT.collectionDetail(
            account.address,
            pathId,
            childAccount
        ))
    }

    // MARK: Private

    private var collections: [ChildAccountAccessible]?
    private var coins: [ChildAccountAccessible]?

    private func fetchCollections() {
        accessibleItems = [FlowModel.NFTCollection].mock(1)
        isLoading = true

        Task {
          guard let parent = account.parent?.address else {
                self.collections = []
                self.accessibleItems = []
                self.isLoading = false
                return
            }

            let child = account.address

            do {
                let result = try await FlowNetwork.fetchAccessibleCollection(
                    parent: parent,
                    child: child
                )
                let response: [NFTCollection] = try await Network
                    .request(FRWAPI.NFT.userCollection(
                        child,
                        .cadence
                    ))
                let collectionList = response

                let resultList: [NFTCollection] = result.compactMap { item in
                    if let contractName = item.split(separator: ".")[safe: 2] {
                        if let model = NFTCatalogCache.cache.find(by: String(contractName)) {
                            return NFTCollection(collection: model.collection, count: 0)
                        }
                    }
                    return nil
                }

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
                if self.showEmptyCollection {
                    self.accessibleItems = res
                } else {
                    self.accessibleItems = res.filter { !$0.isEmpty }
                }
                self.isLoading = false
            } catch {
                log.error("fetchCollections failed", context: error)
                self.collections = []
                self.accessibleItems = []
                self.isLoading = false
            }
        }
    }

    private func fetchCoins() {
        accessibleItems = [FlowModel.TokenInfo].mock(1)
        isLoading = true

        Task {
          guard let parent = account.parent?.address else {
                self.coins = []
                self.accessibleItems = []
                self.isLoading = false
                return
            }

            let child = account.address

            do {
                let result = try await FlowNetwork.fetchAccessibleFT(parent: parent, child: child)
                self.coins = result
                self.accessibleItems = result
                self.isLoading = false
            } catch {
                log.error("fetchCoins failed", context: error)
                self.coins = []
                self.accessibleItems = []
                self.isLoading = false
            }
        }
    }
}
