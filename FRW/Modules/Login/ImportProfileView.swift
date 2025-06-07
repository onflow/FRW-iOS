//
//  ImportProfileView.swift
//  FRW
//
//  Created by cat on 6/7/25.
//

import FlowWalletKit
import SwiftUI

struct ImportProfileView: RouteableView {
    @StateObject private var viewModel: ImportProfileViewModel

    var title: String {
        "import_profile".localized
    }

    init(viewModel: ImportProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 0) {
                    Text("confirm_which_account".localized)
                        .font(.inter(size: 24, weight: .w700))
                        .foregroundStyle(Color.Theme.Text.text1)
                        .padding(.bottom, 36)
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        ForEach(0 ..< viewModel.accounts.count, id: \.self) { index in
                            VStack(spacing: 0) {
                                ForEach(viewModel.accounts[index], id: \.account.infoAddress) { account in
                                    AccountInfoView(account: account, isActivity: false, isSelected: false, action: .check(viewModel.isCheck(account))) { model, _ in
                                        viewModel.onClick(model)
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
                state: viewModel.hideAccount.count == viewModel.accounts.count ? .disabled : .enabled,
                action: {
                    viewModel.onImportAccount()
                },
                title: "import_account".localized
                    .uppercasedFirstLetter()
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 42)
        }
        .applyRouteable(self)
        .task {
            await viewModel.fetchInfo()
        }
    }
}
