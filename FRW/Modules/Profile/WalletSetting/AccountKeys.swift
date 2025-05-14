//
//  AccountKeys.swift
//  FRW
//
//  Created by cat on 2023/10/18.
//

import Flow
import SwiftUI

// MARK: - AccountKeysView

struct AccountKeysView: RouteableView {
    // MARK: Internal

    var title: String {
        "wallet_account_key".localized.capitalized
    }

    var body: some View {
        ScrollView {
            ForEach(0 ..< vm.allKeys.count, id: \.self) { index in
                let model = vm.allKeys[index]
                AccountKeysView.Cell(model: model) { model in
                    self.onRevokeKey(at: model)
                }
            }
        }
        .backgroundFill(.Theme.Background.white)
        .mockPlaceholder(vm.status == PageStatus.loading)
        .halfSheet(showSheet: $vm.showRovekeView, autoResizing: true, backgroundColor: Color.LL.Neutrals.background) {
            AccountKeyRevokeView()
                .environmentObject(vm)
        }
        .applyRouteable(self)
        .tracedView(self)
    }

    func onRevokeKey(at model: AccountKeyModel) {
        guard !model.isCurrent() else {
            HUD.info(title: "account_key_current_tips".localized)
            return
        }
        guard !model.accountKey.revoked else {
            HUD.info(title: "account_key_done_revoked_tips".localized)
            return
        }
        vm.revokeKey(at: model)
    }

    // MARK: Private

    @StateObject
    private var vm = AccountKeyViewModel()
}

// MARK: AccountKeysView.Cell

extension AccountKeysView {
    struct Cell: View {
        var model: AccountKeyModel
        var onRevoke: ((AccountKeyModel) -> Void)?
        @State
        var isExpanding = false
        @State
        var isShowRevoke = false

        var body: some View {
            VStack(spacing: -8) {
                HStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
//                        Text("Key \(model.accountKey.index)")
//                            .padding(.trailing, 8)
                        Image(model.titleIcon())
                            .resizable()
                            .frame(width: 24, height: 24)

                        Text(model.deviceName())
                            .font(.inter(size: 12))
                            .foregroundStyle(model.deviceNameColor())
                            .hidden(model.deviceName().isEmpty)

                        Spacer()
//                        AccountKeysView.ProgressView(model: model)

                        Text(model.statusText())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .frame(height: 20)
                            .font(.inter(size: 9, weight: .bold))
                            .foregroundStyle(model.statusColor())
                            .background(model.statusColor().fixedOpacity())
                            .cornerRadius(4)
                            .visibility(model.statusText().isEmpty ? .gone : .visible)

                        Image(isExpanding ? "arrow.up" : "arrow.down")
                            .frame(width: 16, height: 16)
                            .padding(.leading, 16)
                    }
                    .frame(height: 52)
                    .padding(.horizontal, 16)
                    .background(
                        ThemeManager.shared.style == .light ? Color.Theme.Background
                            .pureWhite : Color.Theme.Background.grey
                    )
                    .cornerRadius(16)
                    .padding(.horizontal, 18)
                    .zIndex(100)
                    .onTapGesture {
                        withAnimation {
                            isExpanding.toggle()
                        }
                    }
                }

                HStack {
                    VStack {
                        CopyInfoView(model: model)
                        WeightView(model: model, contentType: .weight)
                        TextInfoView(model: model, contentType: .hash)
                        TextInfoView(model: model, contentType: .number)
                        TextInfoView(model: model, contentType: .curve)
                        TextInfoView(model: model, contentType: .keyIndex)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 16)
                    .background(Color.Theme.Background.grey.opacity(0.75))
                    .cornerRadius([.bottomLeading, .bottomTrailing], 16)
                }
                .padding(.horizontal, 24)
                .visibility(isExpanding ? .visible : .gone)
            }
            .onViewSwipe(title: "revoke".localized) {
                onRevokeAction()
            }
        }

        func onRevokeAction() {
            onRevoke?(model)
        }
    }
}

extension AccountKeysView {
    struct ProgressView: View {
        var model: AccountKeyModel

        var body: some View {
            ZStack(alignment: .leading) {
                model.weightBG()
                    .frame(width: model.weightPadding())
                    .cornerRadius(2)
                Text(model.weightDes())
                    .font(.inter(size: 9, weight: .bold))
                    .frame(width: 72, height: 16)
                    .foregroundStyle(Color.Theme.Text.black3)
            }
            .frame(width: 72, height: 16)
            .background(.Theme.Background.white)
            .cornerRadius(2)
        }
    }

    struct CopyInfoView: View {
        var model: AccountKeyModel

        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                model.icon(at: .publicKey)
                    .frame(width: 16, height: 16)
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text(model.tag(at: .publicKey))
                            .font(.inter(size: 10))
                            .foregroundStyle(Color.Theme.Text.black8)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = model.accountKey.publicKey.description
                            HUD.success(title: "copied".localized)
                        } label: {
                            Image("icon_copy")
                        }
                    }

                    Text(model.accountKey.publicKey.description)
                        .font(.inter(size: 10))
                        .foregroundStyle(Color.Theme.Text.black3)
                }
            }
        }
    }

    struct TextInfoView: View {
        var model: AccountKeyModel
        var contentType: AccountKeyModel.ContentType

        var body: some View {
            HStack {
                model.icon(at: contentType)
                    .frame(width: 16, height: 16)
                Text(model.tag(at: contentType))
                    .font(.inter(size: 10))
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                Text(model.content(at: contentType))
                    .font(.inter(size: 10, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.black3)
            }
        }
    }

    struct WeightView: View {
        var model: AccountKeyModel
        var contentType: AccountKeyModel.ContentType

        var body: some View {
            HStack {
                model.icon(at: contentType)
                    .frame(width: 16, height: 16)
                Text(model.tag(at: contentType))
                    .font(.inter(size: 10))
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                AccountKeysView.ProgressView(model: model)
            }
        }
    }
}

// MARK: - ViewSwipe

struct ViewSwipe: ViewModifier {
    // MARK: Internal

    let title: String
    let action: () -> Void

    @State
    var offset: CGSize = .zero
    @State
    var initialOffset: CGSize = .zero
    @State
    var contentWidth: CGFloat = 0.0

    // MARK: Constants

    let deletionDistance = CGFloat(200)
    let halfDeletionDistance = CGFloat(50)
    let tappableDeletionWidth = CGFloat(89 + 18)

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in

                    HStack {
                        ZStack {
                            Rectangle()
                                .cornerRadius(16, style: .continuous)
                                .foregroundColor(Color.Theme.Accent.red)
                            Text(title)
                                .font(.inter(size: 16, weight: .semibold))
                                .foregroundStyle(Color.Theme.Text.white9)
                                .frame(width: 89, height: 52)
                                .layoutPriority(-1)
                        }
                        Color.clear
                            .frame(width: 18)
                    }
                    .frame(width: -offset.width)
                    .clipShape(Rectangle())
                    .offset(x: geometry.size.width)
                    .onAppear {
                        contentWidth = geometry.size.width
                    }
                    .gesture(
                        TapGesture()
                            .onEnded {
                                onAction()
                            }
                    )
                }
            )
            .offset(x: offset.width, y: 0)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width + initialOffset.width <= 0 {
                            self.offset.width = gesture.translation.width + initialOffset.width
                        } else {
                            offset = .zero
                            initialOffset = .zero
                        }
                    }
                    .onEnded { _ in
                        if offset.width <= -deletionDistance {
                            offset.width = -tappableDeletionWidth
                            initialOffset.width = -tappableDeletionWidth
                        } else if offset.width <= -halfDeletionDistance {
                            offset.width = -tappableDeletionWidth
                            initialOffset.width = -tappableDeletionWidth
                        } else {
                            offset = .zero
                            initialOffset = .zero
                        }
                    }
            )
            .animation(.interactiveSpring(), value: offset)
    }

    // MARK: Private

    private func onAction() {
        offset = .zero
        initialOffset = .zero
        hapticFeedback()
        action()
    }

    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

extension View {
    func onViewSwipe(title: String, perform action: @escaping () -> Void) -> some View {
        modifier(ViewSwipe(title: title, action: action))
    }
}
