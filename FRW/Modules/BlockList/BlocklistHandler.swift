//
//  BlocklistHandler.swift
//  FRW
//
//  Created by cat on 4/8/25.
//

import Foundation

final class BlocklistHandler {
    static let shared = BlocklistHandler()

    private var domains: BlocklistResponse = .empty

    private init() {
        fetch()
    }

    func fetch() {
        Task {
            do {
                self.domains = try await Network.requestWithRawModel(FRWAPI.Blocklist.domain)
                log.debug("Domain Block List:\(self.domains.flow.count)-\(self.domains.evm.count)")
            } catch {
                log.error("Domain Block List:\(error.localizedDescription)")
            }
        }
    }

    func inBlacklist(url: String, withType: AccountType = .flow) -> Bool {
        // TODO: #six This needs to be confirmed
        let result = withType == .flow ? domains.flow.filter { url.contains($0) } : domains.evm.filter { url.contains($0) }
        return result.count > 0
    }
}
