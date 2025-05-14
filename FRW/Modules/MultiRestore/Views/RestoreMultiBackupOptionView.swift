//
//  RestoreMultiBackupOptionView.swift
//  FRW
//
//  Created by cat on 2024/1/7.
//

import SwiftUI

struct RestoreMultiBackupOptionView: RouteableView {
    @StateObject
    var viewModel: RestoreMultiBackupOptionViewModel = .init()

    var title: String {
        ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("restore".localized)
                        .foregroundColor(Color.Theme.Accent.green)
                        .bold()
                    Text("wallet".localized)
                        .foregroundColor(Color.Theme.Accent.green)
                        .bold()
                }
                .font(.LL.largeTitle)

                Text("from_multi_backup".localized)
                    .foregroundColor(Color.Theme.Text.black8)
                    .font(.LL.largeTitle)
                    .bold()

                Text("from_multi_backup_desc".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns(), spacing: 40) {
                ForEach(viewModel.list.indices, id: \.self) { index in
                    let item = $viewModel.list[index]
                    BackupMultiView.ItemView(item: item) { item in
                        onClick(item: item)
                    }
                    .frame(height: 136)
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 64)

            Spacer()

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.nextable ? .enabled : .disabled,
                action: {
                    onNext()
                },
                title: "next".localized
            )
            .padding(.horizontal, 18)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    func columns() -> [GridItem] {
        let width = (screenWidth - 64 * 2) / 2
        return [
            GridItem(.adaptive(minimum: width)),
            GridItem(.adaptive(minimum: width)),
        ]
    }

    func onClick(item: BackupMultiViewModel.MultiItem) {
        viewModel.onClick(item: item)
    }

    func onNext() {
        viewModel.onNext()
    }
}

#Preview {
    RestoreMultiBackupOptionView()
}
