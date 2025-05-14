//
//  BackupMultiView.swift
//  FRW
//
//  Created by cat on 2023/12/7.
//

import SwiftUI
import SwiftUIX

// MARK: - BackupMultiView

struct BackupMultiView: RouteableView {
    // MARK: Lifecycle

    init(items: [MultiBackupType]) {
        _viewModel = StateObject(wrappedValue: BackupMultiViewModel(backups: items))
    }

    // MARK: Internal

    @StateObject
    var viewModel: BackupMultiViewModel

    var title: String {
        "multi_backup".localized
    }

    var body: some View {
        VStack {
            VStack(spacing: 15) {
                Text("multi_backup_guide_title".localized)
                    .font(.inter(size: 16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.Theme.Accent.grey)
            }
            .padding(.horizontal, 40)

            LazyVGrid(columns: columns(), spacing: 40) {
                ForEach(viewModel.list.indices, id: \.self) { index in
                    let item = $viewModel.list[index]
                    ItemView(item: item) { item in
                        onClick(item: item)
                    }
                    .frame(maxWidth: 136)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)

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
        .applyRouteable(self)
        .tracedView(self)
        .backgroundFill(Color.LL.Neutrals.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onLearnMore()
                } label: {
                    Image("questionmark.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(2)
                }
            }
        }
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

    func onLearnMore() {
        viewModel.onLearnMore()
    }
}

// MARK: BackupMultiView.ItemView

extension BackupMultiView {
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
            VStack(alignment: .center, spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .inset(by: 1)
                            .stroke(Color.Theme.Accent.green, lineWidth: isSelected ? 2 : 0)
                            .background(.Theme.Background.white)
                            .cornerRadius(24)
                        Image(item.icon)
                            .frame(width: 68, height: 68)
                            .padding(.all, 14)
                    }

                    Image("check_circle_border")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .offset(x: 6, y: -6)
                        .visibility(isSelected ? .visible : .gone)
                }
                .frame(width: 96, height: 96)

                Text(item.name)
                    .font(.inter(size: 14))
                    .foregroundStyle(Color.Theme.Text.black8)
                    .frame(height: 24)
            }
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
    BackupMultiView(items: [])
}
