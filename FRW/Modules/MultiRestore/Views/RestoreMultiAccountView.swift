//
//  RestoreMultiAccountView.swift
//  FRW
//
//  Created by cat on 2024/1/7.
//

import Kingfisher
import SwiftUI

// MARK: - RestoreMultiAccountView

struct RestoreMultiAccountView: RouteableView {
    // MARK: Lifecycle

    init(_ items: [[MultiBackupManager.StoreItem]]) {
        _viewModel = StateObject(wrappedValue: RestoreMultiAccountViewModel(items: items))
    }

    // MARK: Internal

    @StateObject
    var viewModel: RestoreMultiAccountViewModel

    var title: String {
        ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("confirm_tag".localized)
                    .font(.inter(size: 30, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.black8)
                HStack {
                    Text("importing_tag".localized)
                        .font(.inter(size: 30, weight: .bold))
                        .foregroundStyle(Color.Theme.Text.black8)
                    Text("wallet".localized)
                        .font(.inter(size: 30, weight: .bold))
                        .foregroundStyle(Color.Theme.Accent.green)
                }
            }

            Text("find_matching_wallet".localized)
                .font(.inter(size: 16, weight: .semibold))
                .foregroundStyle(Color.Theme.Accent.grey)
                .padding(.top, 14)

            Color.clear
                .frame(height: 50)
            ScrollView {
                ForEach(0 ..< viewModel.items.count, id: \.self) { index in
                    let item = viewModel.items[index]
                    RestoreMultiAccountView.UserInfoView(user: item.first!, index: index) { idx in
                        viewModel.onClickUser(at: idx)
                    }
                    .padding(.bottom, 16)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .applyRouteable(self)
        .tracedView(self)
    }
}

// MARK: RestoreMultiAccountView.UserInfoView

extension RestoreMultiAccountView {
    struct UserInfoView: View {
        let user: MultiBackupManager.StoreItem
        let index: Int
        let onClick: (Int) -> Void

        var body: some View {
            HStack(spacing: 12) {
                KFImage.url(URL(string: (user.userAvatar ?? "").convertedAvatarString()))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .cornerRadius(18)
                VStack(alignment: .leading, spacing: 8) {
                    Text("@\(user.userName)")
                        .font(.inter(size: 12, weight: .bold))
                        .foregroundColor(Color.Theme.Text.black8)

                    Text("\(user.address)")
                        .font(.inter(size: 12))
                        .foregroundColor(Color.Theme.Text.black3)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .frame(maxWidth: .infinity)
            .background(Color.Theme.Line.line)
            .contentShape(Rectangle())
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.04), x: 0, y: 4, blur: 16)
            .onTapGesture {
                onClick(index)
            }
        }
    }
}

#Preview {
    RestoreMultiAccountView([])
}
