//
//  NFTCollectionStateManager.swift
//  Flow Wallet
//
//  Created by cat on 2022/6/22.
//

import Flow
import Foundation

final class NFTCollectionStateManager {
    static let share = NFTCollectionStateManager()

    private init() {}

    private var tokenStateList: [NftCollectionState] = []

    func fetch() async {
        let list = NFTCollectionConfig.share.config
        guard let address = WalletManager.shared.walletInfo?.currentNetworkWalletModel?.getAddress,
              !address.isEmpty
        else {
            return
        }

        do {
            let result: [String: Bool] = try await FlowNetwork.checkCollectionEnable(address: Flow.Address(hex: address))

            for (_, collection) in list.enumerated() {
                if let contractName = collection.contractName, let address = collection.address {
                    let key = "A." + address.stripHexPrefix() + "." + contractName
                    let isEnable = result[key] ?? false
                    if let oldIndex = tokenStateList.firstIndex(where: { $0.address.lowercased() == address.lowercased() && $0.name == collection.contractName }) {
                        tokenStateList.remove(at: oldIndex)
                    }
                    tokenStateList.append(NftCollectionState(name: contractName, address: address, isAdded: isEnable))
                }
            }
        } catch {
            debugPrint("NFTCollectionStateManager: \(error)")
        }
    }

    func isTokenAdded(_ address: String) -> Bool {
        tokenStateList.first { $0.address.lowercased() == address.lowercased() }?.isAdded ?? false
    }
}

struct NftCollectionState {
    var name: String
    var address: String
    var isAdded: Bool
}
