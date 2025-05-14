//
//  ProfileBackupView.swift
//  Flow Wallet
//
//  Created by Selina on 2/8/2022.
//

import SwiftUI

extension BackupManager.BackupType {
    var littleIcon: String {
        switch self {
        case .icloud:
            return "icon-icloud"
        case .googleDrive:
            return "icon-gd"
        default:
            return ""
        }
    }
}

// MARK: - ProfileBackupView

struct ProfileBackupView: RouteableView {
    // MARK: Internal

    let types: [BackupManager.BackupType] = [.icloud, .googleDrive]

    var title: String {
        "backup".localized
    }

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                ForEach(types, id: \.self) { type in
                    ItemCell(
                        title: type.descLocalizedString,
                        icon: type.littleIcon,
                        isSelected: vm.selectedBackupType == type
                    ) {
                        vm.changeBackupTypeAction(type)
                    }

                    if type != .manual {
                        Divider().background(Color.LL.Neutrals.background)
                    }
                }
            }
            .padding(.horizontal, 16)
            .roundedBg()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 18)
        }
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @StateObject
    private var vm = ProfileBackupViewModel()
}

// MARK: ProfileBackupView.ItemCell

extension ProfileBackupView {
    struct ItemCell: View {
        let title: String
        let icon: String
        let isSelected: Bool
        let syncAction: () -> Void

        var body: some View {
            HStack(spacing: 0) {
                Image(icon)
                    .frame(width: 32, height: 32)
//                    .background(Color.LL.Secondary.navy5)
//                    .clipShape(Circle())
                    .padding(.trailing, 15)

                Text(title)
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(Color.LL.Neutrals.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: .checkmarkSelected)
                    .foregroundColor(Color.LL.Success.success2)
                    .visibility(isSelected ? .visible : .gone)

                Button {
                    syncAction()
                } label: {
                    Text("btn_sync".localized)
                        .font(.inter(size: 16, weight: .medium))
                        .foregroundColor(Color("0x8C9BAB"))
                }
                .visibility(isSelected ? .gone : .visible)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
    }
}

// MARK: - Previews_ProfileBackupView_Previews

struct Previews_ProfileBackupView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileBackupView()
    }
}
