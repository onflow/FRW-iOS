//
//  BridgeConversionExamples.swift
//  FRW
//
//  Created by Auto-generated on 2025-01-08.
//  Examples of how to use the bridge model conversion functions
//

import Foundation

// MARK: - Bridge Conversion Examples

class BridgeConversionExamples {
    
    // MARK: - TokenModel Conversion Examples
    
    /// Example: Convert RNTokenModel to RNBridge.TokenModel
    static func exampleTokenToBridge() {
        // Create an RNTokenModel instance
        let tokenModel = RNTokenModel.mockFlow()
        
        // Convert to bridge model for communication with React Native
        let bridgeModel = tokenModel.toBridgeModel()
        
        // The bridge model can now be serialized and sent to React Native
        print("Bridge TokenModel type: \(bridgeModel.type)")
        print("Bridge TokenModel name: \(bridgeModel.name)")
    }
    
    /// Example: Convert RNBridge.TokenModel back to RNTokenModel
    static func exampleTokenFromBridge() {
        // Simulate receiving a bridge model from React Native
        let bridgeModel = RNBridge.TokenModel(
            type: .flow,
            name: "Flow Token",
            symbol: "FLOW",
            description: "The native token of Flow blockchain",
            balance: "100000000",
            contractAddress: "1654653399040a61",
            contractName: "FlowToken",
            storagePath: RNBridge.FlowPath(domain: "storage", identifier: "flowTokenVault"),
            receiverPath: RNBridge.FlowPath(domain: "public", identifier: "flowTokenReceiver"),
            balancePath: RNBridge.FlowPath(domain: "public", identifier: "flowTokenBalance"),
            identifier: "A.1654653399040a61.FlowToken",
            isVerified: true,
            logoURI: "https://example.com/flow-logo.svg",
            priceInUSD: "0.50",
            balanceInUSD: "50.0",
            priceInFLOW: "1.0",
            balanceInFLOW: "100.0",
            currency: "USD",
            priceInCurrency: "0.50",
            balanceInCurrency: "50.0",
            displayBalance: "100.0",
            availableBalanceToUse: "100.0",
            change: nil,
            decimal: 8,
            evmAddress: nil,
            website: "https://flow.com"
        )
        
        // Convert to RNTokenModel for use in native code
        let tokenModel = RNTokenModel.fromBridgeModel(bridgeModel)
        
        print("RN TokenModel type: \(tokenModel.type)")
        print("RN TokenModel name: \(tokenModel.name)")
        print("RN TokenModel is Flow: \(tokenModel.isFlow())")
    }
    
    /// Example: Convert array of tokens
    static func exampleTokenArrayConversion() {
        let tokens = [RNTokenModel.mockFlow(), RNTokenModel.mockUSDC()]
        
        // Convert array to bridge models
        let bridgeModels = RNTokenModel.toBridgeModels(tokens)
        
        // Convert back to RN models
        let convertedTokens = RNTokenModel.fromBridgeModels(bridgeModels)
        
        print("Original tokens count: \(tokens.count)")
        print("Bridge models count: \(bridgeModels.count)")
        print("Converted tokens count: \(convertedTokens.count)")
    }
    
    // MARK: - NFTModel Conversion Examples
    
    /// Example: Convert RNNFTModel to RNBridge.NFTModel
    static func exampleNFTToBridge() {
        // Create an RNNFTModel instance
        let nftModel = RNNFTModel.mockFlowNFT()
        
        // Convert to bridge model for communication with React Native
        let bridgeModel = nftModel.toBridgeModel()
        
        // The bridge model can now be serialized and sent to React Native
        print("Bridge NFTModel type: \(bridgeModel.type)")
        print("Bridge NFTModel name: \(bridgeModel.name ?? "Unknown")")
        print("Bridge NFTModel is Flow: \(bridgeModel.type == .flow)")
    }
    
    /// Example: Convert RNBridge.NFTModel back to RNNFTModel
    static func exampleNFTFromBridge() {
        // Simulate receiving a bridge model from React Native
        let bridgePostMedia = RNBridge.NFTPostMedia(
            image: "https://example.com/nft-image.jpg",
            isSvg: false,
            description: "Cool NFT image",
            title: "My NFT"
        )
        
        let bridgeModel = RNBridge.NFTModel(
            id: "12345",
            name: "Cool NFT",
            description: "A very cool NFT",
            thumbnail: "https://example.com/nft-thumbnail.jpg",
            externalURL: "https://example.com/nft",
            collectionName: "Cool Collection",
            collectionContractName: "CoolContract",
            contractAddress: "A.1234567890abcdef.CoolContract",
            evmAddress: nil,
            address: "A.1234567890abcdef.CoolContract",
            contractName: "CoolContract",
            collectionDescription: "A collection of cool NFTs",
            collectionSquareImage: "https://example.com/collection-square.jpg",
            collectionBannerImage: "https://example.com/collection-banner.jpg",
            collectionExternalURL: "https://example.com/collection",
            flowIdentifier: "A.1234567890abcdef.CoolContract.NFT",
            postMedia: bridgePostMedia,
            contractType: nil,
            amount: "1",
            type: .flow
        )
        
        // Convert to RNNFTModel for use in native code
        let nftModel = RNNFTModel.fromBridgeModel(bridgeModel)
        
        print("RN NFTModel type: \(nftModel.type)")
        print("RN NFTModel name: \(nftModel.name ?? "Unknown")")
        print("RN NFTModel is Flow: \(nftModel.isFlowNFT())")
        print("RN NFTModel cover: \(nftModel.getCover())")
    }
    
    /// Example: Convert array of NFTs
    static func exampleNFTArrayConversion() {
        let nfts = [RNNFTModel.mockFlowNFT(), RNNFTModel.mockERC721NFT(), RNNFTModel.mockERC1155NFT()]
        
        // Convert array to bridge models
        let bridgeModels = RNNFTModel.toBridgeModels(nfts)
        
        // Convert back to RN models
        let convertedNFTs = RNNFTModel.fromBridgeModels(bridgeModels)
        
        print("Original NFTs count: \(nfts.count)")
        print("Bridge models count: \(bridgeModels.count)")
        print("Converted NFTs count: \(convertedNFTs.count)")
    }
    
    // MARK: - Testing Functions
    
    /// Run all conversion tests
    static func runAllTests() -> Bool {
        print("🧪 Running bridge conversion tests...")
        
        let tokenTestPassed = RNTokenModel.testBridgeConversion()
        print("TokenModel bridge conversion test: \(tokenTestPassed ? "✅ PASSED" : "❌ FAILED")")
        
        let nftTestPassed = RNNFTModel.testBridgeConversion()
        print("NFTModel bridge conversion test: \(nftTestPassed ? "✅ PASSED" : "❌ FAILED")")
        
        let allTestsPassed = tokenTestPassed && nftTestPassed
        print("All tests: \(allTestsPassed ? "✅ PASSED" : "❌ FAILED")")
        
        return allTestsPassed
    }
    
    /// Run all examples
    static func runAllExamples() {
        print("🚀 Running bridge conversion examples...")
        
        print("\n--- TokenModel Examples ---")
        exampleTokenToBridge()
        exampleTokenFromBridge()
        exampleTokenArrayConversion()
        
        print("\n--- NFTModel Examples ---")
        exampleNFTToBridge()
        exampleNFTFromBridge()
        exampleNFTArrayConversion()
        
        print("\n--- Running Tests ---")
        _ = runAllTests()
    }
}

// MARK: - Usage in Bridge Modules

extension BridgeConversionExamples {
    
    /// Example of how to use in a React Native bridge method
    static func exampleBridgeMethod(tokenData: [String: Any]) -> [String: Any]? {
        // 1. Convert from React Native data to RNTokenModel
        guard let tokenModel = RNTokenModel.fromDictionary(tokenData) else {
            print("Failed to parse token data from React Native")
            return nil
        }
        
        // 2. Convert to bridge model for internal processing
        let bridgeModel = tokenModel.toBridgeModel()
        
        // 3. Process the bridge model (your business logic here)
        // ... do some processing ...
        
        // 4. Convert back to RNTokenModel if needed
        let processedTokenModel = RNTokenModel.fromBridgeModel(bridgeModel)
        
        // 5. Convert to dictionary for React Native
        return processedTokenModel.toDictionary()
    }
}