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
                self.domains = try await Network.requestWithRawModel(FRWAPI.Blocklist.domain, needAuthToken: false)
                log.debug("Domain Block List:\(self.domains.flow.count)-\(self.domains.evm.count)")
            } catch {
                log.error("Domain Block List:\(error.localizedDescription)")
            }
        }
    }

    func inBlacklist(url: String) -> Bool {
        guard !url.isEmpty else {
            return false
        }
        let list = domains.flow + domains.evm
        let result = list.filter { url.contains($0) }
        return result.count > 0
    }
}
