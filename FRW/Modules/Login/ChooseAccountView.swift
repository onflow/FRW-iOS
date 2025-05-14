//
//  ChooseAccountView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 31/12/21.
//

import SwiftUI

private func createFakeItem() -> BackupManager.DriveItem {
    let item = BackupManager.DriveItem()
    item.username = UUID().uuidString
    return item
}

extension ChooseAccountView {
    var title: String {
        ""
    }
}

// MARK: - ChooseAccountView

struct ChooseAccountView: RouteableView {
    // MARK: Lifecycle

    init(driveItems: [BackupManager.DriveItem], backupType: BackupManager.BackupType) {
        _vm = StateObject(wrappedValue: ChooseAccountViewModel(
            driveItems: driveItems,
            backupType: backupType
        ))
    }

    // MARK: Internal

    @StateObject
    var vm: ChooseAccountViewModel

    var body: some View {
        VStack(spacing: 10) {
            headerView
            Spacer()
            listView
                .padding(.top, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 28)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("choose".localized)
                    .foregroundColor(Color.LL.text)
                    .bold()
                Text("account".localized)
                    .foregroundColor(Color.LL.orange)
                    .bold()
            }
            .font(.LL.largeTitle)

            Text("multiple_accounts_found".localized(vm.items.count))
                .font(.LL.body)
                .foregroundColor(.LL.note)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var listView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(0 ..< vm.items.count, id: \.self) { index in
                    let item = vm.items[index]
                    Button {
                        vm.restoreAccountAction(item: item)
                    } label: {
                        createAccountView(item: item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(.plain)
    }

    func createAccountView(item: BackupManager.DriveItem) -> some View {
        ZStack {
            Text(item.username ?? "")
                .font(.inter(size: 14, weight: .bold))
                .foregroundColor(.LL.Neutrals.text)
                .lineLimit(1)
                .padding(.horizontal, 35)

            HStack {
                Spacer()
                Image("icon-account-arrow-right")
                    .renderingMode(.template)
                    .foregroundColor(.LL.Neutrals.text)
            }
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(.LL.Neutrals.outline)
        .cornerRadius(16)
    }
}

// struct ChooseAccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChooseAccountView(driveItems: [])
//    }
// }
