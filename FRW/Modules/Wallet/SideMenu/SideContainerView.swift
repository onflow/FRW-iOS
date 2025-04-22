//
//  SideContainerView.swift
//  FRW
//
//  Created by Hao Fu on 1/4/2025.
//

import SwiftUI

// MARK: - SideContainerView

struct SideContainerView: View {
    // MARK: Internal

    private let SideOffset: CGFloat = 65
    
    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
                debugPrint("dragging: \(dragOffset)")
            }
            .onEnded { _ in
                if !vm.isOpen && dragOffset.width > 20 {
                    vm.isOpen = true
                }

                if vm.isOpen && dragOffset.width < -20 {
                    vm.isOpen = false
                }

                isDragging = false
                dragOffset = .zero
            }
    }

    var body: some View {
        if !um.isLoggedIn {
            EmptyWalletView()
        } else {
            ZStack {
                SideMenuView()
                    .offset(x: vm.isOpen ? 0 : -(screenWidth - SideOffset))

                Group {
                    makeTabView()

                    Color.black
                        .opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture {
                            vm.onToggle()
                        }
                        .opacity(vm.isOpen ? 1.0 : 0.0)
                }
                .offset(x: vm.isOpen ? screenWidth - SideOffset : 0)
            }
            .onAppearOnce {
                Task {
                    try await Task.sleep(for: .seconds(1))
                    TransactionUIHandler.shared.refreshPanelHolder()
                    PushHandler.shared.showPushAlertIfNeeded()
                }
            }
        }
    }

    // MARK: Fileprivate

    @ViewBuilder
    fileprivate func makeTabView() -> some View {
        let wallet = TabBarPageModel<AppTabType>(
            tag: WalletHomeView.tabTag(),
            iconName: WalletHomeView.iconName(),
            title: WalletHomeView.title()
        ) {
            AnyView(WalletHomeView())
        }

        let nft = TabBarPageModel<AppTabType>(
            tag: NFTTabScreen.tabTag(),
            iconName: NFTTabScreen.iconName(),
            title: NFTTabScreen.title()
        ) {
            AnyView(NFTTabScreen())
        }

        let explore = TabBarPageModel<AppTabType>(
            tag: ExploreTabScreen.tabTag(),
            iconName: ExploreTabScreen.iconName(),
            title: ExploreTabScreen.title()
        ) {
            AnyView(ExploreTabScreen())
        }

        let txHistory = TabBarPageModel<AppTabType>(
            tag: TransactionListViewController.tabTag(),
            iconName: TransactionListViewController.iconName(),
            title: TransactionListViewController.title()
        ) {
            /// MU: This was the only way to make it pretty in SwiftUI
            let vc = TransactionListViewControllerRepresentable()
            return AnyView(
                NavigationView {
                    vc
                        .navigationViewStyle(StackNavigationViewStyle())
                        .navigationBarBackButtonHidden()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .padding(.top, 4)
            )
        }

        let profile = TabBarPageModel<AppTabType>(
            tag: ProfileView.tabTag(),
            iconName: ProfileView.iconName(),
            title: ProfileView.title()
        ) {
            AnyView(ProfileView())
        }

        if vm.isLinkedAccount {
            TabBarView(
                current: .wallet,
                pages: [wallet, nft, txHistory, profile],
                maxWidth: UIScreen.main.bounds.width
            )
        } else {
            if vm.hideBrowser {
                TabBarView(
                    current: .wallet,
                    pages: [wallet, nft, txHistory, profile],
                    maxWidth: UIScreen.main.bounds.width
                )
            } else {
                TabBarView(
                    current: .wallet,
                    pages: [wallet, nft, explore, txHistory, profile],
                    maxWidth: UIScreen.main.bounds.width
                )
            }
        }
    }

    // MARK: Private

    @StateObject
    private var vm = SideContainerViewModel()
    @StateObject
    private var um = UserManager.shared
    @State
    private var dragOffset: CGSize = .zero
    @State
    private var isDragging: Bool = false
}

#Preview {
    SideContainerView().makeTabView()
}
