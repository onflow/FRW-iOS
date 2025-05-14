//
//  WalletResetConfirmView.swift
//  Flow Wallet
//
//  Created by Selina on 25/10/2022.
//

import SwiftUI

// MARK: - WalletResetConfirmView

struct WalletResetConfirmView: RouteableView {
    // MARK: Internal

    var title: String {
        "reset_wallet".localized
    }

    var body: some View {
        VStack {
            Image("icon-wallet-reset")
                .padding(.top, 40)

            Text("delete_wallet_confirm_title".localized)
                .font(.inter(size: 18, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text)
                .padding(.top, 24)

            Text("delete_wallet_confirm_desc".localized)
                .font(.LL.footnote)
                .foregroundColor(Color.LL.Neutrals.text)
                .padding(.top, 12)
                .padding(.horizontal, 12)

            Text(AttributedString(descAttributeString))
                .padding(.top, 20)

            ZStack {
                TextField("", text: $vm.text)
                    .disableAutocorrection(true)
                    .font(.inter(size: 18, weight: .medium))
                    .frame(height: 50)
            }
            .padding(.horizontal, 10)
            .border(Color.LL.Neutrals.text, cornerRadius: 6)

            Spacer()

            Button {
                vm.resetWalletAction()
            } label: {
                Text("delete_wallet".localized)
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
    }

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
            string: "reset_wallet_desc_1".localized,
            attributes: normalAttr
        )
        let str2 = NSAttributedString(
            string: "delete_wallet_desc_2".localized,
            attributes: highlightAttr
        )
        let str3 = NSMutableAttributedString(
            string: "reset_wallet_desc_3".localized,
            attributes: normalAttr
        )

        str1.append(str2)
        str1.append(str3)
        return str1
    }

    // MARK: Private

    @StateObject
    private var vm = WalletResetConfirmViewModel()
}

// MARK: - WalletResetConfirmView_Previews

struct WalletResetConfirmView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WalletResetConfirmView()
        }
    }
}
