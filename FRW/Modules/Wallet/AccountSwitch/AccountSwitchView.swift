//
//  AccountSwitchView.swift
//  Flow Wallet
//
//  Created by Selina on 13/6/2023.
//

import Combine
import Kingfisher
import SwiftUI

// MARK: - AccountSwitchView

struct AccountSwitchView: PresentActionView {
    // MARK: Internal

    var changeHeight: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            titleView
                .padding(.vertical, 36)

            contentView

            bottomView
                .padding(.top, 7)
        }
        .backgroundFill(Color.LL.Neutrals.background)
    }

    var titleView: some View {
        Text("accounts".localized)
            .font(.inter(size: 24, weight: .bold))
            .foregroundColor(Color.LL.Neutrals.text)
    }

    var bottomView: some View {
        VStack(spacing: 2) {
            Button {
                if currentNetwork != .mainnet {
                    showAlert = true
                } else {
                    Router.dismiss {
                        vm.createNewAccountAction()
                    }
                }

            } label: {
                HStack(spacing: 8) {
                    Image("user-circle-plus")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("create_new_account".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black8)

                    Spacer()
                }
                .padding(.vertical, 16)
            }
            .alert("wrong_network_title".localized, isPresented: $showAlert) {
                Button("switch_to_mainnet".localized) {
                    WalletManager.shared.changeNetwork(.mainnet)
                    Router.dismiss {
                        vm.createNewAccountAction()
                    }
                }
                Button("action_cancel".localized, role: .cancel) {}
            } message: {
                Text("wrong_network_des".localized)
            }

            Divider()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.Summer.line)

            Button {
                Router.dismiss {
                    vm.loginAccountAction()
                }
            } label: {
                HStack(spacing: 8) {
                    Image("user-circle-check")
                        .resizable()
                        .frame(width: 24, height: 24)

                    Text("recover_profile".localized)
                        .font(.inter(size: 14, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black8)

                    Spacer()
                }
                .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.Summer.cards)
        .cornerRadius(16)
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }

    var contentView: some View {
        GeometryReader { _ in
            ScrollViewOffset { offset in
                self.offset = offset
            } content: {
                LazyVStack(spacing: 20) {
                    ForEach(vm.placeholders, id: \.userId) { placeholder in
                        Button {
                            vm.selectedUid = placeholder.userId
                            if currentNetwork != .mainnet {
                                showSwitchUserAlert = true
                            } else {
                                Router.dismiss {
                                    vm.switchAccountAction(placeholder.userId)
                                }
                            }

                        } label: {
                            createAccountCell(placeholder)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .alert("wrong_network_title".localized, isPresented: $showSwitchUserAlert) {
                            Button("switch_to_mainnet".localized) {
                                WalletManager.shared.changeNetwork(.mainnet)
                                if let uid = vm.selectedUid {
                                    Router.dismiss {
                                        vm.switchAccountAction(uid)
                                    }
                                }
                            }
                            Button("action_cancel".localized, role: .cancel) {}
                        } message: {
                            Text("wrong_network_des".localized)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SizePreferenceKey.self, value: proxy.size)
                    }
                    .onPreferenceChange(SizePreferenceKey.self, perform: { value in
                        self.contentHeight = value.height
                    })
                }
            }
            .padding(.horizontal, 18)
        }
    }

    func createAccountCell(_ placeholder: UserManager.StoreUser) -> some View {
        HStack(spacing: 16) {
            ProfileInfoView(userInfo: placeholder.userInfo ?? .empty)

            Spacer()
            FCheckBox(isSelected: .constant(placeholder.userId == UserManager.shared
                    .activatedUID))
        }
        .frame(height: 42)
        .contentShape(Rectangle())
    }

    // MARK: Private

    @StateObject
    private var vm = AccountSwitchViewModel()
    @State
    private var showAlert = false
    @State
    private var showSwitchUserAlert = false

    @State
    private var offset: CGFloat = 0
    @State
    private var contentHeight: CGFloat = 0
}

extension AccountSwitchView {
    var detents: [UISheetPresentationController.Detent] {
        [.medium(), .large()]
    }
}

// MARK: - ScrollViewOffset

struct ScrollViewOffset<Content: View>: View {
    // MARK: Lifecycle

    init(
        onOffsetChange: @escaping (CGFloat) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.onOffsetChange = onOffsetChange
        self.content = content
    }

    // MARK: Internal

    let onOffsetChange: (CGFloat) -> Void
    let content: () -> Content

    var body: some View {
        ScrollView {
            offsetReader
            content()
                .padding(.top, -8)
        }
        .coordinateSpace(name: "frameLayer")
        .onPreferenceChange(OffsetPreferenceKey.self, perform: onOffsetChange)
    }

    var offsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: OffsetPreferenceKey.self,
                    value: proxy.frame(in: .named("frameLayer")).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - SizePreferenceKey

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - OffsetPreferenceKey

private struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value _: inout CGFloat, nextValue _: () -> CGFloat) {}
}
