//
//  MultiBackupItemView.swift
//  FRW
//
//  Created by cat on 5/26/25.
//

import SwiftUI

struct MultiBackupItemView: View {
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
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)

            Text(item.name)
                .font(.inter(size: 14, weight: .w600))
                .foregroundStyle(Color.Summer.Text.primary)

            Spacer()

            FCheckBox(isSelected: $isSelected)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.Summer.cards)
        }
        .clipped()
        .onTapGesture {
            onClick(item)
        }
    }

    // MARK: Private

    @Binding
    private var isSelected: Bool
}

#Preview {
    MultiBackupItemView(item: .constant(BackupMultiViewModel.MultiItem(type: .google, isBackup: false))) { _ in }
}
