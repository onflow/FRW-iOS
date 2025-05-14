//
//  PushAlertView.swift
//  Flow Wallet
//
//  Created by Selina on 25/7/2023.
//

import SwiftUI

struct PushAlertView: RouteableView {
    var title: String {
        ""
    }

    var body: some View {
        VStack {
            Text("turn_on_noti_title")
                .font(.inter(size: 24, weight: .bold))
                .foregroundColor(Color.LL.Neutrals.text)
                .padding(.vertical, 12)

            Text("turn_on_noti_desc")
                .font(.inter(size: 14))
                .foregroundColor(Color.LL.Neutrals.text2)
                .multilineTextAlignment(.center)

            Spacer()

            Image("img-noti")

            Spacer()

            turnOnButton
                .padding(.bottom, 16)

            laterButton
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 28)
        .backgroundFill(Color.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    var turnOnButton: some View {
        Button {
            backButtonAction()
            PushHandler.shared.requestPermission()
        } label: {
            Text("turn_on_noti_title".localized)
                .foregroundColor(Color.LL.Button.text)
                .font(.inter(size: 14, weight: .bold))
                .frame(height: 54)
                .frame(maxWidth: .infinity)
                .background(Color.LL.Button.color)
                .cornerRadius(12)
        }
    }

    var laterButton: some View {
        Button {
            backButtonAction()
        } label: {
            Text("maybe_later_text".localized)
                .foregroundColor(Color.LL.Neutrals.text2)
                .font(.inter(size: 14, weight: .medium))
        }
    }

    func backButtonAction() {
        Router.dismiss()
    }
}
