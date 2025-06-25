//
//  ImportFromDeviceViewModel.swift
//  FRW
//
//  Created by cat on 6/23/25.
//

import Combine
import Foundation
import SwiftUICore
import WalletConnectPairing
import WalletConnectSign

final class ImportFromDeviceViewModel: ObservableObject {
    // MARK: Internal

    @EnvironmentObject var adapter: ImportWalletViewModel

    @Published
    var uriString: String?
    @Published
    var isConnect: Bool = false

    // MARK: Private

    private var publishers = [AnyCancellable]()

    private var topic: String?

    init() {
        WalletConnectManager.shared.$setSessions
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { sessions in
                for session in sessions {
                    // TODO: check this
                    if session.pairingTopic == self.topic {
                        let namespaces = session.requiredNamespaces.values.map { $0 }
                        let result = namespaces.filter { $0.methods.contains(FCLWalletConnectMethod.addMultiAccount.rawValue) }
                        if result.count > 0 {
                            WalletConnectManager.shared.skipToSyncAction(source: .new)
                        }
                    }
                }
            }.store(in: &publishers)
    }

    private func createUrl() {
        Task {
            do {
                let uri = try await connectUrl()
                WalletConnectManager.shared.prepareSyncAccount()
                await MainActor.run {
                    self.topic = uri.topic
                    self.uriString = uri.absoluteString
                }
            } catch {
                log.error("[Import] connect walletconnect failed from \(adapter.importType).\(error)")
            }
        }
    }

    private func connectUrl() async throws -> WalletConnectURI {
        if adapter.importType == .account {
            try await WalletConnectManager.shared.connectURIForAccount()
        } else {
            try await WalletConnectManager.shared.connectURIForProfile()
        }
    }
}
