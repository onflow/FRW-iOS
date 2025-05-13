//
//  SideContainerViewModel.swift
//  FRW
//
//  Created by Hao Fu on 1/4/2025.
//

import Combine
import Foundation
import SwiftUI

// MARK: - SideContainerViewModel

class SideContainerViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onToggle),
            name: .toggleSideMenu,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onRemoteConfigDidChange),
            name: .remoteConfigDidUpdate,
            object: nil
        )

        isLinkedAccount = WalletManager.shared.selectedChildAccount != nil
        WalletManager.shared.$selectedAccount
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink(receiveValue: { [weak self] _ in
                self?.isLinkedAccount = WalletManager.shared.isSelectedChildAccount
            }).store(in: &cancellableSet)
    }

    // MARK: Internal

    @Published
    var isOpen: Bool = false
    @Published
    var isLinkedAccount: Bool = false
    @Published
    var hideBrowser: Bool = false

    @objc
    func onToggle() {
        withAnimation {
            isOpen.toggle()
        }
    }

    @objc
    func onRemoteConfigDidChange() {
        DispatchQueue.main.async {
            self.hideBrowser = RemoteConfigManager.shared.config?.features.hideBrowser ?? true
        }
    }

    // MARK: Private

    private var cancellableSet = Set<AnyCancellable>()
}
