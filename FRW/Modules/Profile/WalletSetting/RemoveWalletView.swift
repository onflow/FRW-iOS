//
//  RemoveWalletView.swift
//  FRW
//
//  Created by cat on 6/18/25.
//

import SwiftUI

struct RemoveWalletView: RouteableView {
    @StateObject var viewModel: RemoveWalletViewModel

    var title: String

    init(account: AccountInfoProtocol? = nil) {
        let viewModel = RemoveWalletViewModel(account: account)
        _viewModel = StateObject(wrappedValue: viewModel)
        title = viewModel.data.navTitle
    }

    var body: some View {
        VStack {
            Image("icon_remove_account")
                .padding(.top, 30)

            Text(viewModel.data.hintTitle)
                .font(.inter(size: 18, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text)
                .padding(.top, 24)

            Text(viewModel.data.hintDesc)
                .font(.LL.footnote)
                .foregroundColor(Color.LL.Neutrals.text)
                .padding(.top, 12)
                .padding(.horizontal, 12)

            Text(AttributedString(descAttributeString))
                .padding(.top, 20)

            ZStack {
                TextField("", text: $viewModel.text)
                    .disableAutocorrection(true)
                    .font(.inter(size: 18, weight: .medium))
                    .frame(height: 50)
            }
            .padding(.horizontal, 10)
            .border(Color.LL.Neutrals.text, cornerRadius: 6)

            Spacer()

            Button {
                viewModel.removeAccount()
            } label: {
                Text(viewModel.data.buttonTitle)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.LL.Warning.warning2)
                    .cornerRadius(16)
                    .foregroundColor(Color.white)
                    .font(.inter(size: 16, weight: .semibold))
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
        .backgroundFill(.LL.background)
        .applyRouteable(self)
        .tracedView(self)

        var descAttributeString: NSAttributedString {
            let normalAttr: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.LL.Neutrals.text2,
                .font: UIFont.inter(size: 14),
            ]
            let highlightAttr: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.LL.Neutrals.text,
                .font: UIFont.interSemiBold(size: 16),
            ]

            let str1 = NSMutableAttributedString(
                string: viewModel.data.hintConfirm1,
                attributes: normalAttr
            )
            let str2 = NSAttributedString(
                string: viewModel.data.hintConfirm,
                attributes: highlightAttr
            )
            let str3 = NSMutableAttributedString(
                string: viewModel.data.hintConfirm3,
                attributes: normalAttr
            )

            str1.append(str2)
            str1.append(str3)
            return str1
        }
    }
}

#Preview {
    RemoveWalletView()
}
