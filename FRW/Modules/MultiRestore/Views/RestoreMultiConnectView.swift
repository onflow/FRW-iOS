//
//  RestoreMultiConnectView.swift
//  FRW
//
//  Created by cat on 2024/1/7.
//

import SwiftUI

struct RestoreMultiConnectView: RouteableView {
    // MARK: Lifecycle

    init(items: [MultiBackupType]) {
        _viewModel = StateObject(wrappedValue: RestoreMultiConnectViewModel(items: items))
    }

    // MARK: Internal

    @StateObject
    var viewModel: RestoreMultiConnectViewModel

    var title: String {
        "import_wallet".localized
    }

    var body: some View {
        VStack {
            BackupUploadView.ProgressView(
                items: viewModel.items,
                currentIndex: $viewModel.currentIndex
            )
            .padding(.top, 24)
            .padding(.horizontal, 56)

            VStack(spacing: 24) {
                Image(viewModel.currentIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .background(.Theme.Background.white)
                    .cornerRadius(60)
                    .clipped()

                Text(viewModel.currentTitle)
                    .font(.inter(size: 20, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.black)

                Text(viewModel.currentNote)
                    .font(.inter(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.Theme.Accent.grey)
                    .frame(alignment: .top)
                    .visibility(viewModel.isEnd ? .gone : .visible)
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)

            Spacer()

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.enable ? .enabled : .loading,
                action: {
                    viewModel.onClickButton()
                },
                title: viewModel.currentButton
            )
            .padding(.horizontal, 18)
            .padding(.bottom)
        }
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }
}

#Preview {
    RestoreMultiConnectView(items: [.google, .icloud])
}
