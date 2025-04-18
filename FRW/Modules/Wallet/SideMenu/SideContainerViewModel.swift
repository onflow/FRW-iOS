//
//  SideContainerViewModel.swift
//  FRW
//
//  Created by Hao Fu on 1/4/2025.
//

import Foundation
import Combine
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

        isLinkedAccount = ChildAccountManager.shared.selectedChildAccount != nil
        ChildAccountManager.shared.$selectedChildAccount
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink(receiveValue: { [weak self] newChildAccount in
                self?.isLinkedAccount = newChildAccount != nil
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
