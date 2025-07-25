//
//  CadenceModel.swift
//  FRW
//
//  Created by Hao Fu on 14/4/2025.
//

import Foundation

// MARK: - CadenceResponse

struct CadenceResponse: Codable {
    let scripts: CadenceScript
    let version: String?
}

// MARK: - CadenceScript

struct CadenceScript: Codable {
    let testnet: CadenceModel
    let mainnet: CadenceModel
}

// MARK: - CadenceModel

struct CadenceModel: Codable {
    let version: String?
    let basic: CadenceModel.Basic?
    let account: CadenceModel.Account?
    let collection: CadenceModel.Collection?
    let contract: CadenceModel.Contract?
    let domain: CadenceModel.Domain?
    let ft: CadenceModel.FlowToken?

    let hybridCustody: CadenceModel.HybridCustody?
    let staking: CadenceModel.Staking?
    let storage: CadenceModel.Storage?
    let switchboard: CadenceModel.Switchboard?
    let nft: CadenceModel.NFT?
    let swap: CadenceModel.Swap?

    let evm: CadenceModel.EVM?
    let bridge: CadenceModel.Bridge?
}

extension CadenceModel {
    struct Basic: Codable {
        let addKey: String?
        let getAccountInfo: String?
        let getFindAddress: String?
        let getFindDomainByAddress: String?
        let getFlownsAddress: String?
        let getFlownsDomainsByAddress: String?
        let getStorageInfo: String?
        let getTokenBalanceWithModel: String?
        let isTokenStorageEnabled: String?
        let revokeKey: String?
        let getAccountMinFlow: String?
        let getFlowBalanceForAnyAccounts: String?
    }

    struct Account: Codable {
        let getBookmark: String?
        let getBookmarks: String?
    }

    struct Collection: Codable {
        let enableNFTStorage: String?
        let getCatalogTypeData: String?
        let getNFT: String?
        let getNFTCatalogByCollectionIds: String?
        let getNFTCollection: String?
        let getNFTDisplays: String?
        let getNFTMetadataViews: String?
        let sendNbaNFTV3: String?
        let sendNFTV3: String?
        /// 2.6+, replace checkNFTListEnabled
        let getNFTBalanceStorage: String?
    }

    struct Contract: Codable {
        let getContractNames: String?
        let getContractByName: String?
    }

    struct Domain: Codable {
        let claimNFTFromInbox: String?
        let getAddressOfDomain: String?
        let getDefaultDomainsOfAddress: String?
        let getFlownsInbox: String?
        let sendInboxNFT: String?
        let transferInboxTokens: String?
    }

    struct FlowToken: Codable {
        let addToken: String?
        let enableTokenStorage: String?
        let transferTokensV3: String?

        let isTokenListEnabled: String?
        let getTokenListBalance: String?

        let getTokenBalanceStorage: String?
    }

    struct HybridCustody: Codable {
        let editChildAccount: String?
        let getAccessibleCoinInfo: String?
        let getAccessibleCollectionAndIds: String?
        let getAccessibleCollectionAndIdsDisplay: String?
        let getAccessibleCollectionsAndIds: String?

        let getAccessibleFungibleToken: String?
        let getChildAccount: String?
        let getChildAccountMeta: String?
        let getChildAccountNFT: String?
        let unlinkChildAccount: String?

        let transferChildNFT: String?
        let transferNFTToChild: String?
        let sendChildNFT: String?
        let getChildAccountAllowTypes: String?
        let checkChildLinkedCollections: String?
        let batchTransferChildNFT: String?
        let batchTransferNFTToChild: String?
        /// child to child
        let batchSendChildNFTToChild: String?
        /// send NFT from child to child
        let sendChildNFTToChild: String?

        let bridgeChildNFTToEvm: String?
        let bridgeChildNFTFromEvm: String?

        let batchBridgeChildNFTToEvm: String?
        let batchBridgeChildNFTFromEvm: String?

        let bridgeChildFTToEvm: String?
        let bridgeChildFTFromEvm: String?
    }

    struct Staking: Codable {
        let checkSetup: String?

        let createDelegator: String?
        let createStake: String?
        let getApr: String?
        let getDelegatesInfoV2: String?
        let getEpochMetadata: String?
        let getNodeInfo: String?
        let getNodesInfo: String?

        let getDelegatesInfoArrayV2: String?
        let getApyWeekly: String?

        let getStakeInfo: String?
        let getStakingInfo: String?
        let restakeReward: String?
        let restakeUnstaked: String?

        let setup: String?
        let unstake: String?
        let withdrawLocked: String?
        let withdrawReward: String?
        let withdrawUnstaked: String?

        let checkStakingEnabled: String?
    }

    struct Storage: Codable {
        let enableTokenStorage: String?
        let getBasicPublicItems: String?
        let getPrivateItems: String?
        let getPrivatePaths: String?
        let getPublicItem: String?
        let getPublicItems: String?
        let getPublicPaths: String?
        let getStoragePaths: String?
        let getStoredItems: String?
        let getStoredResource: String?
        let getStoredStruct: String?

        let getBasicPublicItemsTest: String?
        let getPrivateItemsTest: String?
    }

    struct Switchboard: Codable {
        let getSwitchboard: String?
    }

    struct NFT: Codable {
        let checkNFTListEnabled: String?
    }

    struct Swap: Codable {
        let DeployPairTemplate: String?
        let CreatePairTemplate: String?
        let AddLiquidity: String?
        let RemoveLiquidity: String?
        let SwapExactTokensForTokens: String?
        let SwapTokensForExactTokens: String?
        let MintAllTokens: String?
        let QueryTokenNames: String?

        let QueryPairArrayAddr: String?
        let QueryPairArrayInfo: String?
        let QueryPairInfoByAddrs: String?
        let QueryPairInfoByTokenKey: String?
        let QueryUserAllLiquidities: String?
        let QueryTimestamp: String?

        let QueryVaultBalanceBatched: String?
        let QueryTokenPathPrefix: String?
        let CenterTokens: [String]?
    }
}

extension CadenceModel {
    struct EVM: Codable {
        let call: String?
        let createCoaEmpty: String?
        let deployContract: String?
        let estimateGas: String?
        let fundEvmAddr: String?
        let getBalance: String?
        let getCoaBalance: String?
        let getCoaAddr: String?
        let getCode: String?
        let withdrawCoa: String?
        let fundCoa: String?
        let callContract: String?
        let callContractV2: String?
        let transferFlowToEvmAddress: String?
        let transferFlowFromCoaToFlow: String?
        let checkCoaLink: String?
        let coaLink: String?
        let getNonce: String?
    }

    struct Bridge: Codable {
        let batchOnboardByIdentifier: String?
        let bridgeTokensFromEvmV2: String?
        let bridgeTokensToEvmV2: String?

        let batchBridgeNFTToEvmV2: String?
        let batchBridgeNFTFromEvmV2: String?
        /// send Not Flow Token to Evm
        let bridgeTokensToEvmAddressV2: String?
        /// evm to other flow
        let bridgeTokensFromEvmToFlowV3: String?
        /// nft flow to any evm
        let bridgeNFTToEvmAddressV2: String?
        let bridgeNFTFromEvmToFlowV3: String?

        let getAssociatedEvmAddress: String?
        let getAssociatedFlowIdentifier: String?

        let batchBridgeNFTFromEvmWithPayer: String? //
        let batchBridgeNFTToEvmAddressWithPayer: String?
        let batchBridgeNFTToEvmWithPayer: String? //
        let bridgeNFTFromEvmToFlowWithPayer: String? //
        let bridgeNFTFromEvmWithPayer: String?
        let bridgeNFTToEvmAddressWithPayer: String? //
        let bridgeNFTToEvmWithPayer: String?
    }
}
