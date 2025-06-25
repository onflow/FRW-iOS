//
//  ImportFromMultiBackupView.swift
//  FRW
//
//  Created by cat on 6/24/25.
//

import SwiftUI

struct ImportFromMultiBackupView: RouteableView {
    var title: String {
        importViewModel.title
    }

    @StateObject var viewModel = ImportFromMultiBackupViewModel()
    @ObservedObject var importViewModel: ImportWalletViewModel

    init(_ importViewModel: ImportWalletViewModel) {
        self.importViewModel = importViewModel
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
                    ImportFromMultiBackupView.ItemView(item: item) { item in
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
        .padding(.horizontal, 18)
        .backgroundFill(Color.Summer.Background.nav)
        .navigationBarItems(trailing: HStack(spacing: 6) {
            Button {
                let callback = {}
                Router.route(to: RouteMap.Backup.introduction(.whatMultiBackup, callback, false))
            } label: {
                Image("circle_info")
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
            }
        })
        .applyRouteable(self)
        .tracedView(self)
    }

    func onClick(item: BackupMultiViewModel.MultiItem) {
        viewModel.onClick(item: item)
    }

    func onNext() {
        viewModel.onNext()
    }
}

extension ImportFromMultiBackupView {
    struct ItemView: View {
        // MARK: Lifecycle

        init(
            item: Binding<BackupMultiViewModel.MultiItem>,
            onClick: @escaping (BackupMultiViewModel.MultiItem) -> Void
        ) {
            _item = item
            self.onClick = onClick
            _isSelected = item.isBackup
        }

        // MARK: Internal

        @Binding
        var item: BackupMultiViewModel.MultiItem
        var onClick: (BackupMultiViewModel.MultiItem) -> Void

        var body: some View {
            HStack(spacing: 10) {
                Image(item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 40, maxHeight: 40)

                Text(item.name)
                    .font(.inter(size: 14, weight: .w600))
                    .foregroundStyle(Color.Summer.Text.primary)

                Spacer()

                FCheckBox(isSelected: $isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 68)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.Theme.Special.white1)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 8)
            )
            .onTapGesture {
                onClick(item)
            }
        }

        // MARK: Private

        @Binding
        private var isSelected: Bool
    }
}

#Preview {
    ImportFromMultiBackupView(ImportWalletViewModel(importType: .account))
}
