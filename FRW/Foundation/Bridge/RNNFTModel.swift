//
//  RNNFTModel.swift
//  FRW
//
//  Created by Auto-generated on 2025-01-08.
//  Model that matches RN NFTModel structure for cross-platform compatibility
//

import Foundation


extension RNBridge.NFTModel {
  /// Convert from native NFTModel to RNNFTModel
  static func fromNFTModel(_ nftModel: NFTModel?) -> RNBridge.NFTModel? {
    guard let nftModel else {
      return nil
    }
    // Determine wallet type based on available addresses
    let rnType: RNBridge.WalletType = WalletManager.shared.selectedAccount?.vmType == .evm ? .evm : .flow

    // Convert postMedia if exists
    var rnPostMedia: RNBridge.NFTPostMedia?
    if let postMedia = nftModel.response.postMedia {
      rnPostMedia = RNBridge.NFTPostMedia(image: postMedia.image, isSvg: postMedia.isSvg, description: postMedia.description, title: postMedia.title)
    }

    return RNBridge.NFTModel(
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
  static func fromNFTModels(_ nftModels: [NFTModel]?) -> [RNBridge.NFTModel]? {
    guard let nftModels else {
      return nil
    }
    return nftModels.compactMap { fromNFTModel($0) }
  }
}
