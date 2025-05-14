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
        VStack(spacing: 0) {
            Divider()
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.LL.Neutrals.background)
                .padding(.bottom, 30)

            Button {
                if currentNetwork != .mainnet {
                    showAlert = true
                } else {
                    Router.dismiss {
                        vm.createNewAccountAction()
                    }
                }

            } label: {
                HStack(spacing: 15) {
                    Image("icon-plus")
                        .renderingMode(.template)
                        .foregroundColor(Color.LL.Neutrals.text)
                        .frame(width: 14, height: 14)

                    Text("create_new_account".localized)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundColor(Color.LL.Neutrals.text)

                    Spacer()
                }
                .frame(height: 40)
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

            Button {
                Router.dismiss {
                    vm.loginAccountAction()
                }
            } label: {
                HStack(spacing: 15) {
                    Image("icon-down-arrow")
                        .renderingMode(.template)
                        .foregroundColor(Color.LL.Neutrals.text)
                        .frame(width: 14, height: 14)

                    Text("add_existing_account".localized)
                        .font(.inter(size: 14, weight: .semibold))
                        .foregroundColor(Color.LL.Neutrals.text)

                    Spacer()
                }
                .frame(height: 40)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
    }

    var contentView: some View {
        GeometryReader { geometry in
            ScrollViewOffset { offset in
                self.offset = offset
            } content: {
                LazyVStack(spacing: 20) {
                    ForEach(vm.placeholders, id: \.uid) { placeholder in
                        Button {
                            vm.selectedUid = placeholder.uid
                            if currentNetwork != .mainnet {
                                showSwitchUserAlert = true
                            } else {
                                Router.dismiss {
                                    vm.switchAccountAction(placeholder.uid)
                                }
                            }

                        } label: {
                            createAccountCell(placeholder)
                        }
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
            .overlay(alignment: .bottom) {
                moreView
                    .opacity(offset < 10 ? max(0, 1 - (-offset / 50.0)) : 1)
                    .visibility(self.contentHeight > geometry.size.height ? .visible : .gone)
            }
        }
    }

    var moreView: some View {
        Button {
            self.changeHeight?()
        } label: {
            HStack {
                Text("view_more".localized)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Accent.grey)
                Image("icon_arrow_double_down")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background(.Theme.Background.grey)
            .cornerRadius(16)
        }
    }

    func createAccountCell(_ placeholder: AccountSwitchViewModel.Placeholder) -> some View {
        HStack(spacing: 16) {
            KFImage.url(URL(string: placeholder.avatar.convertedAvatarString()))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(placeholder.username)")
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(Color.LL.Neutrals.text)

                Text("\(placeholder.address)")
                    .font(.inter(size: 12, weight: .regular))
                    .foregroundColor(Color.LL.Neutrals.text2)
            }

            Spacer()
            Image("icon-backup-success")
                .visibility(
                    placeholder.uid == UserManager.shared
                        .activatedUID ? .visible : .invisible
                )
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
