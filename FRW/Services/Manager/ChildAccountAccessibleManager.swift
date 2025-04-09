//
//  ChildAccountAccessibleManager.swift
//  Flow Wallet
//
//  Created by cat on 2023/8/8.
//

import Foundation

extension ChildAccountManager {
    class AccessibleManager {
        // MARK: Internal

        var coins: [FlowModel.TokenInfo]?
        var collections: [String]?

        func fetchFT() async throws {
            guard let childAddr = childAddr, let parentAddr = parentAddr else {
                coins = []
                return
            }
            coins = try await FlowNetwork.fetchAccessibleFT(parent: parentAddr, child: childAddr)
        }

        func fetchNFT() async throws {
            guard let childAddr = childAddr, let parentAddr = parentAddr else {
                collections = []
                return
            }
            collections = try await FlowNetwork.fetchAccessibleCollection(
                parent: parentAddr,
                child: childAddr
            )
        }

        func isChildAccount() -> Bool {
            if parentAddr != nil, childAddr != nil {
                return true
            }
            return false
        }

        // check coin
        func isAccessible(_ model: TokenModel) -> Bool {
            guard isChildAccount() else {
                return true
            }
            let result = coins?.filter { info in

                guard let modelAddr = model.getAddress(),
                      let contractName = info.id.split(separator: ".")[safe: 2],
                      let address = info.id.split(separator: ".")[safe: 1]
                else {
                    return false
                }
                return contractName == model.contractName && modelAddr.hasSuffix(address)
            }
            return result?.count == 1
        }

        // check collection
        func isAccessible(_ model: NFTCollectionInfo) -> Bool {
            guard isChildAccount() else {
                return true
            }
            let result = collections?.filter { idStr in
                let list = idStr.split(separator: ".")
                if let contractName = list[safe: 2],
                   let address = list[safe: 1]
                {
                    if let name = model.contractName, let modelAddress = model.address {
                        return contractName == name && modelAddress.hasSuffix(address)
                    }
                    return false
                } else {
                    return false
                }
            }
            return result?.count == 1
        }

        // check nft
        func isAccessible(_ model: NFTModel) -> Bool {
            guard isChildAccount() else {
                return true
            }

            if let collection = model.collection {
                return isAccessible(collection)
            }

            if let address = model.response.contractAddress,
               let name = model.response.collectionContractName
            {
                return isAccessible(contractName: name, address: address)
            }

            return false
        }

        // MARK: Private

        private var parentAddr: String? {
            WalletManager.shared.getPrimaryWalletAddress()
        }

        private var childAddr: String? {
            WalletManager.shared.childAccount?.addr
        }

        private func isAccessible(contractName _: String, address: String) -> Bool {
            let result = collections?.filter { idStr in
                let list = idStr.split(separator: ".")
                if let contractName = list[safe: 2],
                   let addr = list[safe: 1]
                {
                    return contractName == contractName && address.hasSuffix(addr)
                } else {
                    return false
                }
            }
            return result?.count == 1
        }
    }
}
