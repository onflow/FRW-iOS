//
//  TokenBalanceProviderTests.swift
//  FRWTests
//
//  Created by Marty Ulrich on 3/13/25.
//

import Testing
@testable import FRW

struct TokenBalanceProviderTests {
    
    @Test func testFetchNFTsInCollection () async throws {
        let tokenBalanceProvider = TokenBalanceHandler.shared
        let nftsCount = try await tokenBalanceProvider.getAllNFTs(address: FWAddressDector.create(address: "0x37a7e864611c7a85")!, collectionIdentifier: "MomentCollection") { progress in
            print("PROGRESS: \(progress)")
        }.count
        
        var offset = 0
        var nftsPagedCount = try await fetchMomentCollection(offset: offset)?.count ?? 0
        offset += nftsPagedCount
        
        while let page = try await fetchMomentCollection(offset: offset) {
            nftsPagedCount += page.count
            offset += page.count
        }

        #expect(nftsCount == nftsPagedCount)
    }
    
    private func fetchMomentCollection(offset: Int) async throws -> [NFTResponse]? {
        let page = try await TokenBalanceHandler.shared
            .getNFTCollectionDetail(
                address: FWAddressDector.create(address: "0x37a7e864611c7a85")!,
                collectionIdentifier: "MomentCollection", offset: offset
            ).nfts
        if page?.isEmpty == true {
            return nil
        } else {
            return page
        }
    }
}
