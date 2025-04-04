//
//  StakingManager.swift
//  Flow Wallet
//
//  Created by Selina on 30/11/2022.
//

import Combine
import Flow
import Foundation
import SwiftUI

let StakingDefaultApy: Double = 0.093
let StakingDefaultNormalApy: Double = 0.09

// 2022-10-27 07:00
private let StakeStartTime: TimeInterval = 1_666_825_200
private let StakingGapSeconds: TimeInterval = 7 * 24 * 60 * 60

// MARK: - StakingManager

class StakingManager: ObservableObject {
    // MARK: Lifecycle

    init() {
        _ = StakingProviderCache.cache
        createFolderIfNeeded()
        loadCache()

        TransactionManager.shared.$holders
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.refresh()
            }.store(in: &cancelSet)

        WalletManager.shared.$selectedAccount
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { account in
                if account.type == .main {
                    self.refresh()
                } else {
                    self.clean()
                }
            }.store(in: &cancelSet)
    }

    // MARK: Internal

    static let shared = StakingManager()

    @Published
    var nodeInfos: [StakingNode] = []
    @Published
    var delegatorIds: [String: Int] = [:]
    @Published
    var apy: Double = StakingDefaultApy
    @Published
    var isSetup: Bool = false

    var stakingCount: Double {
        nodeInfos.reduce(0.0) { partialResult, node in
            partialResult + node.tokensCommitted + node.tokensStaked
        }
    }

    var dayRewards: Double {
        let yearTotalRewards = nodeInfos.reduce(0.0) { partialResult, node in
            let apy = node.isLilico ? apy : StakingDefaultNormalApy
            return partialResult + (node.stakingCount * apy)
        }

        return yearTotalRewards / 365.0
    }

    var monthRewards: Double {
        dayRewards * 30
    }

    var dayRewardsASUSD: Double {
        let token = WalletManager.shared.flowToken
        let coinRate = CoinRateCache.cache.getSummary(by: token?.contractId ?? "")?
            .getLastRate() ?? 0
        return dayRewards * coinRate
    }

    var monthRewardsASUSD: Double {
        let token = WalletManager.shared.flowToken
        let coinRate = CoinRateCache.cache.getSummary(by: token?.contractId ?? "")?
            .getLastRate() ?? 0
        return monthRewards * coinRate
    }

    var isStaked: Bool {
        stakingCount > 0
    }

    var stakingEpochStartTime: Date {
        let current = Date().timeIntervalSince1970
        var startTime = StakeStartTime
        while startTime + StakingGapSeconds < current {
            startTime += StakingGapSeconds
        }

        return Date(timeIntervalSince1970: startTime)
    }

    var stakingEpochEndTime: Date {
        stakingEpochStartTime.addingTimeInterval(StakingGapSeconds)
    }

    func providerForNodeId(_ nodeId: String) -> StakingProvider? {
        StakingProviderCache.cache.providers.first { $0.id == nodeId }
    }

    func refresh() {
        if !UserManager.shared.isLoggedIn {
            return
        }

        if WalletManager.shared.isSelectedChildAccount {
            log.warning("child account should will not refresh staking info")
            return
        }

        log.debug("start refresh")

        updateApy()
        updateSetupStatus()
        queryStakingInfo()
        Task {
            do {
                try await refreshDelegatorInfo()
            } catch {
                debugPrint("StakingManager -> refreshDelegatorInfo failed: \(error)")
            }
        }
    }

    func stakingSetup() async -> Bool {
        do {
            if try await FlowNetwork.accountStakingIsSetup() == true {
                // has been setup
                return true
            }

            let isSetup = try await FlowNetwork.setupAccountStaking()
            await MainActor.run {
                self.isSetup = isSetup
                self.saveCache()
            }

            return isSetup
        } catch {
            debugPrint("StakingManager -> stakingSetup failed: \(error)")
            return false
        }
    }

    func claimReward(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        let txId = try await FlowNetwork.claimReward(
            nodeID: nodeID,
            delegatorId: delegatorId,
            amount: amount
        )
        let holder = TransactionManager.TransactionHolder(id: txId, type: .stakeFlow)
        TransactionManager.shared.newTransaction(holder: holder)
        return txId
    }

    func reStakeReward(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        let txId = try await FlowNetwork.reStakeReward(
            nodeID: nodeID,
            delegatorId: delegatorId,
            amount: amount
        )
        let holder = TransactionManager.TransactionHolder(id: txId, type: .stakeFlow)
        TransactionManager.shared.newTransaction(holder: holder)
        return txId
    }

    func claimUnstake(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        let txId = try await FlowNetwork.claimUnstake(
            nodeID: nodeID,
            delegatorId: delegatorId,
            amount: amount
        )
        let holder = TransactionManager.TransactionHolder(id: txId, type: .stakeFlow)
        TransactionManager.shared.newTransaction(holder: holder)
        return txId
    }

    func reStakeUnstake(nodeID: String, delegatorId: Int, amount: Decimal) async throws -> Flow.ID {
        let txId = try await FlowNetwork.reStakeUnstake(
            nodeID: nodeID,
            delegatorId: delegatorId,
            amount: amount
        )
        let holder = TransactionManager.TransactionHolder(id: txId, type: .stakeFlow)
        TransactionManager.shared.newTransaction(holder: holder)
        return txId
    }

    func goStakingAction() {
        if nodeInfos.count == 1, let node = nodeInfos.first,
           let provider = StakingProviderCache.cache.providers
           .first(where: { $0.id == node.nodeID }) {
            Router.route(to: RouteMap.Wallet.stakeDetail(provider, node))
        } else {
            Router.route(to: RouteMap.Wallet.stakingList)
        }
    }

    // MARK: Private

    private lazy var rootFolder = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
    ).first!.appendingPathComponent("staking_cache")
    private lazy var cacheFile = rootFolder.appendingPathComponent("cache_file")

    private var cancelSet = Set<AnyCancellable>()
}

extension StakingManager {
    private func updateApy() {
        let refAddress = WalletManager.shared.getPrimaryWalletAddress() ?? "0"

        Task {
            do {
                let apy = try await FlowNetwork.getStakingApyByWeek()
                if WalletManager.shared.getPrimaryWalletAddress() != refAddress {
                    return
                }

                await MainActor.run {
                    self.apy = apy
                    self.saveCache()
                }
            } catch {
                log.error("updateApy failed", context: error)
            }
        }
    }

    private func queryStakingInfo() {
        let refAddress = WalletManager.shared.getPrimaryWalletAddress() ?? "0"

        Task {
            do {
                if let response = try await FlowNetwork.queryStakeInfo() {
                    if WalletManager.shared.getPrimaryWalletAddress() != refAddress {
                        return
                    }

                    await MainActor.run {
                        log.debug("queryStakingInfo success")
                        self.nodeInfos = response
                        self.saveCache()
                    }
                } else {
                    log.debug("queryStakingInfo is empty")
                    await MainActor.run {
                        self.nodeInfos = []
                        self.saveCache()
                    }
                }
            } catch {
                log.error("queryStakingInfo failed", context: error)
                await MainActor.run {
                    self.nodeInfos = []
                    self.saveCache()
                }
            }
        }
    }

    func refreshDelegatorInfo() async throws {
        guard let refAddress = WalletManager.shared.getPrimaryWalletAddress() else {
            throw WalletError.emptyAddress
        }
        let response = try await FlowNetwork.getDelegatorInfo()

        if WalletManager.shared.getPrimaryWalletAddress() != refAddress {
            return
        }
        
        for node in response {
            delegatorIds[node.nodeID] = node.id
        }
    }

    private func updateSetupStatus() {
        let refAddress = WalletManager.shared.getPrimaryWalletAddress() ?? "0"

        Task {
            do {
                let isSetup = try await FlowNetwork.accountStakingIsSetup()
                if WalletManager.shared.getPrimaryWalletAddress() != refAddress {
                    return
                }

                await MainActor.run {
                    self.isSetup = isSetup
                    self.saveCache()
                }
            } catch {
                debugPrint("StakingManager -> updateSetupStatus failed: \(error)")
            }
        }
    }

    @objc
    private func clean() {
        nodeInfos = []
        delegatorIds.removeAll()
        apy = StakingDefaultApy
        isSetup = false

        deleteCache()
    }
}

extension StakingManager {
    struct StakingCache: Codable {
        var nodeInfos: [StakingNode] = []
        var apy: Double = StakingDefaultApy
        var isSetup: Bool = false
    }

    private func createFolderIfNeeded() {
        do {
            if !FileManager.default.fileExists(atPath: rootFolder.relativePath) {
                try FileManager.default.createDirectory(
                    at: rootFolder,
                    withIntermediateDirectories: true
                )
            }
        } catch {
            debugPrint("StakingManager -> createFolderIfNeeded error: \(error)")
        }
    }

    private func saveCache() {
        let cacheObj = StakingCache(nodeInfos: nodeInfos, apy: apy, isSetup: isSetup)

        do {
            let data = try JSONEncoder().encode(cacheObj)
            try data.write(to: cacheFile)
        } catch {
            debugPrint("StakingManager -> saveCache: error: \(error)")
            deleteCache()
        }
    }

    private func loadCache() {
        if !FileManager.default.fileExists(atPath: cacheFile.relativePath) {
            return
        }

        do {
            let data = try Data(contentsOf: cacheFile)
            let cacheObj = try JSONDecoder().decode(StakingCache.self, from: data)
            nodeInfos = cacheObj.nodeInfos
            apy = cacheObj.apy
            isSetup = cacheObj.isSetup
        } catch {
            debugPrint("StakingManager -> loadCache error: \(error)")
            deleteCache()
            return
        }
    }

    private func deleteCache() {
        if FileManager.default.fileExists(atPath: cacheFile.relativePath) {
            do {
                try FileManager.default.removeItem(at: cacheFile)
            } catch {
                debugPrint("StakingManager -> clearCache: error: \(error)")
            }
        }
    }
}
