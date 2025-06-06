//
//  UnlinkConfirmView.swift
//  FRW
//
//  Created by cat on 6/6/25.
//

import FlowWalletKit
import Kingfisher
import SwiftUI

struct UnlinkConfirmView: View {
    // MARK: Internal

    let childAccount: FlowWalletKit.ChildAccount
    let onConfirm: EmptyClosure

    var body: some View {
        VStack {
            SheetHeaderView(title: "unlink_confirmation".localized)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    fromToView
                    Indicator()
                        .padding(.bottom, 38)
                }
                .background(Color.LL.background)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), x: 0, y: 4, blur: 16)
                .padding(.horizontal, 18)

                descView
                    .padding(.top, -20)
                    .padding(.horizontal, 28)
                    .zIndex(-1)

                Spacer()

                confirmButton
                    .padding(.bottom, 10)
                    .padding(.horizontal, 28)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    var fromToView: some View {
        HStack {
            ChildAccountTargetView(
                iconURL: childAccount.icon?.absoluteString ?? "",
                name: childAccount.name ?? "",
                address: childAccount.infoAddress
            )

            Spacer()

            ChildAccountTargetView(
                iconURL: UserManager.shared.userInfo?.avatar.convertedAvatarString() ?? "",
                name: UserManager.shared.userInfo?.meowDomain ?? "",
                address: fromUser?.infoAddress ?? "0x"
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
    }

    var fromUser: AccountInfoProtocol? {
        UserManager.shared.mainAccount(by: childAccount.infoAddress)
    }

    var descView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("unlink_account".localized.uppercased())
                .font(.inter(size: 14, weight: .semibold))
                .foregroundColor(Color.LL.Neutrals.text4)

            Text("unlink_account_desc_x".localized(childAccount.name ?? ""))
                .font(.inter(size: 14, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 18)
        .padding(.top, 44)
        .padding(.bottom, 34)
        .background(Color.LL.Neutrals.neutrals6)
        .cornerRadius(16)
    }

    var confirmButton: some View {
        WalletSendButtonView(
            allowEnable: .constant(true),
            buttonText: "hold_to_unlink".localized
        ) {
            onConfirm()
        }
    }
}

private struct ChildAccountTargetView: View {
    @State
    var iconURL: String
    @State
    var name: String
    @State
    var address: String

    var body: some View {
        VStack(spacing: 8) {
            KFImage.url(URL(string: iconURL))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .cornerRadius(20)

            Text(name)
                .font(.inter(size: 10, weight: .semibold))
                .foregroundColor(Color.LL.Neutrals.text)
                .lineLimit(1)

            Text(address)
                .font(.inter(size: 10, weight: .medium))
                .foregroundColor(.LL.Neutrals.note)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}

private struct Indicator: View {
    var styleColor: Color {
        Color(hex: "#CCCCCC")
    }

    var barColors: [Color] {
        [.clear, styleColor]
    }

    var body: some View {
        HStack(spacing: 0) {
            dotView
            lineView(start: .leading, end: .trailing)
            shortLine
                .padding(.horizontal, 4)

            Image("unlink-indicator")
                .renderingMode(.template)
                .foregroundColor(styleColor)

            shortLine
                .padding(.horizontal, 4)
            lineView(start: .trailing, end: .leading)
            dotView
        }
        .frame(width: 114, height: 8)
    }

    var shortLine: some View {
        Rectangle()
            .frame(width: 4, height: 2)
            .foregroundColor(styleColor)
    }

    var dotView: some View {
        Circle()
            .frame(width: 8, height: 8)
            .foregroundColor(styleColor)
    }

    func lineView(start: UnitPoint, end: UnitPoint) -> some View {
        LinearGradient(colors: barColors, startPoint: start, endPoint: end)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}
