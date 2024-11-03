//
//  FlowNetwork.swift
//  Flow Wallet
//
//  Created by Hao Fu on 30/4/2022.
//

import BigInt
import Combine
import Flow
import Foundation
import Web3Core

enum FlowNetwork {
    static func setup() {
        let type = LocalUserDefaults.shared.flowNetwork.toFlowType()
        log.debug("did setup flow chainID to \(LocalUserDefaults.shared.flowNetwork.rawValue)")
        flow.configure(chainID: type)
    }
}

// MARK: - Token

extension FlowNetwork {
    static func checkTokensEnable(address: Flow.Address) async throws -> [String: Bool] {
        let cadence = CadenceManager.shared.current.ft?.isTokenListEnabled?.toFunc() ?? ""
        return try await fetch(at: address, by: cadence)
    }

    static func fetchBalance(at address: Flow.Address) async throws -> [String: Double] {
        let cadence = CadenceManager.shared.current.ft?.getTokenListBalance?.toFunc() ?? ""
        return try await fetch(at: address, by: cadence)
    }

    static func enableToken(at address: Flow.Address, token: TokenModel) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.ft?.addToken?.toFunc() ?? ""
        let cadenceString = token.formatCadence(cadence: originCadence)
        let fromKeyIndex = WalletManager.shared.keyIndex

        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners) {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }

            gasLimit {
                9999
            }
        }
    }

    static func transferToken(to address: Flow.Address, amount: Decimal, token: TokenModel) async throws -> Flow.ID {
        let cadenceString = TokenCadence.tokenTransfer(token: token, at: flow.chainID)
        let currentAdd = WalletManager.shared.getPrimaryWalletAddress() ?? ""
        let keyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: Flow.Address(hex: currentAdd), keyIndex: keyIndex)
            }

            authorizers {
                Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
            }

            arguments {
                [.ufix64(amount), .address(address)]
            }

            gasLimit {
                9999
            }
        })
    }

    static func minFlowBalance() async throws -> Double {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let cadenceString = CadenceManager.shared.current.basic?.getAccountMinFlow?.toFunc() ?? ""
        let result: Decimal = try await fetch(cadence: cadenceString, arguments: [.address(Flow.Address(hex: fromAddress))])
        return result.doubleValue
    }
}

// MARK: - NFT

extension FlowNetwork {
    static func checkCollectionEnable(address: Flow.Address) async throws -> [String: Bool] {
        let originCadence = CadenceManager.shared.current.nft?.checkNFTListEnabled?.toFunc() ?? ""
        let cadence = originCadence.replace(by: ScriptAddress.addressMap())
//        let cadence = NFTCadence.collectionListCheckEnabled(with: list, on: flow.chainID)
        let result: [String: Bool] = try await fetch(at: address, by: cadence)
        return result
    }

    static func addCollection(at address: Flow.Address, collection: NFTCollectionInfo) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.collection?.enableNFTStorage?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: originCadence)
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }

            gasLimit {
                9999
            }
        })
    }

    static func transferNFT(to address: Flow.Address, nft: NFTModel) async throws -> Flow.ID {
        var nftCollection = nft.collection
        if nftCollection == nil {
            nftCollection = await NFTCollectionConfig.share.get(from: nft.response.contractAddress ?? "")
        }

        guard let collection = nftCollection else {
            throw NFTError.noCollectionInfo
        }

        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }

        guard let tokenIdInt = UInt64(nft.response.id) else {
            throw NFTError.invalidTokenId
        }

        var nftTransfer = CadenceManager.shared.current.collection?.sendNFT?.toFunc() ?? ""
        let nbaNFTTransfer = CadenceManager.shared.current.collection?.sendNbaNFT?.toFunc() ?? ""
        let result = CadenceManager.shared.current.version?.compareVersion(to: "1.0.0")
        if result != .orderedAscending {
            nftTransfer = CadenceManager.shared.current.collection?.sendNFT?.toFunc() ?? ""
        }

        let cadenceString = collection.formatCadence(script: nft.isNBA ? nbaNFTTransfer : nftTransfer)
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: Flow.Address(hex: fromAddress), keyIndex: fromKeyIndex)
            }

            authorizers {
                Flow.Address(hex: fromAddress)
            }

            arguments {
                [.address(address), .uint64(tokenIdInt)]
            }

            gasLimit {
                9999
            }
        })
    }
}

// MARK: - Search

extension FlowNetwork {
    static func queryAddressByDomainFind(domain: String) async throws -> String {
        let cadence = CadenceManager.shared.current.basic?.getFindAddress?.toFunc() ?? ""
        return try await fetch(cadence: cadence, arguments: [.string(domain)])
    }

    static func queryAddressByDomainFlowns(domain: String, root: String = "fn") async throws -> String {
        let cadence = CadenceManager.shared.current.basic?.getFlownsAddress?.toFunc() ?? ""

        let realDomain = domain
            .replacingOccurrences(of: ".fn", with: "")
            .replacingOccurrences(of: ".meow", with: "")
        return try await fetch(cadence: cadence, arguments: [.string(realDomain), .string(root)])
    }
}

// MARK: - Inbox

extension FlowNetwork {
    static func claimInboxToken(domain: String, key: String, coin: TokenModel, amount: Decimal, root: String = Contact.DomainType.meow.domain) async throws -> Flow.ID {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let cadenceString = coin.formatCadence(cadence: CadenceManager.shared.current.domain?.claimFTFromInbox?.toFunc() ?? "")
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: Flow.Address(hex: address), keyIndex: fromKeyIndex)
            }

            authorizers {
                Flow.Address(hex: address)
            }

            arguments {
                [.string(domain), .string(root), .string(key), .ufix64(amount)]
            }

            gasLimit {
                9999
            }
        })
    }

    static func claimInboxNFT(domain: String, key: String, collection: NFTCollectionInfo, itemId: UInt64, root: String = Contact.DomainType.meow.domain) async throws -> Flow.ID {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let cadenceString = collection.formatCadence(script: CadenceManager.shared.current.domain?.claimNFTFromInbox?.toFunc() ?? "")
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: Flow.Address(hex: address), keyIndex: fromKeyIndex)
            }

            authorizers {
                Flow.Address(hex: address)
            }

            arguments {
                [.string(domain), .string(root), .string(key), .uint64(itemId)]
            }

            gasLimit {
                9999
            }
        })
    }
}

// MARK: - Swap

extension FlowNetwork {
    static func swapToken(swapPaths: [String], tokenInMax: Decimal, tokenOutMin: Decimal, tokenInVaultPath: String, tokenOutSplit: [Decimal], tokenInSplit: [Decimal], tokenOutVaultPath: String, tokenOutReceiverPath: String, tokenOutBalancePath: String, deadline: Decimal, isFrom: Bool) async throws -> Flow.ID {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }

        let tokenName = String(swapPaths.last?.split(separator: ".").last ?? "")
        let tokenAddress = String(swapPaths.last?.split(separator: ".")[1] ?? "").addHexPrefix()

        let fromCadence = CadenceManager.shared.current.swap?.SwapExactTokensForTokens?.toFunc() ?? ""
        let toCadence = CadenceManager.shared.current.swap?.SwapTokensForExactTokens?.toFunc() ?? ""
        var cadenceString = isFrom ? fromCadence : toCadence
        cadenceString = cadenceString
            .replace(by: ["Token1Name": tokenName, "Token1Addr": tokenAddress])
            .replace(by: ScriptAddress.addressMap())
        log.error("[Cadence] swap from:\n \(cadenceString)")
        var args = [Flow.Cadence.FValue]()
        args.append(.array(swapPaths.map { .string($0) }))

        if isFrom {
            args.append(.array(tokenInSplit.map { .ufix64($0) }))
            args.append(.ufix64(tokenOutMin))
        } else {
            args.append(.array(tokenOutSplit.map { .ufix64($0) }))
            args.append(.ufix64(tokenInMax))
        }

        args.append(.ufix64(deadline))
        args.append(.path(Flow.Argument.Path(domain: "storage", identifier: tokenInVaultPath)))
        args.append(.path(Flow.Argument.Path(domain: "storage", identifier: tokenOutVaultPath)))
        args.append(.path(Flow.Argument.Path(domain: "public", identifier: tokenOutReceiverPath)))
        args.append(.path(Flow.Argument.Path(domain: "public", identifier: tokenOutBalancePath)))
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: Flow.Address(hex: address), keyIndex: fromKeyIndex)
            }

            authorizers {
                Flow.Address(hex: address)
            }

            arguments {
                args
            }

            gasLimit {
                9999
            }
        })
    }
}

// MARK: - Stake

enum LilicoError: Error {
    case emptyWallet
}

extension FlowNetwork {
    static func stakingIsEnabled() async throws -> Bool {
        let cadence = CadenceManager.shared.current.staking?.checkStakingEnabled?.toFunc() ?? ""
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        return try await fetch(cadence: cadence, arguments: [])
    }

    static func accountStakingIsSetup() async throws -> Bool {
        let cadence = CadenceManager.shared.current.staking?.checkSetup?.toFunc() ?? ""
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        return try await fetch(cadence: cadence, arguments: [.address(address)])
    }

    static func claimUnstake(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        guard let walletAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LilicoError.emptyWallet
        }

        let address = Flow.Address(hex: walletAddress)
        let cadenceOrigin = CadenceManager.shared.current.staking?.withdrawUnstaked?.toFunc() ?? ""
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners) {
            cadence {
                cadenceOrigin.replace(by: ScriptAddress.addressMap())
            }

            arguments {
                [.string(nodeID), .uint32(UInt32(delegatorId)), .ufix64(amount)]
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }
        }
    }

    static func reStakeUnstake(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        guard let walletAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LilicoError.emptyWallet
        }

        let address = Flow.Address(hex: walletAddress)
        let cadenceOrigin = CadenceManager.shared.current.staking?.restakeUnstaked?.toFunc() ?? ""
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners) {
            cadence {
                cadenceOrigin.replace(by: ScriptAddress.addressMap())
            }

            arguments {
                [.string(nodeID), .uint32(UInt32(delegatorId)), .ufix64(amount)]
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }
        }
    }

    static func claimReward(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        guard let walletAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LilicoError.emptyWallet
        }

        let address = Flow.Address(hex: walletAddress)
        let cadenceOrigin = CadenceManager.shared.current.staking?.withdrawReward?.toFunc() ?? ""
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners) {
            cadence {
                cadenceOrigin.replace(by: ScriptAddress.addressMap())
            }

            arguments {
                [.string(nodeID), .uint32(UInt32(delegatorId)), .ufix64(amount)]
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }
        }
    }

    static func reStakeReward(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        guard let walletAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LilicoError.emptyWallet
        }

        let address = Flow.Address(hex: walletAddress)
        let cadenceOrigin = CadenceManager.shared.current.staking?.restakeReward?.toFunc() ?? ""
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners) {
            cadence {
                cadenceOrigin.replace(by: ScriptAddress.addressMap())
            }

            arguments {
                [.string(nodeID), .uint32(UInt32(delegatorId)), .ufix64(amount)]
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }
        }
    }

    static func setupAccountStaking() async throws -> Bool {
        let cadenceOrigin = CadenceManager.shared.current.staking?.setup?.toFunc() ?? ""
        let cadenceString = cadenceOrigin.replace(by: ScriptAddress.addressMap())

        guard let walletAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LilicoError.emptyWallet
        }
        let address = Flow.Address(hex: walletAddress)
        let fromKeyIndex = WalletManager.shared.keyIndex
        let txId = try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }
        })

        let result = try await txId.onceSealed()

        if result.isFailed {
            debugPrint("FlowNetwork: setupAccountStaking failed msg: \(result.errorMessage)")
            return false
        }

        return true
    }

    static func createDelegatorId(providerId: String, amount: Double = 0) async throws -> Flow.ID {
        let cadenceOrigin = CadenceManager.shared.current.staking?.createDelegator?.toFunc() ?? ""
        let cadenceString = cadenceOrigin.replace(by: ScriptAddress.addressMap())
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let fromKeyIndex = WalletManager.shared.keyIndex
        let txId = try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }

            arguments {
                [.string(providerId), .ufix64(Decimal(amount))]
            }

            gasLimit {
                9999
            }
        })
        return txId
    }

    static func stakeFlow(providerId: String, delegatorId: Int, amount: Double) async throws -> Flow.ID {
        let cadenceOrigin = CadenceManager.shared.current.staking?.createStake?.toFunc() ?? ""
        let cadenceString = cadenceOrigin.replace(by: ScriptAddress.addressMap())
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let fromKeyIndex = WalletManager.shared.keyIndex
        let txId = try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }

            arguments {
                [.string(providerId), .uint32(UInt32(delegatorId)), .ufix64(Decimal(amount))]
            }

            gasLimit {
                9999
            }
        })

        return txId
    }

    static func unstakeFlow(providerId: String, delegatorId: Int, amount: Double) async throws -> Flow.ID {
        let cadenceOrigin = CadenceManager.shared.current.staking?.unstake?.toFunc() ?? ""
        let cadenceString = cadenceOrigin.replace(by: ScriptAddress.addressMap())
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let fromKeyIndex = WalletManager.shared.keyIndex
        let txId = try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }

            arguments {
                [.string(providerId), .uint32(UInt32(delegatorId)), .ufix64(Decimal(amount))]
            }

            gasLimit {
                9999
            }
        })

        return txId
    }

    static func queryStakeInfo() async throws -> [StakingNode]? {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let cadence = CadenceManager.shared.current.staking?.getDelegatesInfoArray?.toFunc() ?? ""
        let response: [StakingNode] = try await fetch(at: address, by: cadence)
        debugPrint("FlowNetwork -> queryStakeInfo, response = \(response)")
        return response
    }

    static func getStakingApyByWeek() async throws -> Double {
        let candence = CadenceManager.shared.current.staking?.getApyWeekly?.toFunc() ?? ""
        let result: Decimal = try await fetch(cadence: candence, arguments: [])

        return result.doubleValue
    }

    static func getStakingApyByYear() async throws -> Double {
        let candence = CadenceManager.shared.current.staking?.getApr?.toFunc() ?? ""
        let result: Decimal = try await fetch(cadence: candence, arguments: [])

        return result.doubleValue
    }

    static func getDelegatorInfo() async throws -> [String: Int]? {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let cadence = CadenceManager.shared.current.staking?.getDelegatesIndo?.toFunc() ?? ""
        let replacedCadence = cadence.replace(by: ScriptAddress.addressMap())
        let rawResponse = try await flow.accessAPI.executeScriptAtLatestBlock(script: Flow.Script(text: replacedCadence),
                                                                              arguments: [.address(address)])

        let response = try JSONDecoder().decode(StakingDelegatorInner.self, from: rawResponse.data)
        debugPrint("FlowNetwork -> getDelegatorInfo, response = \(response)")

        guard let values = response.value?.value else {
            return nil
        }

        let compactValues = values.compactMap { $0 }

        var results: [String: Int] = [:]
        for value in compactValues {
            if let resultKey = value.key?.value {
                let resultValue = Int(value.value?.value?.first??.key?.value ?? "0") ?? 0
                results[resultKey] = resultValue
            }
        }

        return results
    }
}

// MARK: - Child Account

extension FlowNetwork {
    static func queryChildAccountList() async throws -> [String] {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let cadence = CadenceManager.shared.current.hybridCustody?.getChildAccount?.toFunc() ?? ""
        let response: [String] = try await fetch(at: address, by: cadence)
        return response
    }

    static func unlinkChildAccount(_ address: String) async throws -> Flow.ID {
        let cadenceOrigin = CadenceManager.shared.current.hybridCustody?.unlinkChildAccount?.toFunc() ?? ""
        let cadenceString = cadenceOrigin.replace(by: ScriptAddress.addressMap())
        let walletAddress = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let fromKeyIndex = WalletManager.shared.keyIndex
        let txId = try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: walletAddress, keyIndex: fromKeyIndex)
            }

            authorizers {
                walletAddress
            }

            arguments {
                [.address(Flow.Address(hex: address))]
            }

            gasLimit {
                9999
            }
        })

        return txId
    }

    static func queryChildAccountMeta(_ address: String) async throws -> [ChildAccount] {
        let address = Flow.Address(hex: address)
        let cadence = CadenceManager.shared.current.hybridCustody?.getChildAccountMeta?.toFunc() ?? ""
        let replacedCadence = cadence.replace(by: ScriptAddress.addressMap())
        let rawResponse = try await flow.accessAPI.executeScriptAtLatestBlock(script: Flow.Script(text: replacedCadence),
                                                                              arguments: [.address(address)])

        guard let decode = rawResponse.decode() as? [String: Any?] else {
            return []
        }

        let result: [ChildAccount] = decode.keys.compactMap { key in
            guard let value = decode[key],
                  let value = value,
                  let data = try? JSONSerialization.data(withJSONObject: value),
                  var model = try? JSONDecoder().decode(ChildAccount.self, from: data)
            else {
                return ChildAccount(address: key, name: nil, desc: nil, icon: nil, pinTime: 0)
            }

            model.addr = key
            return model
        }

        return result
    }

    static func editChildAccountMeta(_ address: String, name: String, desc: String, thumbnail: String) async throws -> Flow.ID {
        let editChildAccount = CadenceManager.shared.current.hybridCustody?.editChildAccount?.toFunc() ?? ""
        let cadenceString = editChildAccount.replace(by: ScriptAddress.addressMap())
        let walletAddress = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let fromKeyIndex = WalletManager.shared.keyIndex
        let txId = try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                cadenceString
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: walletAddress, keyIndex: fromKeyIndex)
            }

            authorizers {
                walletAddress
            }

            arguments {
                [.address(Flow.Address(hex: address)), .string(name), .string(desc), .string(thumbnail)]
            }

            gasLimit {
                9999
            }
        })

        return txId
    }

    static func fetchAccessibleCollection(parent: String, child: String) async throws -> [String] {
        let cadence = CadenceManager.shared.current.hybridCustody?.getChildAccountAllowTypes?.toFunc() ?? ""
        let cadenceString = cadence.replace(by: ScriptAddress.addressMap())
        let parentAddress = Flow.Address(hex: parent)
        let childAddress = Flow.Address(hex: child)
        let response = try await flow.accessAPI
            .executeScriptAtLatestBlock(script: Flow.Script(text: cadenceString), arguments: [.address(parentAddress), .address(childAddress)])
        let result = try response.decode([String].self)
        return result
    }

    static func fetchAccessibleFT(parent: String, child: String) async throws -> [FlowModel.TokenInfo] {
        let accessible = CadenceManager.shared.current.hybridCustody?.getAccessibleCoinInfo?.toFunc() ?? ""
        let cadenceString = accessible.replace(by: ScriptAddress.addressMap())
        let parentAddress = Flow.Address(hex: parent)
        let childAddress = Flow.Address(hex: child)
        let response = try await flow.accessAPI
            .executeScriptAtLatestBlock(script: Flow.Script(text: cadenceString), arguments: [.address(parentAddress), .address(childAddress)])
            .decode([FlowModel.TokenInfo].self)
        return response
    }

    // on child, move nft to parent
    static func moveNFTToParent(nftId: UInt64, childAddress: String, identifier: String, collection: NFTCollectionInfo) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.transferChildNFT?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: accessible)
        let childAddress = Flow.Address(hex: childAddress)
        return try await sendTransaction(cadenceStr: cadenceString, argumentList: [.address(childAddress), .string(identifier), .uint64(nftId)])
    }

    // on parent， move nft to child
    static func moveNFTToChild(nftId: UInt64, childAddress: String, identifier: String, collection: NFTCollectionInfo) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.transferNFTToChild?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: accessible)
        return try await sendTransaction(cadenceStr: cadenceString, argumentList: [.address(Flow.Address(hex: childAddress)), .string(identifier), .uint64(nftId)])
    }

    // send NFT from child to other wallet
    static func sendChildNFT(nftId: UInt64, childAddress: String, toAddress: String, identifier: String, collection: NFTCollectionInfo) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.sendChildNFT?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: accessible)
        let childAddr = Flow.Address(hex: childAddress)
        let toAddr = Flow.Address(hex: toAddress)
        return try await sendTransaction(cadenceStr: cadenceString, argumentList: [.address(childAddr), .address(toAddr), .string(identifier), .uint64(nftId)])
    }

    // Send NFT from child to child
    static func sendChildNFTToChild(nftId: UInt64, childAddress: String, toAddress: String, identifier: String, collection: NFTCollectionInfo) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.sendChildNFTToChild?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: accessible)
        let childAddr = Flow.Address(hex: childAddress)
        let toAddr = Flow.Address(hex: toAddress)
        return try await sendTransaction(cadenceStr: cadenceString, argumentList: [.address(childAddr), .address(toAddr), .string(identifier), .uint64(nftId)])
    }

    static func linkedAccountEnabledTokenList(address: String) async throws -> [String: Bool] {
        let cadence = CadenceManager.shared.current.ft?.isLinkedAccountTokenListEnabled?.toFunc() ?? ""
        return try await fetch(at: Flow.Address(hex: address), by: cadence)
    }

    static func checkChildLinkedCollections(parent: String, child: String, identifier: String, collection _: NFTCollectionInfo) async throws -> Bool {
        let cadence = CadenceManager.shared.current.hybridCustody?.checkChildLinkedCollections?.toFunc() ?? ""
        let cadenceString = cadence.replace(by: ScriptAddress.addressMap())
        let parentAddress = Flow.Address(hex: parent)
        let childAddress = Flow.Address(hex: child)
        let response = try await flow.accessAPI
            .executeScriptAtLatestBlock(script: Flow.Script(text: cadenceString),
                                        arguments: [
                                            .address(parentAddress),
                                            .address(childAddress),
                                            .string(identifier),
                                        ])
        let result = try response.decode(Bool.self)
        return result
    }

    static func batchMoveNFTToParent(childAddr address: String, identifier: String, ids: [UInt64], collection: NFTCollectionInfo) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.batchTransferChildNFT?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: accessible)
        let childAddress = Flow.Address(hex: address)
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }

        let ident = identifier.split(separator: "/").last.map { String($0) } ?? identifier

        return try await sendTransaction(cadenceStr: cadenceString, argumentList: [.address(childAddress), .string(ident), .array(idMaped)])
    }

    static func batchMoveNFTToChild(childAddr address: String, identifier: String, ids: [UInt64], collection: NFTCollectionInfo) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.batchTransferNFTToChild?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: accessible)
        let childAddress = Flow.Address(hex: address)
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }
        let ident = identifier.split(separator: "/").last.map { String($0) } ?? identifier

        return try await sendTransaction(cadenceStr: cadenceString, argumentList: [.address(childAddress), .string(ident), .array(idMaped)])
    }

    static func batchSendChildNFTToChild(fromAddress: String, toAddress: String, identifier: String, ids: [UInt64], collection: NFTCollectionInfo) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.batchSendChildNFTToChild?.toFunc() ?? ""
        let cadenceString = collection.formatCadence(script: accessible)
        let fromAddr = Flow.Address(hex: fromAddress)
        let toAddr = Flow.Address(hex: toAddress)
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }
        let ident = identifier.split(separator: "/").last.map { String($0) } ?? identifier

        return try await sendTransaction(cadenceStr: cadenceString, argumentList: [.address(fromAddr), .address(toAddr), .string(ident), .array(idMaped)])
    }
}

// MARK: - Others

extension FlowNetwork {
    static func addressVerify(address: String) async -> Bool {
        // testnet test address: 0x912d5440f7e3769e
        guard address.hasPrefix("0x") else {
            return false
        }

        let fAddress = Flow.Address(hex: address)
        do {
            _ = try await flow.accessAPI.getAccountAtLatestBlock(address: fAddress)
            return true
        } catch {
            return false
        }
    }

    static func getTransactionResult(by id: String) async throws -> Flow.TransactionResult {
        let idObj = Flow.ID(hex: id)
        return try await flow.accessAPI.getTransactionResultById(id: idObj)
    }

    static func getAccountAtLatestBlock(address: String) async throws -> Flow.Account {
        return try await flow.accessAPI.getAccountAtLatestBlock(address: Flow.Address(hex: address))
    }

    static func getLastBlockAccountKeyId(address: String) async throws -> Int {
        let account = try await getAccountAtLatestBlock(address: address)
        return account.keys.first?.index ?? 0
    }

    static func checkStorageInfo() async throws -> Flow.StorageInfo {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let cadence = CadenceManager.shared.current.basic?.getStorageInfo?.toFunc() ?? ""
        let response = try await flow.accessAPI.executeScriptAtLatestBlock(cadence: cadence, arguments: [.address(address)]).decode(Flow.StorageInfo.self)
        return response
    }
}

// MARK: - Base

extension FlowNetwork {
    private static func fetch<T: Decodable>(at address: Flow.Address, by cadence: String) async throws -> T {
        let replacedCadence = cadence.replace(by: ScriptAddress.addressMap())

        let response = try await flow.accessAPI.executeScriptAtLatestBlock(script: Flow.Script(text: replacedCadence),
                                                                           arguments: [.address(address)])
        let model: T = try response.decode()
        return model
    }

    private static func fetch<T: Decodable>(cadence: String, arguments: [Flow.Cadence.FValue]) async throws -> T {
        let replacedCadence = cadence.replace(by: ScriptAddress.addressMap())

        let response = try await flow.accessAPI.executeScriptAtLatestBlock(script: Flow.Script(text: replacedCadence), arguments: arguments)
        let model: T = try response.decode()
        return model
    }
}

// MARK: - Extension

extension Flow.TransactionResult {
    var isProcessing: Bool {
        status < .executed && errorMessage.isEmpty
    }

    var isComplete: Bool {
        status == .sealed && errorMessage.isEmpty
    }

    var isExpired: Bool {
        status == .expired
    }

    var isSealed: Bool {
        status == .sealed
    }

    var isFailed: Bool {
        if isProcessing {
            return false
        }

        if isExpired {
            return true
        }
        return !errorMessage.isEmpty
    }
}

// MARK: - Account Key

extension FlowNetwork {
    static func revokeAccountKey(by index: Int, at address: Flow.Address) async throws -> Flow.ID {
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners, builder: {
            cadence {
                CadenceManager.shared.current.basic?.revokeKey?.toFunc() ?? ""
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }

            authorizers {
                address
            }

            arguments {
                [.int(index)]
            }
        })
    }

    static func addKeyToAccount(address: Flow.Address, accountKey: Flow.AccountKey, signers: [FlowSigner]) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.basic?.addKey?.toFunc() ?? ""
        let fromKeyIndex = WalletManager.shared.keyIndex
        return try await flow.sendTransaction(signers: signers) {
            cadence {
                originCadence
            }
            arguments {
                [
                    .string(accountKey.publicKey.hex),
                    .uint8(UInt8(accountKey.signAlgo.index)),
                    .uint8(UInt8(accountKey.hashAlgo.code)),
                    .ufix64(Decimal(accountKey.weight)),
                ]
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: fromKeyIndex)
            }
            authorizers {
                address
            }
        }
    }

    static func addKeyWithMulti(address: Flow.Address, keyIndex: Int, sequenceNum: Int64, accountKey: Flow.AccountKey, signers: [FlowSigner]) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.basic?.addKey?.toFunc() ?? ""
        return try await flow.sendTransaction(signers: signers) {
            cadence {
                originCadence
            }
            arguments {
                [
                    .string(accountKey.publicKey.hex),
                    .uint8(UInt8(accountKey.signAlgo.index)),
                    .uint8(UInt8(accountKey.hashAlgo.code)),
                    .ufix64(Decimal(accountKey.weight)),
                ]
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: address, keyIndex: keyIndex, sequenceNumber: sequenceNum)
            }
            authorizers {
                address
            }
        }
    }
}

// MARK: - EVM

extension FlowNetwork {
    static func createEVM() async throws -> Flow.ID {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.createCoaEmpty?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let fromKeyIndex = WalletManager.shared.keyIndex

        return try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners) {
            cadence {
                cadenceStr
            }

            payer {
                RemoteConfigManager.shared.payer
            }

            proposer {
                Flow.TransactionProposalKey(address: Flow.Address(hex: fromAddress), keyIndex: fromKeyIndex)
            }

            authorizers {
                Flow.Address(hex: fromAddress)
            }

            gasLimit {
                9999
            }
        }
    }

    static func findEVMAddress() async throws -> String {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.getCoaAddr?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let resonpse = try await flow.accessAPI.executeScriptAtLatestBlock(script: Flow.Script(text: cadenceStr), arguments: [.address(Flow.Address(hex: fromAddress))]).decode(String.self)
        return resonpse
    }

    static func fetchEVMBalance(address _: String) async throws -> Decimal {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.getCoaBalance?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())

        let resonpse = try await flow.accessAPI.executeScriptAtLatestBlock(script: Flow.Script(text: cadenceStr), arguments: [.address(Flow.Address(hex: fromAddress))])
        let result = try resonpse.decode(Decimal.self)
        return result
    }

    /// evm to flow between self
    static func withdrawCoa(amount: Decimal) async throws -> Flow.ID {
        guard let toAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.withdrawCoa?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())

        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .ufix64(amount),
            .address(Flow.Address(hex: toAddress)),
        ])
    }

    /// cadence to evm
    static func fundCoa(amount: Decimal) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.evm?.fundCoa?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .ufix64(amount),
        ])
    }

    /// coa -> eoa
    static func sendTransaction(amount: String, data: Data?, toAddress: String, gas: UInt64) async throws -> Flow.ID {
        guard let amountParse = Decimal(string: amount) else {
            throw WalletError.insufficientBalance
        }
        let originCadence = CadenceManager.shared.current.evm?.callContract?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        var argData: Flow.Cadence.FValue = .array([])
        if let toValue = data?.cadenceValue {
            argData = toValue
        }
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(toAddress),
            .ufix64(amountParse),
            argData,
            .uint64(gas),
        ])
    }

    static func fetchEVMTransactionResult(txid: String) async throws -> EVMTransactionExecuted {
        log.info("[EVM] evm transaction tix: \(txid)")
        let result = try await flow.getTransactionResultById(id: .init(hex: txid))
        let event = result.events.filter { event in
            event.type.lowercased().contains("evm.TransactionExecuted".lowercased())
        }.first
        guard let event = event else {
            throw EVMError.transactionResult
        }
        let model: EVMTransactionExecuted = try event.payload.decode()
        log.debug("[EVM] result ==> \(String(describing: model.hash))")
        return model
    }

    // transferFlowToEvmAddress
    static func sendFlowToEvm(evmAddress: String, amount: Decimal, gas: UInt64) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.evm?.transferFlowToEvmAddress?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(evmAddress),
            .ufix64(amount),
            .uint64(gas),
        ])
    }

    /// transferFlowFromCoaToFlow
    static func sendFlowTokenFromCoaToFlow(amount: Decimal, address: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.evm?.transferFlowFromCoaToFlow?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .ufix64(amount),
            .address(Flow.Address(hex: address)),
        ])
    }

    static func sendNoFlowTokenToEVM(vaultIdentifier: String, amount: Decimal, recipient: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.bridge?.bridgeTokensToEvmAddressV2?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let amountValue = Flow.Cadence.FValue.ufix64(amount)

        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(vaultIdentifier),
            amountValue,
            .string(recipient),
        ])
    }

    static func bridgeToken(vaultIdentifier: String, amount: Decimal, fromEvm: Bool, decimals: Int) async throws -> Flow.ID {
        let originCadence = (fromEvm ? CadenceManager.shared.current.bridge?.bridgeTokensFromEvmV2?.toFunc()
            : CadenceManager.shared.current.bridge?.bridgeTokensToEvmV2?.toFunc()) ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        var amountValue = Flow.Cadence.FValue.ufix64(amount)
        if let result = Utilities.parseToBigUInt(amount.description, decimals: decimals), fromEvm {
            amountValue = Flow.Cadence.FValue.uint256(result)
        }
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(vaultIdentifier),
            amountValue,
        ])
    }

    static func bridgeTokensFromEvmToFlow(identifier: String, amount: BigUInt, receiver: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.bridge?.bridgeTokensFromEvmToFlowV2?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let amountValue = Flow.Cadence.FValue.uint256(amount)
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            amountValue,
            .address(Flow.Address(hex: receiver)),
        ])
    }

    //

    static func bridgeNFTToEVM(identifier: String, ids: [UInt64], fromEvm: Bool) async throws -> Flow.ID {
        let originCadence = (fromEvm ? CadenceManager.shared.current.bridge?.batchBridgeNFTFromEvmV2?.toFunc()
            : CadenceManager.shared.current.bridge?.batchBridgeNFTToEvmV2?.toFunc()) ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let idMaped = fromEvm ? ids.map { Flow.Cadence.FValue.uint256(BigUInt($0)) } : ids.map { Flow.Cadence.FValue.uint64($0) }

        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            .array(idMaped),
        ])
    }

    static func bridgeNFTToAnyEVM(identifier: String, id: String, toAddress: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.bridge?.bridgeNFTToEvmAddressV2?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        guard let nftId = UInt64(id) else {
            throw NFTError.invalidTokenId
        }

        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            .uint64(nftId),
            .string(toAddress),
        ])
    }

    static func bridgeNFTFromEVMToAnyFlow(identifier: String, id: String, receiver: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.bridge?.bridgeNFTFromEvmToFlowV2?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())

        guard let nftId = BigUInt(id) else {
            throw NFTError.invalidTokenId
        }

        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            .uint256(nftId),
            .address(Flow.Address(hex: receiver)),
        ])
    }
    
    static func checkCoaLink(address: String) async throws -> Bool? {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.checkCoaLink?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let resonpse = try await flow.accessAPI.executeScriptAtLatestBlock(script: Flow.Script(text: cadenceStr), arguments: [.address(Flow.Address(hex: fromAddress))]).decode(Bool?.self)
        return resonpse
    }
    
    static func coaLink() async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.evm?.coaLink?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [])
    }
}

//MARK: Bridge between Child and EVM
extension FlowNetwork {
    static func bridgeChildNFTToEvm(nft identifier: String, id: UInt64, child: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.hybridCustody?.bridgeChildNFTToEvm?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let nftId = BigUInt(id)
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            .uint64(id),
            .address(Flow.Address(hex: child)),
        ])
    }
    
    static func bridgeChildNFTFromEvm(nft identifier: String, id: UInt64, child: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.hybridCustody?.bridgeChildNFTFromEvm?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        
        let nftId = BigUInt(id)
        
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            .address(Flow.Address(hex: child)),
            .uint256(nftId),
        ])
    }
    
    static func batchBridgeChildNFTToCoa(nft identifier: String, ids: [UInt64], child: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.hybridCustody?.batchBridgeChildNFTToEvm?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }
        
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            .address(Flow.Address(hex: child)),
            .array(idMaped),
        ])
    }
    
    static func batchBridgeChildNFTFromCoa(nft identifier: String, ids: [UInt64], child: String) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.hybridCustody?.batchBridgeChildNFTFromEvm?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }
        
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(identifier),
            .address(Flow.Address(hex: child)),
            .array(idMaped),
        ])
    }
    
    static func bridgeChildTokenToCoa(vaultIdentifier: String, child:String, amount: Decimal) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.hybridCustody?.bridgeChildFTToEvm?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let amountValue = Flow.Cadence.FValue.ufix64(amount)
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(vaultIdentifier),
            .address(Flow.Address(hex: child)),
            amountValue,
        ])
    }
    
    static func bridgeChildTokenFromCoa(vaultIdentifier: String, child:String, amount: Decimal) async throws -> Flow.ID {
        let originCadence = CadenceManager.shared.current.hybridCustody?.bridgeChildFTFromEvm?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let amountValue = Flow.Cadence.FValue.ufix64(amount)
        return try await sendTransaction(cadenceStr: cadenceStr, argumentList: [
            .string(vaultIdentifier),
            .address(Flow.Address(hex: child)),
            amountValue,
        ])
    }
}

extension FlowNetwork {
    private static func sendTransaction(cadenceStr: String, argumentList: [Flow.Cadence.FValue]) async throws -> Flow.ID {
        let fromKeyIndex = WalletManager.shared.keyIndex
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let tranId = try await flow.sendTransaction(signers: WalletManager.shared.defaultSigners) {
            cadence {
                cadenceStr
            }

            payer {
                RemoteConfigManager.shared.payer
            }
            arguments {
                argumentList
            }
            proposer {
                Flow.TransactionProposalKey(address: Flow.Address(hex: fromAddress), keyIndex: fromKeyIndex)
            }

            authorizers {
                Flow.Address(hex: fromAddress)
            }

            gasLimit {
                9999
            }
        }
        log.info("[Flow] transaction Id:\(tranId.description)")
        return tranId
    }
}

extension Data {
    var cadenceValue: Flow.Cadence.FValue {
        .array(map { $0.cadenceValue })
    }
}

extension UInt8 {
    var cadenceValue: Flow.Cadence.FValue {
        Flow.Cadence.FValue.uint8(self)
    }
}

extension String {
    func compareVersion(to version: String) -> ComparisonResult {
        return compare(version, options: .numeric)
    }
}
