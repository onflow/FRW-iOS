//
//  WalletNewsHandler.swift
//  FRW
//
//  Created by cat on 2024/8/26.
//

import Foundation
import SwiftUI

class WalletNewsHandler: ObservableObject {
    static let shared = WalletNewsHandler()

    private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)

    // TODO: Change it to Set
    @Published var list: [RemoteConfigManager.News] = []

    var removeIds: [String] = [] {
        didSet {
            LocalUserDefaults.shared.removedNewsIds = removeIds
        }
    }

    private init() {
        removeIds = LocalUserDefaults.shared.removedNewsIds
    }

    /// Call only once when receive Firebase Config
    func addRemoteNews(_ news: [RemoteConfigManager.News]) {
        accessQueue.sync { [weak self] in
            guard let self else { return }
            self.list.removeAll()
            self.list.append(contentsOf: news)
            self.removeExpiryNew()
            self.removeMarkedNews()
            self.handleConfition()
            self.orderNews()
            log.debug("[NEWS] count:\(list.count)")
        }
    }

    func addRemoteNews(_ news: RemoteConfigManager.News) {
        accessQueue.sync { [weak self] in
            guard let self else { return }
            if list.contains(where: { $0.id == news.id }) {
                return
            }

            list.append(news)
            orderNews()
        }
    }

    func removeNews(_ news: RemoteConfigManager.News) {
        accessQueue.sync { [weak self] in
            guard let self else { return }
            if let index = list.firstIndex(where: { $0.id == news.id }), let _ = list[safe: index] {
                list.remove(at: index)
                orderNews()
            }
        }
    }

    func refreshWalletConnectNews(_ news: [RemoteConfigManager.News]) {
        accessQueue.sync { [weak self] in
            guard let self else { return }
            let tmpList = list
            for (index, new) in tmpList.enumerated() {
                if new.flag == .walletconnect, let _ = list[safe: index] {
                    list.remove(at: index)
                }
            }

            for item in news {
                addRemoteNews(item)
            }
        }
    }

    private func removeExpiryNew() {
        accessQueue.sync {
            
            let currentData = Date()
            list = list.filter { $0.expiryTime > currentData }
            log.debug("[NEWS] removeExpiryNew count:\(list.count)")
        }
    }

    private func removeMarkedNews() {
        accessQueue.sync {
            list = list.filter { !removeIds.contains($0.id) }
            log.debug("[NEWS] removeMarkedNews count:\(list.count)")
        }
    }

    private func handleConfition() {
        accessQueue.sync {
            list = list.filter { model in
                guard let conditionList = model.conditions, !conditionList.isEmpty else {
                    return true
                }
                return !conditionList.map { $0.type.boolValue() }.contains(false)
            }
            log.debug("[NEWS] handleConfition count:\(list.count)")
        }
    }

    private func orderNews() {
        list.sort(by: >)
    }

    @discardableResult
    private func markItemIfNeed(_ itemId: String, displatyType: [RemoteConfigManager.NewDisplayType] = [.once]) -> Bool {
        let item = list.first { $0.id == itemId }
        guard let type = item?.displayType, displatyType.contains(type) else {
            return false
        }
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            removeIds.append(itemId)
        }
        return true
    }

    /// Call only once when view appear
    func checkFirstNews() {
        accessQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            if let item = list.first {
                markItemIfNeed(item.id, displatyType: [.once])
            }
        }
    }
}

// MARK: User Action

extension WalletNewsHandler {
    func onShowItem(_ itemId: String) {
        markItemIfNeed(itemId, displatyType: [.once])
    }

    func onCloseItem(_ itemId: String) {
        markItemIfNeed(itemId)
        withAnimation {
            list.removeAll { $0.id == itemId }
        }
    }

    func onClickItem(_ itemId: String) {
        guard let item = list.first(where: { $0.id == itemId }) else { return }

        let shouldRemove = markItemIfNeed(itemId, displatyType: [.click, .once])

        if let urlStr = item.url, !urlStr.isEmpty, let url = URL(string: urlStr) {
            if urlStr.contains("apple.com") {
                UIApplication.shared.open(url)
            } else {
                Router.route(to: RouteMap.Explore.browser(url))
            }
        }

        if item.flag == .walletconnect, let request = WalletConnectManager.shared.pendingRequests.first(where: { $0.topic == item.id }) {
            WalletConnectManager.shared.handleRequest(request)
        }

        if shouldRemove {
            withAnimation {
                list.removeAll { $0.id == itemId }
            }
        }
    }

    func nextItem(_ itemId: String) -> String? {
        guard let index = list.firstIndex(where: { $0.id == itemId }) else {
            return nil
        }
        guard index + 1 < list.count else {
            return nil
        }
        let item = list[index + 1]
        return item.id
    }

    func nextIndex(_ itemId: String) -> Int? {
        guard let index = list.firstIndex(where: { $0.id == itemId }) else {
            return nil
        }
        let nextIndex = index + 1
        guard nextIndex < list.count else {
            return nil
        }
        return nextIndex
    }

    func onScroll(index: Int) {
        guard index < list.count else { return }

        let item = list[index]
        if item.displayType == .once {
            removeIds.append(item.id)
        }
    }
}
