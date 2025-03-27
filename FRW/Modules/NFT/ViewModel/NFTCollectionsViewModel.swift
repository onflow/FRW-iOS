//
//  NFTCollectionsViewModel.swift
//  FRW
//
//  Created by Marty Ulrich on 3/12/25.
//

import Foundation
import Combine

@MainActor
final class NFTCollectionsViewModel: ObservableObject {
    @Published var isRefreshing: Bool = false
    @Published var tabVM: NFTTabViewModel
    
    private var tasks = Set<Task<Void, Never>>()

    lazy var dataModel: NFTUIKitListNormalDataModel = {
        let dm = NFTUIKitListNormalDataModel()
        dm.reloadCallback = { [weak self] in
            Task {
                await self?.refresh()
            }
        }
        
        return dm
    }()
        
    init(tabVM: NFTTabViewModel) {
        self.tabVM = tabVM
        
        tasks.insert(Task.detached { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .watchAddressDidChanged) {
                await self?.refresh()
            }
        })
        tasks.insert(Task.detached { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .didResetWallet) {
                await self?.refresh()
            }
        })
        tasks.insert(Task.detached { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .childAccountChanged) {
                await self?.refresh()
            }
        })
        tasks.insert(Task.detached { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .nftDidChangedByMoving) {
                await self?.refresh()
            }
        })
        
        // Combine publishers as AsyncPublisher
        tasks.insert(Task.detached { [weak self] in
            let values = WalletManager.shared.$walletInfo
                .dropFirst()
                .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .values
            for await _ in values {
                await self?.refresh()
            }
        })
        tasks.insert(Task.detached { [weak self] in
            let values = EVMAccountManager.shared.$selectedAccount
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .values
            for await _ in values {
                await self?.refresh()
            }
        })
        
        Task { await refresh() }
    }
    
    deinit {
        // Cancel all async tasks
        tasks.forEach { $0.cancel() }
    }

    func refresh() async {
        if isRefreshing {
            return
        }
        isRefreshing = true
        defer {
            isRefreshing = false            
        }
        do {
            try await dataModel.refreshCollectionAction()
        } catch {
            log.error(error)
            HUD.error(title: "request_failed".localized)
        }
    }
    
    func onAddButtonTap() {
        Router.route(to: RouteMap.NFT.addCollection)
    }
    
    func onCollectionSelection(_ collection: CollectionItem) {
        Router.route(to: RouteMap.NFT.collection(tabVM, collection))
    }
}
