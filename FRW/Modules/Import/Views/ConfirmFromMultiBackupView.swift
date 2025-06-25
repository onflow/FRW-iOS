//
//  ConfirmFromMultiBackupView.swift
//  FRW
//
//  Created by cat on 6/26/25.
//

import SwiftUI

struct ConfirmFromMultiBackupView: RouteableView {
    @ObservedObject var importViewModel: ImportWalletViewModel
    @StateObject var viewModel: ConfirmFromMultiBackupViewModel

    var title: String {
        importViewModel.title
    }

    init(importViewModel: ImportWalletViewModel, items: [[MultiBackupManager.StoreItem]]) {
        self.importViewModel = importViewModel
        _viewModel = StateObject(wrappedValue: ConfirmFromMultiBackupViewModel(items: items))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .center, spacing: 0) {
                Text("confirm_which_account".localized)
                    .font(.inter(size: 24, weight: .w700))
                    .foregroundStyle(Color.Theme.Text.text1)
                    .padding(.bottom, 36)
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    ForEach(0 ..< viewModel.accounts.count, id: \.self) { index in
                        let account = viewModel.accounts[index]
                        VStack(spacing: 0) {
                            AccountInfoView(account: account, isActivity: false, isSelected: false, action: .check(viewModel.isCheck(account))) { _, _ in
//                                viewModel.onClick(model)
                            }
                            ForEach(0 ..< account.linkedAccounts.count, id: \.self) { index in
                                let linkedAccount = account.linkedAccounts[index]
                                AccountInfoView(account: linkedAccount, isActivity: false, isSelected: false, action: .check(viewModel.isCheck(linkedAccount))) { _, _ in
//                                    viewModel.onClick(model)
                                }
                            }
                        }
                        .cardStyle()
                    }
                }
                Text("confirm_which_account_des".localized)
                    .font(.inter(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.Theme.Text.black6)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 18)
        }

        VPrimaryButton(
            model: ButtonStyle.primary,
            state: .enabled,
            action: {},
            title: "import_account".localized
                .uppercasedFirstLetter()
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 42)
        .applyRouteable(self)
        .task {
            await viewModel.fetchInfo()
        }
    }
}

#Preview {
    ConfirmFromMultiBackupView(importViewModel: .init(importType: .account), items: [])
}
