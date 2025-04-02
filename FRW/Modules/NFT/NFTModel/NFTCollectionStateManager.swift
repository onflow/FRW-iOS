//
//  NFTCollectionStateManager.swift
//  Flow Wallet
//
//  Created by cat on 2022/6/22.
//

import Flow
import Foundation

// MARK: - NFTCollectionStateManager

final class NFTCollectionStateManager {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let share = NFTCollectionStateManager()

    func fetch() async {
        guard let address = WalletManager.shared.walletInfo?.currentNetworkWalletModel?.getAddress,
              !address.isEmpty
        else {
            return
        }

        do {
            let result: [String: Int] = try await FlowNetwork.checkCollectionEnable(address: Flow.Address(hex: address))
            runOnMain {
                self.collectionStateList = result
            }
        } catch {
            log.error("[NFT] \(error)")
        }
    }

    func isCollectionAdd(_ info: NFTCollectionInfo) -> Bool {
        guard let contractAddress = info.address, let contractName = info.contractName else {
            return false
        }
        let contractId = "A." + contractAddress.stripHexPrefix() + "." + contractName
        let result = collectionStateList.filter { $0.key.lowercased().contains(contractId.lowercased()) }
        return !result.isEmpty
    }

    // MARK: Private

    private var collectionStateList: [String: Int] = [:]
}

// MARK: - NftCollectionState

struct NftCollectionState {
    var name: String
    var address: String
    var isAdded: Bool
}
