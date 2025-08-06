//
//  RNNFTModel.swift
//  FRW
//
//  Created by Auto-generated on 2025-01-08.
//  Model that matches RN NFTModel structure for cross-platform compatibility
//

import Foundation

// MARK: - RNNFTPostMedia

/// NFT post media structure matching RN NFTPostMedia
struct RNNFTPostMedia: Codable, Hashable {
  // MARK: Lifecycle

  init(
    image: String? = nil,
    isSvg: Bool? = nil,
    description: String? = nil,
    title: String? = nil
  ) {
    self.image = image
    self.isSvg = isSvg
    self.description = description
    self.title = title
  }

  // MARK: Internal

  let image: String?
  let isSvg: Bool?
  let description: String?
  let title: String?
}

// MARK: - RNNFTModel

/// NFTModel that exactly matches RN NFTModel structure (extends NFT interface)
struct RNNFTModel: Codable, Hashable, Identifiable {
  // MARK: Lifecycle

  // MARK: - Initializer

  init(
    id: String? = nil,
    name: String? = nil,
    description: String? = nil,
    thumbnail: String? = nil,
    externalURL: String? = nil,
    collectionName: String? = nil,
    collectionContractName: String? = nil,
    contractAddress: String? = nil,
    evmAddress: String? = nil,
    address: String? = nil,
    contractName: String? = nil,
    collectionDescription: String? = nil,
    collectionSquareImage: String? = nil,
    collectionBannerImage: String? = nil,
    collectionExternalURL: String? = nil,
    flowIdentifier: String? = nil,
    postMedia: RNNFTPostMedia? = nil,
    contractType: String? = nil,
    amount: String? = nil,
    type: RNWalletType
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.thumbnail = thumbnail
    self.externalURL = externalURL
    self.collectionName = collectionName
    self.collectionContractName = collectionContractName
    self.contractAddress = contractAddress
    self.evmAddress = evmAddress
    self.address = address
    self.contractName = contractName
    self.collectionDescription = collectionDescription
    self.collectionSquareImage = collectionSquareImage
    self.collectionBannerImage = collectionBannerImage
    self.collectionExternalURL = collectionExternalURL
    self.flowIdentifier = flowIdentifier
    self.postMedia = postMedia
    self.contractType = contractType
    self.amount = amount
    self.type = type
  }

  // MARK: Internal

  // MARK: - NFT Interface Properties (from RN service.ts)

  /// Unique identifier for the NFT
  let id: String?

  /// Name of the NFT
  let name: String?

  /// Description of the NFT
  let description: String?

  /// URL to the NFT thumbnail
  let thumbnail: String?

  /// External URL for the NFT
  let externalURL: String?

  /// Name of the collection
  let collectionName: String?

  /// Contract name of the collection
  let collectionContractName: String?

  /// Flow contract address
  let contractAddress: String?

  /// EVM contract address
  let evmAddress: String?

  /// Flow address
  let address: String?

  /// Name of the contract
  let contractName: String?

  /// Description of the collection
  let collectionDescription: String?

  /// URL to the collection square image
  let collectionSquareImage: String?

  /// URL to the collection banner image
  let collectionBannerImage: String?

  /// External URL for the collection
  let collectionExternalURL: String?

  /// Flow identifier
  let flowIdentifier: String?

  /// Media information for the NFT
  let postMedia: RNNFTPostMedia?

  /// Type of the contract ERC721 / ERC1155
  let contractType: String?

  /// Amount of the NFT
  let amount: String?

  // MARK: - NFTModel Extension Properties (from RN NFTModel.ts)

  /// Wallet type (Flow or EVM)
  let type: RNWalletType
}

// MARK: - Conversion from Native NFTModel

extension RNNFTModel {
  /// Convert from native NFTModel to RNNFTModel
  static func fromNFTModel(_ nftModel: NFTModel?) -> RNNFTModel? {
    guard let nftModel else {
      return nil
    }
    // Determine wallet type based on available addresses
    let rnType: RNWalletType = WalletManager.shared.selectedAccount?.vmType == .evm ? .EVM : .Flow

    // Convert postMedia if exists
    var rnPostMedia: RNNFTPostMedia?
    if let postMedia = nftModel.response.postMedia {
      rnPostMedia = RNNFTPostMedia(
        image: postMedia.image,
        isSvg: postMedia.isSvg,
        description: postMedia.description,
        title: postMedia.title
      )
    }

    return RNNFTModel(
      id: nftModel.response.id,
      name: nftModel.response.name,
      description: nftModel.response.description,
      thumbnail: nftModel.response.thumbnail,
      externalURL: nftModel.response.externalURL,
      collectionName: nftModel.response.collectionName,
      collectionContractName: nftModel.response.collectionContractName,
      contractAddress: nftModel.response.contractAddress,
      evmAddress: nftModel.response.evmAddress,
      address: nftModel.response.address,
      contractName: nftModel.collection?.contractName,
      collectionDescription: nftModel.response.collectionDescription,
      collectionSquareImage: nftModel.response.collectionSquareImage,
      collectionBannerImage: nftModel.response.collectionBannerImage,
      collectionExternalURL: nftModel.response.collectionExternalURL,
      flowIdentifier: nftModel.response.flowIdentifier,
      postMedia: rnPostMedia,
      contractType: nftModel.response.contractType,
      amount: nftModel.response.amount,
      type: rnType
    )
  }

  /// Convert array of native NFTModels to RNNFTModels
  static func fromNFTModels(_ nftModels: [NFTModel]?) -> [RNNFTModel]? {
    guard let nftModels else {
      return nil
    }
    return nftModels.compactMap { fromNFTModel($0) }
  }
}
