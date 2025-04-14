//
//  FlowNetwork.swift
//  Flow Wallet
//
//  Created by Hao Fu on 30/4/2022.
//

import BigInt
import Combine
import CryptoKit
import Flow
import Foundation
import Web3Core

private actor ScriptStore {
    private var scriptIds: [String: String] = [:]

    func getScriptId(_ txId: Flow.ID) -> String? {
        scriptIds[txId.description]
    }

    func setScriptId(_ txId: String, _ funcName: String) {
        scriptIds[txId] = funcName
    }
}

// MARK: - FlowNetwork

enum FlowNetwork {
    private static let scriptStore = ScriptStore()
    static func setup() {
        let type = LocalUserDefaults.shared.flowNetwork.toFlowType()
        log.debug("did setup flow chainID to \(LocalUserDefaults.shared.flowNetwork.rawValue)")
        flow.configure(chainID: type)
    }
}

extension FlowNetwork {
    static func scriptId(_ txId: Flow.ID) async -> String? {
        await scriptStore.getScriptId(txId)
    }
}

// MARK: - Token

extension FlowNetwork {
    // TODO: delete
    static func checkTokensEnable(address: Flow.Address) async throws -> [String: Bool] {
        try await fetch(
            by: \.ft?.isTokenListEnabled,
            arguments: [.address(address)]
        )
    }

    // TODO: delete
    static func fetchBalance(at address: Flow.Address) async throws -> [String: Double] {
        try await fetch(
            by: \.ft?.getTokenListBalance,
            arguments: [.address(address)]
        )
    }

    static func enableToken(at _: Flow.Address, token: TokenModel) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.ft?.addToken,
            with: token,
            argumentList: []
        )
    }

    static func transferToken(
        to address: Flow.Address,
        amount: Decimal,
        token: TokenModel
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.ft?.transferTokensV3,
            with: token,
            argumentList: [.ufix64(amount), .address(address)]
        )
    }

    static func minFlowBalance() async throws -> Double {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let result: Decimal = try await fetch(
            by: \.basic?.getAccountMinFlow,
            arguments: [.address(Flow.Address(hex: fromAddress))]
        )
        return result.doubleValue
    }

    /// fetch all valid token and balance
    static func fetchTokenBalance(address: Flow.Address) async throws -> [String: Double] {
        try await fetch(by: \.ft?.getTokenBalanceStorage, arguments: [.address(address)])
    }

    /// get avaiblabe account balance for all type: coa,flow,link
    static func getFlowBalanceForAnyAccount(address: [String]) async throws -> [String: Double?] {
        let list = address.map { Flow.Cadence.FValue.string($0) }
        return try await fetch(by: \.basic?.getFlowBalanceForAnyAccounts, arguments: [Flow.Cadence.FValue.array(list)])
    }
}

// MARK: - NFT

extension FlowNetwork {
    static func checkCollectionEnable(address: Flow.Address) async throws -> [String: Int] {
        try await fetch(
            by: \.collection?.getNFTBalanceStorage,
            arguments: [.address(address)]
        )
    }

    static func addCollection(
        at _: Flow.Address,
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.collection?.enableNFTStorage,
            with: collection,
            argumentList: []
        )
    }

    static func transferNFT(to address: Flow.Address, nft: NFTModel) async throws -> Flow.ID {
        var nftCollection = nft.collection
        if nftCollection == nil {
            nftCollection = await NFTCollectionConfig.share
                .get(from: nft.response.contractAddress ?? "")
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

        var nftTransfer: KeyPath<CadenceModel, String?> = \.collection?.sendNFTV3
        let nbaNFTTransfer: KeyPath<CadenceModel, String?> = \.collection?.sendNbaNFTV3

        return try await sendTransaction(
            by: nft.isNBA ? nbaNFTTransfer : nftTransfer,
            with: collection,
            argumentList: [.address(address), .uint64(tokenIdInt)]
        )
    }
}

// MARK: - Search

extension FlowNetwork {
    static func queryAddressByDomainFind(domain: String) async throws -> String {
        try await fetch(by: \.basic?.getFindAddress, arguments: [.string(domain)])
    }

    static func queryAddressByDomainFlowns(
        domain: String,
        root: String = "fn"
    ) async throws -> String {
        let realDomain = domain
            .replacingOccurrences(of: ".fn", with: "")
            .replacingOccurrences(of: ".meow", with: "")
        return try await fetch(
            by: \.basic?.getFlownsAddress,
            arguments: [.string(realDomain), .string(root)]
        )
    }
}

// MARK: - Inbox

extension FlowNetwork {
    static func claimInboxToken(
        domain: String,
        key: String,
        coin: TokenModel,
        amount: Decimal,
        root: String = Contact.DomainType.meow.domain
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.domain?.claimFTFromInbox,
            with: coin,
            argumentList: [
                .string(domain),
                .string(root),
                .string(key),
                .ufix64(amount),
            ]
        )
    }

    static func claimInboxNFT(
        domain: String,
        key: String,
        collection: NFTCollectionInfo,
        itemId: UInt64,
        root: String = Contact.DomainType.meow.domain
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.domain?.claimNFTFromInbox,
            with: collection,
            argumentList: [.string(domain), .string(root), .string(key), .uint64(itemId)]
        )
    }
}

// MARK: - Swap

extension FlowNetwork {
    static func swapToken(
        swapPaths: [String],
        tokenInMax: Decimal,
        tokenOutMin: Decimal,
        tokenInVaultPath: String,
        tokenOutSplit: [Decimal],
        tokenInSplit: [Decimal],
        tokenOutVaultPath: String,
        tokenOutReceiverPath: String,
        tokenOutBalancePath: String,
        deadline: Decimal,
        isFrom: Bool
    ) async throws -> Flow.ID {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }

        let tokenName = String(swapPaths.last?.split(separator: ".").last ?? "")
        let tokenAddress = String(swapPaths.last?.split(separator: ".")[1] ?? "").addHexPrefix()

        let fromCadence: KeyPath<CadenceModel, String?> = \.swap?.SwapExactTokensForTokens
        let toCadence: KeyPath<CadenceModel, String?> = \.swap?.SwapTokensForExactTokens
        var cadenceKeyPath = isFrom ? fromCadence : toCadence

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

        return try await sendTransaction(
            by: cadenceKeyPath,
            with: ["Token1Name": tokenName, "Token1Addr": tokenAddress],
            argumentList: args
        )
    }
}

// MARK: - LilicoError

enum LilicoError: Error {
    case emptyWallet
}

extension FlowNetwork {
    static func stakingIsEnabled() async throws -> Bool {
        return try await fetch(by: \.staking?.checkStakingEnabled)
    }

    static func accountStakingIsSetup() async throws -> Bool {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        return try await fetch(by: \.staking?.checkSetup, arguments: [.address(address)])
    }

    static func claimUnstake(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow
        .ID
    {
        try await sendTransaction(
            by: \.staking?.withdrawUnstaked,
            argumentList: [
                .string(nodeID),
                .uint32(UInt32(delegatorId)),
                .ufix64(amount),
            ]
        )
    }

    static func reStakeUnstake(
        nodeID: String,
        delegatorId: Int,
        amount: Decimal
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.staking?.restakeUnstaked,
            argumentList: [
                .string(nodeID),
                .uint32(UInt32(delegatorId)),
                .ufix64(amount),
            ]
        )
    }

    // FIXME:
    static func claimReward(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow
        .ID
    {
        try await sendTransaction(
            by: \.staking?.withdrawReward,
            argumentList: [.string(nodeID), .uint32(UInt32(delegatorId)), .ufix64(amount)]
        )
    }

    static func reStakeReward(
        nodeID: String,
        delegatorId: Int,
        amount: Decimal
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.staking?.restakeReward,
            argumentList: [
                .string(nodeID),
                .uint32(UInt32(delegatorId)),
                .ufix64(amount),
            ]
        )
    }

    static func setupAccountStaking() async throws -> Bool {
        let txId = try await sendTransaction(by: \.staking?.setup, argumentList: [])
        let result = try await txId.onceSealed()
        if result.isFailed {
            debugPrint("FlowNetwork: setupAccountStaking failed msg: \(result.errorMessage)")
            return false
        }

        return true
    }

    static func createDelegatorId(providerId: String, amount: Double = 0) async throws -> Flow.ID {
        let txId = try await sendTransaction(
            by: \.staking?.createDelegator,
            argumentList: [.string(providerId), .ufix64(Decimal(amount))]
        )

        return txId
    }

    static func stakeFlow(providerId: String, delegatorId: Int, amount: Double) async throws -> Flow
        .ID
    {
        let txId = try await sendTransaction(
            by: \.staking?.createStake,
            argumentList: [
                .string(providerId),
                .uint32(UInt32(delegatorId)),
                .ufix64(Decimal(amount)),
            ]
        )

        return txId
    }

    static func unstakeFlow(
        providerId: String,
        delegatorId: Int,
        amount: Double
    ) async throws -> Flow.ID {
        let txId = try await sendTransaction(
            by: \.staking?.unstake,
            argumentList: [
                .string(providerId),
                .uint32(UInt32(delegatorId)),
                .ufix64(Decimal(amount)),
            ]
        )

        return txId
    }

    static func queryStakeInfo() async throws -> [StakingNode]? {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let response: [StakingNode] = try await fetch(
            by: \.staking?.getDelegatesInfoArrayV2,
            arguments: [.address(address)]
        )
        debugPrint("FlowNetwork -> queryStakeInfo, response = \(response)")
        return response
    }

    static func getStakingApyByWeek() async throws -> Double {
        let result: Decimal = try await fetch(by: \.staking?.getApyWeekly, arguments: [])
        return result.doubleValue
    }

    static func getStakingApyByYear() async throws -> Double {
        let result: Decimal = try await fetch(by: \.staking?.getApr, arguments: [])
        return result.doubleValue
    }

    static func getDelegatorInfo() async throws -> [String: Int]? {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let cadence = CadenceManager.shared.current.staking?.getDelegatesIndo?.toFunc() ?? ""
        let replacedCadence = cadence.replace(by: ScriptAddress.addressMap())
        let rawResponse = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: replacedCadence),
            arguments: [.address(address)]
        )

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
        let response: [String] = try await fetch(
            by: \.hybridCustody?.getChildAccount,
            arguments: [.address(address)]
        )
        return response
    }

    static func unlinkChildAccount(_ address: String) async throws -> Flow.ID {
        let txId = try await sendTransaction(
            by: \.hybridCustody?.unlinkChildAccount,
            argumentList: [.address(Flow.Address(hex: address))]
        )

        return txId
    }

    static func queryChildAccountMeta(_ address: String) async throws -> [ChildAccount] {
        let address = Flow.Address(hex: address)
        let cadence = CadenceManager.shared.current.hybridCustody?.getChildAccountMeta?
            .toFunc() ?? ""
        let replacedCadence = cadence.replace(by: ScriptAddress.addressMap())
        let rawResponse = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: replacedCadence),
            arguments: [.address(address)]
        )

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

    static func editChildAccountMeta(
        _ address: String,
        name: String,
        desc: String,
        thumbnail: String
    ) async throws -> Flow.ID {
        let txId = try await sendTransaction(by: \.hybridCustody?.editChildAccount, argumentList: [
            .address(Flow.Address(hex: address)),
            .string(name),
            .string(desc),
            .string(thumbnail),
        ])

        return txId
    }

    static func fetchAccessibleCollection(parent: String, child: String) async throws -> [String] {
        let cadence = CadenceManager.shared.current.hybridCustody?.getChildAccountAllowTypes?
            .toFunc() ?? ""
        let cadenceString = cadence.replace(by: ScriptAddress.addressMap())
        let parentAddress = Flow.Address(hex: parent)
        let childAddress = Flow.Address(hex: child)
        let response = try await flow.accessAPI
            .executeScriptAtLatestBlock(
                script: Flow.Script(text: cadenceString),
                arguments: [.address(parentAddress), .address(childAddress)]
            )
        let result = try response.decode([String].self)
        return result
    }

    static func fetchAccessibleFT(
        parent: String,
        child: String
    ) async throws -> [FlowModel.TokenInfo] {
        let accessible = CadenceManager.shared.current.hybridCustody?.getAccessibleCoinInfo?
            .toFunc() ?? ""
        let cadenceString = accessible.replace(by: ScriptAddress.addressMap())
        let parentAddress = Flow.Address(hex: parent)
        let childAddress = Flow.Address(hex: child)
        let response = try await flow.accessAPI
            .executeScriptAtLatestBlock(
                script: Flow.Script(text: cadenceString),
                arguments: [.address(parentAddress), .address(childAddress)]
            )
            .decode([FlowModel.TokenInfo].self)
        return response
    }

    // on child, move nft to parent
    static func moveNFTToParent(
        nftId: UInt64,
        childAddress: String,
        identifier: String,
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        let childAddress = Flow.Address(hex: childAddress)
        return try await sendTransaction(
            by: \.hybridCustody?.transferChildNFT,
            with: collection,
            argumentList: [.address(childAddress), .string(identifier), .uint64(nftId)]
        )
    }

    // on parent， move nft to child
    static func moveNFTToChild(
        nftId: UInt64,
        childAddress: String,
        identifier: String,
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.hybridCustody?.transferNFTToChild,
            with: collection,
            argumentList: [
                .address(Flow.Address(hex: childAddress)),
                .string(identifier),
                .uint64(nftId),
            ]
        )
    }

    // send NFT from child to other wallet
    static func sendChildNFT(
        nftId: UInt64,
        childAddress: String,
        toAddress: String,
        identifier: String,
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        let childAddr = Flow.Address(hex: childAddress)
        let toAddr = Flow.Address(hex: toAddress)
        return try await sendTransaction(
            by: \.hybridCustody?.sendChildNFT,
            with: collection,
            argumentList: [
                .address(childAddr),
                .address(toAddr),
                .string(identifier),
                .uint64(nftId),
            ]
        )
    }

    // Send NFT from child to child
    static func sendChildNFTToChild(
        nftId: UInt64,
        childAddress: String,
        toAddress: String,
        identifier: String,
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        let childAddr = Flow.Address(hex: childAddress)
        let toAddr = Flow.Address(hex: toAddress)
        return try await sendTransaction(
            by: \.hybridCustody?.sendChildNFTToChild,
            with: collection,
            argumentList: [
                .address(childAddr),
                .address(toAddr),
                .string(identifier),
                .uint64(nftId),
            ]
        )
    }

    static func checkChildLinkedCollections(
        parent: String,
        child: String,
        identifier: String,
        collection _: NFTCollectionInfo
    ) async throws -> Bool {
        let cadence = CadenceManager.shared.current.hybridCustody?.checkChildLinkedCollections?
            .toFunc() ?? ""
        let cadenceString = cadence.replace(by: ScriptAddress.addressMap())
        let parentAddress = Flow.Address(hex: parent)
        let childAddress = Flow.Address(hex: child)
        let response = try await flow.accessAPI
            .executeScriptAtLatestBlock(
                script: Flow.Script(text: cadenceString),
                arguments: [
                    .address(parentAddress),
                    .address(childAddress),
                    .string(identifier),
                ]
            )
        let result = try response.decode(Bool.self)
        return result
    }

    static func batchMoveNFTToParent(
        childAddr address: String,
        identifier: String,
        ids: [UInt64],
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        let childAddress = Flow.Address(hex: address)
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }

        let ident = identifier.split(separator: "/").last.map { String($0) } ?? identifier

        return try await sendTransaction(
            by: \.hybridCustody?.batchTransferChildNFT,
            with: collection,
            argumentList: [.address(childAddress), .string(ident), .array(idMaped)]
        )
    }

    static func batchMoveNFTToChild(
        childAddr address: String,
        identifier: String,
        ids: [UInt64],
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        let accessible = CadenceManager.shared.current.hybridCustody?.batchTransferNFTToChild?
            .toFunc() ?? ""
        let childAddress = Flow.Address(hex: address)
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }
        let ident = identifier.split(separator: "/").last.map { String($0) } ?? identifier

        return try await sendTransaction(
            by: \.hybridCustody?.batchTransferNFTToChild,
            with: collection,
            argumentList: [.address(childAddress), .string(ident), .array(idMaped)]
        )
    }

    static func batchSendChildNFTToChild(
        fromAddress: String,
        toAddress: String,
        identifier: String,
        ids: [UInt64],
        collection: NFTCollectionInfo
    ) async throws -> Flow.ID {
        let fromAddr = Flow.Address(hex: fromAddress)
        let toAddr = Flow.Address(hex: toAddress)
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }
        let ident = identifier.split(separator: "/").last.map { String($0) } ?? identifier

        return try await sendTransaction(
            by: \.hybridCustody?.batchSendChildNFTToChild,
            with: collection,
            argumentList: [.address(fromAddr), .address(toAddr), .string(ident), .array(idMaped)]
        )
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
        try await flow.accessAPI.getAccountAtLatestBlock(address: Flow.Address(hex: address))
    }

    static func getLastBlockAccountKeyId(address: String) async throws -> Int {
        let account = try await getAccountAtLatestBlock(address: address)
        return account.keys.first?.index ?? 0
    }

    static func checkStorageInfo() async throws -> Flow.StorageInfo {
        let address = Flow.Address(hex: WalletManager.shared.getPrimaryWalletAddress() ?? "")
        let cadence = CadenceManager.shared.current.basic?.getStorageInfo?.toFunc() ?? ""
        let response = try await flow.accessAPI.executeScriptAtLatestBlock(
            cadence: cadence,
            arguments: [.address(address)]
        ).decode(Flow.StorageInfo.self)
        return response
    }

    static func checkAccountInfo() async throws -> Flow.AccountInfo {
        guard let address = WalletManager.shared.getPrimaryWalletAddress()
            .map(Flow.Address.init(hex:))
        else {
            throw LLError.invalidAddress
        }

        guard let cadence = CadenceManager.shared.current.basic?.getAccountInfo?.toFunc() else {
            throw LLError.invalidCadence
        }

        return try await flow.accessAPI.executeScriptAtLatestBlock(
            cadence: cadence,
            arguments: [.address(address)]
        ).decode(Flow.AccountInfo.self)
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
    static func revokeAccountKey(by index: Int, at _: Flow.Address) async throws -> Flow.ID {
        try await sendTransaction(by: \.basic?.revokeKey, argumentList: [.int(index)])
    }

    static func addKeyToAccount(
        address _: Flow.Address,
        accountKey: Flow.AccountKey,
        signers _: [FlowSigner]
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.basic?.addKey,
            argumentList: [
                .string(accountKey.publicKey.hex),
                .uint8(UInt8(accountKey.signAlgo.index)),
                .uint8(UInt8(accountKey.hashAlgo.code)),
                .ufix64(Decimal(accountKey.weight)),
            ]
        )
    }

    //! !!Note this no need current address and not sign with login user
    static func addKeyWithMulti(
        address: Flow.Address,
        keyIndex: Int,
        sequenceNum: Int64,
        accountKey: Flow.AccountKey,
        signers: [FlowSigner]
    ) async throws -> Flow.ID {
        try await sendTransaction(
            by: \.basic?.addKey,
            address: address,
            keyIndex: keyIndex,
            sequenceNum: sequenceNum,
            signers: signers,
            argumentList: [
                .string(accountKey.publicKey.hex),
                .uint8(UInt8(accountKey.signAlgo.index)),
                .uint8(UInt8(accountKey.hashAlgo.code)),
                .ufix64(Decimal(accountKey.weight)),
            ]
        )
    }
}

// MARK: - EVM

extension FlowNetwork {
    static func createEVM() async throws -> Flow.ID {
        return try await sendTransaction(by: \.evm?.createCoaEmpty, argumentList: [])
    }

    static func findEVMAddress() async throws -> String? {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.getCoaAddr?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let response = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: cadenceStr),
            arguments: [.address(Flow.Address(hex: fromAddress))]
        ).decode(String.self)

        guard !response.isEmpty else {
            return nil
        }

        guard let checkSumAddress = EthereumAddress.toChecksumAddress(response) else {
            return response
        }

        return checkSumAddress
    }

    static func fetchEVMBalance(address _: String) async throws -> Decimal {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.getCoaBalance?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())

        let resonpse = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: cadenceStr),
            arguments: [.address(Flow.Address(hex: fromAddress))]
        )
        let result = try resonpse.decode(Decimal.self)
        return result
    }

    /// evm to flow between self
    static func withdrawCoa(amount: Decimal) async throws -> Flow.ID {
        guard let toAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }

        return try await sendTransaction(by: \.evm?.withdrawCoa, argumentList: [
            .ufix64(amount),
            .address(Flow.Address(hex: toAddress)),
        ])
    }

    /// cadence to evm
    static func fundCoa(amount: Decimal) async throws -> Flow.ID {
        try await sendTransaction(by: \.evm?.fundCoa, argumentList: [
            .ufix64(amount),
        ])
    }

    /// coa -> eoa
    static func sendTransaction(
        amount: String,
        data: Data?,
        toAddress: String,
        gas: UInt64
    ) async throws -> Flow.ID {
        guard let amountParse = Decimal(string: amount) else {
            EventTrack.Transaction.evmSigned(txId: "", success: false)
            throw WalletError.insufficientBalance
        }

        var argData: Flow.Cadence.FValue = .array([])
        if let toValue = data?.cadenceValue {
            argData = toValue
        }
        do {
            let txid = try await sendTransaction(by: \.evm?.callContract, argumentList: [
                .string(toAddress),
                .ufix64(amountParse),
                argData,
                .uint64(gas),
            ])
            EventTrack.Transaction.evmSigned(txId: txid.hex, success: true)
            return txid
        } catch {
            EventTrack.Transaction.evmSigned(txId: "", success: false)
            throw error
        }
    }

    /// coa -> eoa for js
    static func sendTransaction(
        amount: BigUInt,
        data: Data?,
        toAddress: String,
        gas: UInt64
    ) async throws -> Flow.ID {
        var argData: Flow.Cadence.FValue = .array([])
        if let toValue = data?.cadenceValue {
            argData = toValue
        }
        do {
            let txid = try await sendTransaction(by: \.evm?.callContractV2, argumentList: [
                .string(toAddress),
                .uint256(amount),
                argData,
                .uint64(gas),
            ])
            EventTrack.Transaction.evmSigned(txId: txid.hex, success: true)
            return txid
        } catch {
            EventTrack.Transaction.evmSigned(txId: "", success: false)
            throw error
        }
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
        try await sendTransaction(by: \.evm?.transferFlowToEvmAddress, argumentList: [
            .string(evmAddress),
            .ufix64(amount),
            .uint64(gas),
        ])
    }

    /// transferFlowFromCoaToFlow
    static func sendFlowTokenFromCoaToFlow(amount: Decimal, address: String) async throws -> Flow.ID {
        try await sendTransaction(by: \.evm?.transferFlowFromCoaToFlow, argumentList: [
            .ufix64(amount),
            .address(Flow.Address(hex: address)),
        ])
    }

    static func sendNoFlowTokenToEVM(
        vaultIdentifier: String,
        amount: Decimal,
        recipient: String
    ) async throws -> Flow.ID {
        let amountValue = Flow.Cadence.FValue.ufix64(amount)
        return try await sendTransaction(by: \.bridge?.bridgeTokensToEvmAddressV2, argumentList: [
            .string(vaultIdentifier),
            amountValue,
            .string(recipient),
        ])
    }

    static func bridgeToken(
        vaultIdentifier: String,
        amount: Decimal,
        fromEvm: Bool,
        decimals: Int
    ) async throws -> Flow.ID {
        let keyPath: KeyPath<CadenceModel, String?> = fromEvm ? \.bridge?
            .bridgeTokensFromEvmV2 : \.bridge?.bridgeTokensToEvmV2

        var amountValue = Flow.Cadence.FValue.ufix64(amount)

        if let result = amount.description.parseToBigUInt(decimals: decimals), fromEvm {
            amountValue = Flow.Cadence.FValue.uint256(result)
        }
        return try await sendTransaction(by: keyPath, argumentList: [
            .string(vaultIdentifier),
            amountValue,
        ])
    }

    static func bridgeTokensFromEvmToFlow(
        identifier: String,
        amount: BigUInt,
        receiver: String
    ) async throws -> Flow.ID {
        let amountValue = Flow.Cadence.FValue.uint256(amount)
        return try await sendTransaction(by: \.bridge?.bridgeTokensFromEvmToFlowV3, argumentList: [
            .string(identifier),
            amountValue,
            .address(Flow.Address(hex: receiver)),
        ])
    }

    //

    static func bridgeNFTToEVM(
        identifier: String,
        ids: [UInt64],
        fromEvm: Bool
    ) async throws -> Flow.ID {
        let fromEVMKeyPath: KeyPath<CadenceModel, String?> = RemoteConfigManager.shared.coverBridgeFee
            ? \.bridge?.batchBridgeNFTFromEvmWithPayer : \.bridge?.batchBridgeNFTFromEvmV2

        let toEVMKeyPath: KeyPath<CadenceModel, String?> = RemoteConfigManager.shared.coverBridgeFee
            ? \.bridge?.batchBridgeNFTToEvmWithPayer : \.bridge?.batchBridgeNFTToEvmV2

        let keyPath: KeyPath<CadenceModel, String?> = fromEvm ? fromEVMKeyPath : toEVMKeyPath

        let idMaped = fromEvm ? ids.map { Flow.Cadence.FValue.uint256(BigUInt($0)) } : ids
            .map { Flow.Cadence.FValue.uint64($0) }

        return try await sendTransaction(by: keyPath, argumentList: [
            .string(identifier),
            .array(idMaped),
        ])
    }

    static func bridgeNFTToAnyEVM(
        identifier: String,
        id: String,
        toAddress: String
    ) async throws -> Flow.ID {
        guard let nftId = UInt64(id) else {
            throw NFTError.invalidTokenId
        }
        let keyPath: KeyPath<CadenceModel, String?> = RemoteConfigManager.shared.coverBridgeFee
            ? \.bridge?.bridgeNFTToEvmAddressWithPayer : \.bridge?.bridgeNFTToEvmAddressV2
        return try await sendTransaction(by: keyPath, argumentList: [
            .string(identifier),
            .uint64(nftId),
            .string(toAddress),
        ])
    }

    static func bridgeNFTFromEVMToAnyFlow(
        identifier: String,
        id: String,
        receiver: String
    ) async throws -> Flow.ID {
        guard let nftId = BigUInt(id) else {
            throw NFTError.invalidTokenId
        }
        let keyPath: KeyPath<CadenceModel, String?> = RemoteConfigManager.shared.coverBridgeFee
            ? \.bridge?.bridgeNFTFromEvmToFlowWithPayer : \.bridge?.bridgeNFTFromEvmToFlowV3
        return try await sendTransaction(by: keyPath, argumentList: [
            .string(identifier),
            .uint256(nftId),
            .address(Flow.Address(hex: receiver)),
        ])
    }

    static func checkCoaLink(address _: String) async throws -> Bool? {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw LLError.invalidAddress
        }
        let originCadence = CadenceManager.shared.current.evm?.checkCoaLink?.toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let resonpse = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: cadenceStr),
            arguments: [.address(Flow.Address(hex: fromAddress))]
        ).decode(Bool?.self)
        return resonpse
    }

    static func coaLink() async throws -> Flow.ID {
        try await sendTransaction(by: \.evm?.coaLink, argumentList: [])
    }

    /// evm contract address, eg. 0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52
    static func getAssociatedFlowIdentifier(address: String) async throws -> String? {
        let originCadence = CadenceManager.shared.current.bridge?.getAssociatedFlowIdentifier?
            .toFunc() ?? ""
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let resonpse = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: cadenceStr),
            arguments: [.string(address)]
        ).decode(
            String?.self
        )
        return resonpse
    }

    static func getNonce(hexAddress: String) async throws -> UInt64 {
        guard let originCadence = CadenceManager.shared.current.evm?.getNonce?.toFunc() else {
            throw CadenceError.empty
        }
        let cadenceStr = originCadence.replace(by: ScriptAddress.addressMap())
        let encodedAddress = hexAddress.stripHexPrefix()
        let response = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: cadenceStr),
            arguments: [.string(encodedAddress)]
        )
        return try response.decode(UInt64.self)
    }
}

// MARK: Bridge between Child and EVM

extension FlowNetwork {
    static func bridgeChildNFTToEvm(
        nft identifier: String,
        id: UInt64,
        child: String
    ) async throws -> Flow.ID {
        try await sendTransaction(by: \.hybridCustody?.bridgeChildNFTToEvm, argumentList: [
            .string(identifier),
            .uint64(id),
            .address(Flow.Address(hex: child)),
        ])
    }

    static func bridgeChildNFTFromEvm(
        nft identifier: String,
        id: UInt64,
        child: String
    ) async throws -> Flow.ID {
        let nftId = BigUInt(id)

        return try await sendTransaction(by: \.hybridCustody?.bridgeChildNFTFromEvm, argumentList: [
            .string(identifier),
            .address(Flow.Address(hex: child)),
            .uint256(nftId),
        ])
    }

    static func batchBridgeChildNFTToCoa(
        nft identifier: String,
        ids: [UInt64],
        child: String
    ) async throws -> Flow.ID {
        let idMaped = ids.map { Flow.Cadence.FValue.uint64($0) }
        return try await sendTransaction(
            by: \.hybridCustody?.batchBridgeChildNFTToEvm,
            argumentList: [
                .string(identifier),
                .address(Flow.Address(hex: child)),
                .array(idMaped),
            ]
        )
    }

    static func batchBridgeChildNFTFromCoa(
        nft identifier: String,
        ids: [UInt64],
        child: String
    ) async throws -> Flow.ID {
        let idMaped = ids.compactMap { Flow.Cadence.FValue.uint256(BigUInt($0)) }
        return try await sendTransaction(
            by: \.hybridCustody?.batchBridgeChildNFTFromEvm,
            argumentList: [
                .string(identifier),
                .address(Flow.Address(hex: child)),
                .array(idMaped),
            ]
        )
    }

    static func bridgeChildTokenToCoa(
        vaultIdentifier: String,
        child: String,
        amount: Decimal
    ) async throws -> Flow.ID {
        let amountValue = Flow.Cadence.FValue.ufix64(amount)
        return try await sendTransaction(by: \.hybridCustody?.bridgeChildFTToEvm, argumentList: [
            .string(vaultIdentifier),
            .address(Flow.Address(hex: child)),
            amountValue,
        ])
    }

    static func bridgeChildTokenFromCoa(
        vaultIdentifier: String,
        child: String,
        amount: Decimal,
        decimals: Int
    ) async throws -> Flow.ID {
        guard let result = amount.description.parseToBigUInt(decimals: decimals) else {
            throw WalletError.insufficientBalance
        }
        let amountValue = Flow.Cadence.FValue.uint256(result)
        return try await sendTransaction(by: \.hybridCustody?.bridgeChildFTFromEvm, argumentList: [
            .string(vaultIdentifier),
            .address(Flow.Address(hex: child)),
            amountValue,
        ])
    }
}

// MARK: - Base

extension FlowNetwork {
    private static func fetch<T: Decodable>(
        by keyPath: KeyPath<CadenceModel, String?>,
        arguments: [Flow.Cadence.FValue] = []
    ) async throws -> T {
        let funcName = keyPath.funcName()
        guard let cadence = CadenceManager.shared.current[keyPath: keyPath]?.toFunc() else {
            EventTrack.General
                .rpcError(
                    error: CadenceError.empty.errorLog,
                    scriptId: funcName
                )
            log.error("[Cadence] empty script on \(funcName),version:\(CadenceManager.shared.version)")
            throw CadenceError.empty
        }
        let replacedCadence = cadence.replace(by: ScriptAddress.addressMap())
        log.info("[Cadence] fetch on \(funcName)")
        let response = try await flow.accessAPI.executeScriptAtLatestBlock(
            script: Flow.Script(text: replacedCadence),
            arguments: arguments
        )
        let model: T = try response.decode()
        return model
    }

    private static func sendTransaction(
        by keyPath: KeyPath<CadenceModel, String?>,
        argumentList: [Flow.Cadence.FValue]
    ) async throws -> Flow.ID {
        let funcName = keyPath.funcName()
        guard let cadence = CadenceManager.shared.current[keyPath: keyPath]?.toFunc() else {
            EventTrack.General
                .rpcError(
                    error: CadenceError.empty.errorLog,
                    scriptId: funcName
                )
            log.error("[Cadence] empty script on \(funcName)")
            throw CadenceError.empty
        }
        let replacedCadence = cadence.replace(
            by: ScriptAddress.addressMap()
        )
        log.info("[Cadence] transaction start on \(funcName)")
        return try await sendTransaction(
            funcName: funcName,
            cadenceStr: replacedCadence,
            argumentList: argumentList
        )
    }

    private static func sendTransaction(
        by keyPath: KeyPath<CadenceModel, String?>,
        with content: [String: String],
        argumentList: [Flow.Cadence.FValue]
    ) async throws -> Flow.ID {
        let funcName = keyPath.funcName()
        guard let cadence = CadenceManager.shared.current[keyPath: keyPath]?.toFunc() else {
            EventTrack.General
                .rpcError(
                    error: CadenceError.empty.errorLog,
                    scriptId: funcName
                )
            log.error("[Cadence] empty script on \(funcName)")
            throw CadenceError.empty
        }
        let replacedCadence = cadence.replace(from: content).replace(by: ScriptAddress.addressMap())
        log.info("[Cadence] transaction start on \(funcName)")
        return try await sendTransaction(
            funcName: funcName,
            cadenceStr: replacedCadence,
            argumentList: argumentList
        )
    }

    private static func sendTransaction(
        by keyPath: KeyPath<CadenceModel, String?>,
        with token: TokenModel,
        argumentList: [Flow.Cadence.FValue]
    ) async throws -> Flow.ID {
        let funcName = keyPath.funcName()
        guard let cadence = CadenceManager.shared.current[keyPath: keyPath]?.toFunc() else {
            EventTrack.General
                .rpcError(
                    error: CadenceError.empty.errorLog,
                    scriptId: funcName
                )
            log.error("[Cadence] empty script on \(funcName)")
            throw CadenceError.empty
        }
        let replacedCadence = try token.formatCadence(cadence: cadence)
        log.info("[Cadence] transaction start on \(funcName)")
        return try await sendTransaction(
            funcName: funcName,
            cadenceStr: replacedCadence,
            argumentList: argumentList
        )
    }

    private static func sendTransaction(
        by keyPath: KeyPath<CadenceModel, String?>,
        with collection: NFTCollectionInfo,
        argumentList: [Flow.Cadence.FValue]
    ) async throws -> Flow.ID {
        let funcName = keyPath.funcName()
        guard let cadence = CadenceManager.shared.current[keyPath: keyPath]?.toFunc() else {
            EventTrack.General
                .rpcError(
                    error: CadenceError.empty.errorLog,
                    scriptId: funcName
                )
            log.error("[Cadence] empty script on \(funcName)")
            throw CadenceError.empty
        }
        let replacedCadence = collection.formatCadence(script: cadence)
        log.info("[Cadence] transaction start on \(funcName)")
        return try await sendTransaction(
            funcName: funcName,
            cadenceStr: replacedCadence,
            argumentList: argumentList
        )
    }

    private static func sendTransaction(
        funcName: String,
        cadenceStr: String,
        argumentList: [Flow.Cadence.FValue]
    ) async throws -> Flow.ID {
        guard let fromAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            log.error("[Cadence] transaction invalid address on \(funcName)")
            throw LLError.invalidAddress
        }
        do {
            let needBridgeFeePayer = RemoteConfigManager.shared.coverBridgeFee && funcName.lowercased().hasSuffix("withpayer")
            let bridgeFeePayerAddress = Flow.Address(hex: RemoteConfigManager.shared.bridgeFeePayer)
            let fromKeyIndex = WalletManager.shared.keyIndex
            let signers = WalletManager.shared.defaultSigners + (needBridgeFeePayer ? [BridgeFeePayer()] : [])
            let tranId = try await flow
                .sendTransaction(signers: signers) {
                    cadence {
                        cadenceStr
                    }

                    payer {
                        if needBridgeFeePayer {
                            RemoteConfigManager.shared.bridgeFeePayer
                        } else {
                            RemoteConfigManager.shared.payer
                        }
                    }
                    arguments {
                        argumentList
                    }
                    proposer {
                        Flow.TransactionProposalKey(
                            address: Flow.Address(hex: fromAddress),
                            keyIndex: fromKeyIndex
                        )
                    }

                    authorizers {
                        if needBridgeFeePayer {
                            [Flow.Address(hex: fromAddress), bridgeFeePayerAddress]
                        } else {
                            [Flow.Address(hex: fromAddress)]
                        }
                    }

                    gasLimit {
                        9999
                    }
                }
            log.info("[Flow] transaction Id:\(tranId.description)")
            EventTrack.Transaction
                .flowSigned(
                    cadence: hashCadence(cadence: cadenceStr.toHexEncodedString()),
                    txId: tranId.hex,
                    authorizers: [fromAddress],
                    proposer: fromAddress,
                    payer: RemoteConfigManager.shared.payer,
                    success: true
                )
            await scriptStore.setScriptId(tranId.description, funcName)
            return tranId
        } catch {
            EventTrack.General
                .rpcError(
                    error: error.localizedDescription,
                    scriptId: funcName
                )
            EventTrack.Transaction
                .flowSigned(
                    cadence: hashCadence(cadence: cadenceStr.toHexEncodedString()),
                    txId: "",
                    authorizers: [fromAddress],
                    proposer: fromAddress,
                    payer: RemoteConfigManager.shared.payer,
                    success: false
                )
            log.error("[Cadence] transaction error:\(error.localizedDescription)")
            throw error
        }
    }

    private static func sendTransaction(
        by keyPath: KeyPath<CadenceModel, String?>,
        address: Flow.Address,
        keyIndex: Int,
        sequenceNum: Int64,
        signers: [FlowSigner],
        argumentList: [Flow.Cadence.FValue]
    ) async throws -> Flow.ID {
        let funcName = keyPath.funcName()
        guard let cadenceStr = CadenceManager.shared.current[keyPath: keyPath]?.toFunc() else {
            EventTrack.General
                .rpcError(
                    error: CadenceError.empty.errorLog,
                    scriptId: funcName
                )
            log.error("[Cadence] empty script on \(funcName)")
            throw CadenceError.empty
        }
        let replacedCadence = cadenceStr.replace(by: ScriptAddress.addressMap())
        do {
            let tranId = try await flow.sendTransaction(signers: signers) {
                cadence {
                    replacedCadence
                }

                payer {
                    RemoteConfigManager.shared.payer
                }
                arguments {
                    argumentList
                }
                proposer {
                    Flow.TransactionProposalKey(
                        address: address,
                        keyIndex: keyIndex,
                        sequenceNumber: sequenceNum
                    )
                }

                authorizers {
                    address
                }

                gasLimit {
                    9999
                }
            }
            log.info("[Flow] transaction Id:\(tranId.description)")
            EventTrack.Transaction
                .flowSigned(
                    cadence: hashCadence(cadence: cadenceStr.toHexEncodedString()),
                    txId: tranId.hex,
                    authorizers: [address.hex],
                    proposer: address.hex,
                    payer: RemoteConfigManager.shared.payer,
                    success: true
                )
            await scriptStore.setScriptId(tranId.description, funcName)
            return tranId
        } catch {
            EventTrack.General
                .rpcError(
                    error: error.localizedDescription,
                    scriptId: funcName
                )
            EventTrack.Transaction
                .flowSigned(
                    cadence: hashCadence(cadence: cadenceStr.toHexEncodedString()),
                    txId: "",
                    authorizers: [address.hex],
                    proposer: address.hex,
                    payer: RemoteConfigManager.shared.payer,
                    success: false
                )
            log.error("[Cadence] transaction error:\(error.localizedDescription)")
            throw error
        }
    }

    private static func hashCadence(cadence: String) -> String {
        guard !cadence.isEmpty else {
            return ""
        }
        let data = Data(cadence.utf8)
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        return hashString
    }
}

// MARK: - Helper Category

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
        compare(version, options: .numeric)
    }

    public func parseToBigUInt(decimals: Int = 18) -> BigUInt? {
        let separators = CharacterSet(charactersIn: ".,")
        let components = trimmingCharacters(in: .whitespacesAndNewlines).components(
            separatedBy: separators
        )
        guard components.count == 1 || components.count == 2 else { return nil }
        let unitDecimals = decimals
        guard let beforeDecPoint = BigUInt(components[0], radix: 10) else { return nil }
        var mainPart = beforeDecPoint * BigUInt(10).power(unitDecimals)
        if components.count == 2 {
            var part = components[1]
            var numDigits = part.count
            if numDigits > unitDecimals {
                part = String(part.prefix(unitDecimals))
                numDigits = part.count
            }
            guard let afterDecPoint = BigUInt(part, radix: 10) else { return nil }
            let extraPart = afterDecPoint * BigUInt(10).power(unitDecimals - numDigits)
            mainPart += extraPart
        }
        return mainPart
    }
}

private extension KeyPath {
    func funcName() -> String {
        "\(self)".split(separator: ".").last?.replacingOccurrences(
            of: "?",
            with: ""
        ) ?? ""
    }
}
