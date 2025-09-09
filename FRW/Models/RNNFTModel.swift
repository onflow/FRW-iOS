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
    let image: String?
    let isSvg: Bool?
    let description: String?
    let title: String?
    
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
}

// MARK: - RNNFTModel

/// NFTModel that exactly matches RN NFTModel structure (extends NFT interface)
struct RNNFTModel: Codable, Hashable, Identifiable {
    
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
    
    // MARK: - Convenience Methods (matching RN functions)
    
    /// Get NFT cover image (matching getNFTCover function)
    func getCover() -> String {
        if let thumbnail = thumbnail, !thumbnail.isEmpty {
            return thumbnail
        }
        if let image = postMedia?.image, !image.isEmpty {
            return image
        }
        return ""
    }
    
    /// Get NFT ID (matching getNFTId function)
    func getNFTId() -> String {
        return id ?? address ?? ""
    }
    
    /// Get search text (matching getNFTSearchText function)
    func getSearchText() -> String {
        let nameText = name ?? ""
        let descText = description ?? ""
        let mediaDescText = postMedia?.description ?? ""
        return "\(nameText) \(descText) \(mediaDescText)"
    }
    
    /// Check if this is ERC1155 (matching isERC1155 function)
    func isERC1155() -> Bool {
        return contractType == "ERC1155"
    }
    
    /// Check if this is ERC721
    func isERC721() -> Bool {
        return contractType == "ERC721"
    }
    
    /// Check if this is a Flow NFT
    func isFlowNFT() -> Bool {
        return type == .Flow
    }
    
    /// Check if this is an EVM NFT
    func isEVMNFT() -> Bool {
        return type == .EVM
    }
}

// MARK: - Dictionary Conversion

extension RNNFTModel {
    
    /// Convert to dictionary for bridge communication
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Core NFT properties
        dict["id"] = id
        dict["name"] = name
        dict["description"] = description
        dict["thumbnail"] = thumbnail
        dict["externalURL"] = externalURL
        
        // Collection properties
        dict["collectionName"] = collectionName
        dict["collectionContractName"] = collectionContractName
        dict["collectionDescription"] = collectionDescription
        dict["collectionSquareImage"] = collectionSquareImage
        dict["collectionBannerImage"] = collectionBannerImage
        dict["collectionExternalURL"] = collectionExternalURL
        
        // Contract properties
        dict["contractAddress"] = contractAddress
        dict["evmAddress"] = evmAddress
        dict["address"] = address
        dict["contractName"] = contractName
        dict["contractType"] = contractType
        
        // Flow properties
        dict["flowIdentifier"] = flowIdentifier
        
        // Media properties
        if let postMedia = postMedia {
            var postMediaDict: [String: Any] = [:]
            postMediaDict["image"] = postMedia.image
            postMediaDict["isSvg"] = postMedia.isSvg
            postMediaDict["description"] = postMedia.description
            postMediaDict["title"] = postMedia.title
            dict["postMedia"] = postMediaDict
        }
        
        // Amount and type
        dict["amount"] = amount
        dict["type"] = type.rawValue
        
        return dict
    }
    
    /// Create from dictionary (from bridge communication)
    static func fromDictionary(_ dict: [String: Any]) -> RNNFTModel? {
        guard let typeString = dict["type"] as? String,
              let type = RNWalletType(rawValue: typeString) else {
            // If no type specified, try to determine from addresses
            let hasEvmAddress = dict["evmAddress"] as? String != nil
            let inferredType: RNWalletType = hasEvmAddress ? .EVM : .Flow
            
            return createFromDict(dict, type: inferredType)
        }
        
        return createFromDict(dict, type: type)
    }
    
    private static func createFromDict(_ dict: [String: Any], type: RNWalletType) -> RNNFTModel {
        // Parse postMedia if exists
        var postMedia: RNNFTPostMedia?
        if let postMediaDict = dict["postMedia"] as? [String: Any] {
            postMedia = RNNFTPostMedia(
                image: postMediaDict["image"] as? String,
                isSvg: postMediaDict["isSvg"] as? Bool,
                description: postMediaDict["description"] as? String,
                title: postMediaDict["title"] as? String
            )
        }
        
        return RNNFTModel(
            id: dict["id"] as? String,
            name: dict["name"] as? String,
            description: dict["description"] as? String,
            thumbnail: dict["thumbnail"] as? String,
            externalURL: dict["externalURL"] as? String,
            collectionName: dict["collectionName"] as? String,
            collectionContractName: dict["collectionContractName"] as? String,
            contractAddress: dict["contractAddress"] as? String,
            evmAddress: dict["evmAddress"] as? String,
            address: dict["address"] as? String,
            contractName: dict["contractName"] as? String,
            collectionDescription: dict["collectionDescription"] as? String,
            collectionSquareImage: dict["collectionSquareImage"] as? String,
            collectionBannerImage: dict["collectionBannerImage"] as? String,
            collectionExternalURL: dict["collectionExternalURL"] as? String,
            flowIdentifier: dict["flowIdentifier"] as? String,
            postMedia: postMedia,
            contractType: dict["contractType"] as? String,
            amount: dict["amount"] as? String,
            type: type
        )
    }
}

// MARK: - Mock Data

extension RNNFTModel {
    
    /// Create mock Flow NFT
    static func mockFlowNFT() -> RNNFTModel {
        return RNNFTModel(
            id: "12345",
            name: "Cool Flow NFT",
            description: "A very cool NFT on Flow blockchain",
            thumbnail: "https://example.com/flow-nft-thumbnail.jpg",
            externalURL: "https://example.com/flow-nft",
            collectionName: "Cool Flow Collection",
            collectionContractName: "CoolFlowContract",
            contractAddress: "A.1234567890abcdef.CoolFlowContract",
            evmAddress: nil,
            address: "A.1234567890abcdef.CoolFlowContract",
            contractName: "CoolFlowContract",
            collectionDescription: "A collection of cool Flow NFTs",
            collectionSquareImage: "https://example.com/flow-collection-square.jpg",
            collectionBannerImage: "https://example.com/flow-collection-banner.jpg",
            collectionExternalURL: "https://example.com/flow-collection",
            flowIdentifier: "A.1234567890abcdef.CoolFlowContract.NFT",
            postMedia: RNNFTPostMedia(
                image: "https://example.com/flow-nft-image.jpg",
                isSvg: false,
                description: "Flow NFT image description",
                title: "Cool Flow NFT"
            ),
            contractType: nil, // Flow NFTs don't use ERC standards
            amount: "1",
            type: .Flow
        )
    }
    
    /// Create mock EVM ERC721 NFT
    static func mockERC721NFT() -> RNNFTModel {
        return RNNFTModel(
            id: "67890",
            name: "Cool ERC721 NFT",
            description: "A very cool ERC721 NFT on EVM",
            thumbnail: "https://example.com/erc721-nft-thumbnail.jpg",
            externalURL: "https://example.com/erc721-nft",
            collectionName: "Cool ERC721 Collection",
            collectionContractName: "CoolERC721Contract",
            contractAddress: nil,
            evmAddress: "0x1234567890abcdef1234567890abcdef12345678",
            address: "0x1234567890abcdef1234567890abcdef12345678",
            contractName: "CoolERC721Contract",
            collectionDescription: "A collection of cool ERC721 NFTs",
            collectionSquareImage: "https://example.com/erc721-collection-square.jpg",
            collectionBannerImage: "https://example.com/erc721-collection-banner.jpg",
            collectionExternalURL: "https://example.com/erc721-collection",
            flowIdentifier: nil,
            postMedia: RNNFTPostMedia(
                image: "https://example.com/erc721-nft-image.jpg",
                isSvg: false,
                description: "ERC721 NFT image description",
                title: "Cool ERC721 NFT"
            ),
            contractType: "ERC721",
            amount: "1",
            type: .EVM
        )
    }
    
    /// Create mock EVM ERC1155 NFT
    static func mockERC1155NFT() -> RNNFTModel {
        return RNNFTModel(
            id: "11111",
            name: "Cool ERC1155 NFT",
            description: "A very cool ERC1155 NFT on EVM",
            thumbnail: "https://example.com/erc1155-nft-thumbnail.jpg",
            externalURL: "https://example.com/erc1155-nft",
            collectionName: "Cool ERC1155 Collection",
            collectionContractName: "CoolERC1155Contract",
            contractAddress: nil,
            evmAddress: "0xabcdef1234567890abcdef1234567890abcdef12",
            address: "0xabcdef1234567890abcdef1234567890abcdef12",
            contractName: "CoolERC1155Contract",
            collectionDescription: "A collection of cool ERC1155 NFTs",
            collectionSquareImage: "https://example.com/erc1155-collection-square.jpg",
            collectionBannerImage: "https://example.com/erc1155-collection-banner.jpg",
            collectionExternalURL: "https://example.com/erc1155-collection",
            flowIdentifier: nil,
            postMedia: RNNFTPostMedia(
                image: "https://example.com/erc1155-nft-image.jpg",
                isSvg: false,
                description: "ERC1155 NFT image description",
                title: "Cool ERC1155 NFT"
            ),
            contractType: "ERC1155",
            amount: "5", // ERC1155 can have multiple amounts
            type: .EVM
        )
    }
}

// MARK: - Conversion to RNBridge.NFTModel

extension RNNFTModel {
    
    /// Convert to RNBridge.NFTModel for codegen bridge communication
    func toBridgeModel() -> RNBridge.NFTModel {
        // Convert RNWalletType to RNBridge.WalletType
        let bridgeType: RNBridge.WalletType = (type == .Flow) ? .flow : .evm
        
        // Convert RNNFTPostMedia to RNBridge.NFTPostMedia
        let bridgePostMedia = postMedia.map { media in
            RNBridge.NFTPostMedia(
                image: media.image,
                isSvg: media.isSvg,
                description: media.description,
                title: media.title
            )
        }
        
        return RNBridge.NFTModel(
            id: id,
            name: name,
            description: description,
            thumbnail: thumbnail,
            externalURL: externalURL,
            collectionName: collectionName,
            collectionContractName: collectionContractName,
            contractAddress: contractAddress,
            evmAddress: evmAddress,
            address: address,
            contractName: contractName,
            collectionDescription: collectionDescription,
            collectionSquareImage: collectionSquareImage,
            collectionBannerImage: collectionBannerImage,
            collectionExternalURL: collectionExternalURL,
            flowIdentifier: flowIdentifier,
            postMedia: bridgePostMedia,
            contractType: contractType,
            amount: amount,
            type: bridgeType
        )
    }
    
    /// Convert from RNBridge.NFTModel to RNNFTModel
    static func fromBridgeModel(_ bridgeModel: RNBridge.NFTModel) -> RNNFTModel {
        // Convert RNBridge.WalletType to RNWalletType
        let rnType: RNWalletType = (bridgeModel.type == .flow) ? .Flow : .EVM
        
        // Convert RNBridge.NFTPostMedia to RNNFTPostMedia
        let rnPostMedia = bridgeModel.postMedia.map { media in
            RNNFTPostMedia(
                image: media.image,
                isSvg: media.isSvg,
                description: media.description,
                title: media.title
            )
        }
        
        return RNNFTModel(
            id: bridgeModel.id,
            name: bridgeModel.name,
            description: bridgeModel.description,
            thumbnail: bridgeModel.thumbnail,
            externalURL: bridgeModel.externalURL,
            collectionName: bridgeModel.collectionName,
            collectionContractName: bridgeModel.collectionContractName,
            contractAddress: bridgeModel.contractAddress,
            evmAddress: bridgeModel.evmAddress,
            address: bridgeModel.address,
            contractName: bridgeModel.contractName,
            collectionDescription: bridgeModel.collectionDescription,
            collectionSquareImage: bridgeModel.collectionSquareImage,
            collectionBannerImage: bridgeModel.collectionBannerImage,
            collectionExternalURL: bridgeModel.collectionExternalURL,
            flowIdentifier: bridgeModel.flowIdentifier,
            postMedia: rnPostMedia,
            contractType: bridgeModel.contractType,
            amount: bridgeModel.amount,
            type: rnType
        )
    }
    
    /// Convert array of RNNFTModels to RNBridge.NFTModels
    static func toBridgeModels(_ nftModels: [RNNFTModel]) -> [RNBridge.NFTModel] {
        return nftModels.map { $0.toBridgeModel() }
    }
    
    /// Convert array of RNBridge.NFTModels to RNNFTModels
    static func fromBridgeModels(_ bridgeModels: [RNBridge.NFTModel]) -> [RNNFTModel] {
        return bridgeModels.map { fromBridgeModel($0) }
    }
}

// MARK: - Conversion from Native NFTModel

extension RNNFTModel {
    
    /// Convert from native NFTModel to RNNFTModel
    static func fromNFTModel(_ nftModel: NFTModel) -> RNNFTModel {
        // Determine wallet type based on available addresses
        let rnType: RNWalletType = nftModel.response.evmAddress != nil ? .EVM : .Flow
        
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
        
        // Determine contract type based on EVM address
        var contractType: String?
        if nftModel.response.evmAddress != nil {
            // Default to ERC721 for EVM NFTs, could be enhanced with actual contract type detection
            contractType = "ERC721"
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
            contractType: contractType,
            amount: "1", // Default to 1, could be enhanced with actual amount detection
            type: rnType
        )
    }
    
    /// Convert array of native NFTModels to RNNFTModels
    static func fromNFTModels(_ nftModels: [NFTModel]) -> [RNNFTModel] {
        return nftModels.map { fromNFTModel($0) }
    }
}

// MARK: - Testing & Validation

extension RNNFTModel {
    
    /// Test conversion to and from bridge models
    static func testBridgeConversion() -> Bool {
        // Create a test NFT
        let originalNFT = RNNFTModel.mockFlowNFT()
        
        // Convert to bridge model
        let bridgeModel = originalNFT.toBridgeModel()
        
        // Convert back to RN model
        let convertedNFT = RNNFTModel.fromBridgeModel(bridgeModel)
        
        // Verify all properties match
        return originalNFT.id == convertedNFT.id &&
               originalNFT.name == convertedNFT.name &&
               originalNFT.description == convertedNFT.description &&
               originalNFT.thumbnail == convertedNFT.thumbnail &&
               originalNFT.externalURL == convertedNFT.externalURL &&
               originalNFT.collectionName == convertedNFT.collectionName &&
               originalNFT.collectionContractName == convertedNFT.collectionContractName &&
               originalNFT.contractAddress == convertedNFT.contractAddress &&
               originalNFT.evmAddress == convertedNFT.evmAddress &&
               originalNFT.address == convertedNFT.address &&
               originalNFT.contractName == convertedNFT.contractName &&
               originalNFT.collectionDescription == convertedNFT.collectionDescription &&
               originalNFT.collectionSquareImage == convertedNFT.collectionSquareImage &&
               originalNFT.collectionBannerImage == convertedNFT.collectionBannerImage &&
               originalNFT.collectionExternalURL == convertedNFT.collectionExternalURL &&
               originalNFT.flowIdentifier == convertedNFT.flowIdentifier &&
               originalNFT.contractType == convertedNFT.contractType &&
               originalNFT.amount == convertedNFT.amount &&
               originalNFT.type == convertedNFT.type &&
               originalNFT.postMedia?.image == convertedNFT.postMedia?.image &&
               originalNFT.postMedia?.isSvg == convertedNFT.postMedia?.isSvg &&
               originalNFT.postMedia?.description == convertedNFT.postMedia?.description &&
               originalNFT.postMedia?.title == convertedNFT.postMedia?.title
    }
}