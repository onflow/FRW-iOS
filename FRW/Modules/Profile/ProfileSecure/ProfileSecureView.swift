//
//  ProfileSecureView.swift
//  Flow Wallet
//
//  Created by Selina on 3/8/2022.
//

import SwiftUI

// MARK: - ProfileSecureView

struct ProfileSecureView: RouteableView {
    // MARK: Internal

    var title: String {
        "security".localized
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                Button {
                    vm.resetPinCodeAction()
                } label: {
                    ProfileSecureView.ItemCell(
                        title: vm.isPinCodeEnabled ? "disable_pin_code"
                            .localized : "enable_pin_code".localized,
                        style: .arrow,
                        isOn: false,
                        toggleAction: nil
                    )
                    .contentShape(Rectangle())
                    .onAppear {
                        vm.refreshPinCodeStatusAction()
                    }
                }

                Divider().foregroundColor(.LL.Neutrals.background)

                ProfileSecureView.ItemCell(
                    title: SecurityManager.shared.supportedBionic == .touchid ? "touch_id"
                        .localized : "face_id".localized,
                    style: .toggle,
                    isOn: vm.isBionicEnabled
                ) { value in
                    vm.changeBionicAction(value)
                }
                .disabled(SecurityManager.shared.supportedBionic == .none)

                Divider().foregroundColor(.LL.Neutrals.background)

                ProfileSecureView.ItemCell(
                    title: "lock_on_exit".localized,
                    style: .toggle,
                    isOn: vm.isLockOnExit
                ) { value in
                    vm.changeLockOnExitAction(value)
                }
            }
            .padding(.horizontal, 16)
            .roundedBg()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 18)
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @StateObject
    private var vm = ProfileSecureViewModel()
}

extension ProfileSecureView {
    struct ItemCell: View {
        let title: String
        let style: ProfileSecureView.ItemCell.Style
        @State
        var isOn: Bool = false
        let toggleAction: ((Bool) -> Void)?

        var body: some View {
            HStack(spacing: 0) {
                Text(title)
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Toggle(isOn: $isOn) {}
                    .tint(.LL.Primary.salmonPrimary)
                    .onChange(of: isOn) { value in
                        toggleAction?(value)
                    }
                    .visibility(style == .toggle ? .visible : .gone)

                Image("icon-black-right-arrow")
                    .renderingMode(.template)
                    .foregroundColor(Color.LL.Button.color)
                    .visibility(style == .arrow ? .visible : .gone)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
    }

    struct WalletInfoCell: View {
        var user: WalletAccount.User
        var onEdit: () -> Void

        var body: some View {
            HStack {
                user.emoji.icon(size: 40)
                Text(user.name)
                    .font(.inter())
                    .foregroundStyle(Color.Theme.Text.black)

                Spacer()
                Button {
                    onEdit()
                } label: {
                    HStack {
                        Image("icon-edit-child-account")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.Theme.Text.black3)
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, 4)
                }
            }
        }
    }
}

// MARK: - ProfileSecureView.ItemCell.Style

extension ProfileSecureView.ItemCell {
    enum Style {
        case arrow
        case toggle
    }
}

// MARK: - Previews_ProfileSecureView_Previews

struct Previews_ProfileSecureView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSecureView()
    }
}
