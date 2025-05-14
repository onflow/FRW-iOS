//
//  SelectCollectionViewModel.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import Foundation
import SwiftUI

// MARK: - SelectCollectionViewModel

class SelectCollectionViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        selectedItem: CollectionMask?,
        list: [CollectionMask]?,
        callback: @escaping (CollectionMask) -> Void?
    ) {
        self.selectedItem = selectedItem
        self.callback = callback

        if let list = list {
            self.list = list
        }

        if self.list.isEmpty {
            self.list = [NFTCollection.mock(), NFTCollection.mock(), NFTCollection.mock()]
            fetchList()
        }
    }

    // MARK: Internal

    @Published
    var list: [CollectionMask] = []
    @Published
    var selectedItem: CollectionMask?
    @Published
    var isMock = false

    var callback: (CollectionMask) -> Void?

    func fetchList() {
        Task {
            do {
                guard let account = WalletManager.shared.selectedAccount else {
                    return
                }
                let list: [NFTCollection] = try await Network
                    .request(FRWAPI.NFT.userCollection(
                        account.hexAddr,
                        account.vmType
                    ))
                await MainActor.run {
                    self.list = list
                    if self.selectedItem == nil {
                        self.selectedItem = self.list.first
                    }
                }
            } catch {
                log.error("[SelectCollection] fetch failed:\(error)")
            }
        }
    }

    func logo() -> Image {
        let isSelectedEVM = WalletManager.shared.isSelectedEVMAccount
        return isSelectedEVM ? Image("icon_qr_evm") : Image("Flow")
    }
}

extension SelectCollectionViewModel {
    func closeAction() {
        Router.dismiss()
    }

    func select(item: CollectionMask) {
        selectedItem = item
        confirmAction()
    }

    func confirmAction() {
        if let item = selectedItem {
            callback(item)
        }
        closeAction()
    }

    func isSelected(_ item: CollectionMask) -> Bool {
        item.maskContractName == selectedItem?.maskContractName && item.maskName == selectedItem?
            .maskName
    }
}
