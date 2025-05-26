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
        "import_account".localized
    }

    var body: some View {
        VStack(alignment: .center, spacing: 18) {
            VStack(alignment: .center, spacing: 8) {
                Text("from_multi_backup".localized)
                    .font(.inter(size: 24, weight: .w700))
                    .foregroundColor(Color.Summer.Text.primary)

                Text("from_multi_backup_desc".localized)
                    .font(.inter(size: 14))
                    .foregroundColor(.Summer.Text.secondary)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                ForEach(viewModel.list.indices, id: \.self) { index in
                    let item = $viewModel.list[index]
                    MultiBackupItemView(item: item) { item in
                        onClick(item: item)
                    }
                }
            }

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
