//
//  ProfileEditView.swift
//  Flow Wallet
//
//  Created by Selina on 14/6/2022.
//

import Kingfisher
import SwiftUI

// MARK: - ProfileEditView_Previews

struct ProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileEditView()
    }
}

// MARK: - ProfileEditView

struct ProfileEditView: RouteableView {
    // MARK: Internal

    var title: String {
        "edit_account".localized
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                editContainer
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                removeAccount()
            } label: {
                Text("edit_account".localized)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.Theme.Accent.red)
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 18)
        }
        .backgroundFill(.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    var editContainer: some View {
        VStack(spacing: 0) {
            editAvatarCell
            BaseDivider()
            editNicknameCell
            BaseDivider()
            editPrivateCell
        }
        .background(Color.LL.bgForIcon)
        .cornerRadius(16)
        .padding(.horizontal, 18)
    }

    // MARK: Private

    @StateObject
    private var vm = ProfileEditViewModel()

    func removeAccount() {
        Router.route(to: RouteMap.Profile.removeWallet(nil))
    }
}

extension ProfileEditView {
    var editAvatarCell: some View {
        HStack {
            Text("edit_avatar".localized)
                .font(titleFont)
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            KFImage.url(URL(string: vm.state.avatar))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .frame(height: 70)
        .onTapGestureOnBackground {
            vm.trigger(.editAvatar)
        }
    }

    var editNicknameCell: some View {
        HStack {
            Text("edit_nickname".localized)
                .font(titleFont)
                .foregroundColor(titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(vm.state.nickname)
                .font(.inter(size: 16, weight: .medium))
                .foregroundColor(.LL.Neutrals.note)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .onTapGestureOnBackground {
            Router.route(to: RouteMap.Profile.editName)
        }
    }

    var editPrivateCell: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("private".localized)
                    .font(titleFont)
                    .foregroundColor(titleColor)

                Text(
                    vm.state.isPrivate ? "private_on_desc".localized : "private_off_desc"
                        .localized
                )
                .font(.inter(size: 12))
                .foregroundColor(.LL.Neutrals.note)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 24) {
                Button {
                    vm.trigger(.changePrivate(false))
                } label: {
                    VStack {
                        ZStack(alignment: .bottomTrailing) {
                            Image("icon-visible")
                            Image("icon-selected-small")
                                .visibility(vm.state.isPrivate ? .gone : .visible)
                                .padding(.trailing, -3)
                                .padding(.bottom, -3)
                        }

                        Text("visible".localized)
                            .font(.inter(size: 12))
                            .foregroundColor(.LL.Neutrals.note)
                    }
                }

                Button {
                    vm.trigger(.changePrivate(true))
                } label: {
                    VStack {
                        ZStack(alignment: .bottomTrailing) {
                            Image("icon-unvisible")
                            Image("icon-selected-small")
                                .visibility(vm.state.isPrivate ? .visible : .gone)
                                .padding(.trailing, -3)
                                .padding(.bottom, -3)
                        }

                        Text("unvisible".localized)
                            .font(.inter(size: 12))
                            .foregroundColor(.LL.Neutrals.note)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 88)
    }
}

extension ProfileEditView {
    var titleColor: Color {
        .LL.Neutrals.text
    }

    var titleFont: Font {
        .inter(size: 17, weight: .medium)
    }
}
