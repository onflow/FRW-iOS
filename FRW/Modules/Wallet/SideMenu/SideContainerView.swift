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
            // Global custom alert overlay host (fully customizable)
            .overlay(AlertOverlayView())
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
    @ObservedObject
    private var alertCenter = AlertCenter.shared
    @State
    private var dragOffset: CGSize = .zero
    @State
    private var isDragging: Bool = false
}

#Preview {
    SideContainerView().makeTabView()
}

// MARK: - Global Alert Overlay (customizable)

struct AlertOverlayView: View {
    @ObservedObject var alertCenter: AlertCenter = .shared

    var body: some View {
        Group {
            if let model = alertCenter.model {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            if model.actions.contains(where: { $0.id == "cancel" }) {
                                alertCenter.cancel()
                            }
                        }

                    if let custom = model.customContent, !model.wrapsInDefaultContainer {
                        VStack(spacing: 16) {
                            custom

                            if !model.actions.isEmpty {
                                VStack(spacing: 10) {
                                    ForEach(model.actions) { action in
                                        Button {
                                            alertCenter.resolve(selection: action.id)
                                        } label: {
                                            Text(action.title)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                        }
                                        .buttonStyle(AlertButtonStyle(kind: action.style))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                    } else {
                        VStack(spacing: 16) {
                            if let custom = model.customContent {
                                custom
                            } else {
                                if let title = model.title {
                                    Text(title)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                }
                                if let message = model.message {
                                    Text(message)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }

                            VStack(spacing: 10) {
                                ForEach(model.actions) { action in
                                    Button {
                                        alertCenter.resolve(selection: action.id)
                                    } label: {
                                        Text(action.title)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                    .buttonStyle(AlertButtonStyle(kind: action.style))
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 8)
                        )
                        .padding(.horizontal, 28)
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.2), value: alertCenter.model != nil)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct AlertButtonStyle: ButtonStyle {
    let kind: AlertButtonStyleKind

    func makeBody(configuration: Configuration) -> some View {
        switch kind {
        case .primary:
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor)
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
        case .secondary:
            configuration.label
                .font(.body)
                .foregroundColor(Color.accentColor)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
        case .destructive:
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.red)
                )
                .opacity(configuration.isPressed ? 0.8 : 1)
        }
    }
}
