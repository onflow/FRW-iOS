//
//  AccountInfoView.swift
//  FRW
//
//  Created by cat on 5/29/25.
//

import FlowWalletKit
import SwiftUI

struct AccountInfoView: View {
    var account: AccountModel
    var isActivity: Bool = false
    var isSelected: Bool = false
    var backgroundColor: Color = .clear
    var action: Action = .copy
    var onClick: ((AccountModel, AccountInfoView.Action) -> Void)? = nil

    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                if !account.isMain && !isActivity {
                    Image("icon-link")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.leading, 8)
                }
                if let data = account.mainAccount?.walletMetadata {
                    account.account.avatar(isSelected: isSelected, subAvatar: isActivity ? .user(data) : nil)
                } else {
                    account.account.avatar(isSelected: isSelected, subAvatar: nil)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        if !account.isMain && isActivity {
                            Image("icon-link")
                                .resizable()
                                .frame(width: 12, height: 12)
                        }
                        Text(account.account.infoName)
                            .font(.inter(size: 14, weight: .w600))
                            .foregroundStyle(Color.Summer.Text.primary)
                        if account.isCoa {
                            TagView(type: .evm)
                        }
                    }

                    Text(account.account.infoAddress)
                        .font(.inter(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(Color.Summer.Text.secondary)

                    HStack(spacing: 0) {
                        Text(account.showAmount)
                            .font(.inter(size: 12))
                            .foregroundStyle(Color.Summer.Text.secondary)
                            .animation(.easeInOut, value: account.showAmount)
                        Spacer()
                    }
                }
                Spacer(minLength: 2)
                switch action {
                case .copy:
                    copyAction()
                case .arrow:
                    arrowAction()
                case .hide:
                    hideAction()
                case .card:
                    HStack {}
                case let .check(isCheck):
                    checkAction(isCheck: isCheck)
                }
            }
            .padding(.leading, isActivity ? 12 : 5)
            .padding(.trailing, isActivity ? 16 : 0)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: isActivity ? 16 : 0)
                    .fill(isActivity ? Color.Summer.cards : backgroundColor)
            }
            .overlay {
                if !isActivity && !isSelected {
                    RoundedRectangle(cornerRadius: isActivity ? 16 : 0)
                        .fill(backgroundColor.opacity(0.3))
                        .allowsHitTesting(false)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 0))
            .onTapGesture {
                onClick?(account, .card)
            }
        }
    }

    @ViewBuilder
    func copyAction() -> some View {
        HStack {
            Button {
                UIPasteboard.general.string = account.account.infoAddress
                HUD.success(title: "Address Copied".localized)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image("icon_button_copy")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
    }

    @ViewBuilder
    func hideAction() -> some View {
        HStack(spacing: 0) {
            Button {} label: {
                Image("icon-wallet-hidden-on")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fill)
                    .foregroundColor(Color.Theme.Text.black3)
                    .frame(width: 24, height: 24)
                    .padding(12)
            }

            Image("device_arrow_right")
                .resizable()
                .frame(width: 24, height: 24)
        }
    }

    @ViewBuilder
    func arrowAction() -> some View {
        Image("device_arrow_right")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
    }

    @ViewBuilder
    func checkAction(isCheck: Bool) -> some View {
        HStack {
            if account.isMain {
                Button {
                    onClick?(account, .check(isCheck))
                } label: {
                    Image(isCheck ? .checkBoxSelected : .checkBoxNormal)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}

extension AccountInfoView {
    enum Action {
        case card
        case copy
        case arrow
        case hide
        case check(Bool)
    }
}

#Preview {
    VStack {
        AccountInfoView(account: AccountModel.mockSamples()[0], isActivity: true, action: .arrow)
        AccountInfoView(account: AccountModel.mockSamples()[1], isActivity: true)
        AccountInfoView(account: AccountModel.mockSamples()[0], isActivity: false, isSelected: true)
        AccountInfoView(account: AccountModel.mockSamples()[1], isSelected: true)
        AccountInfoView(account: AccountModel.mockSamples()[2], isSelected: false)
    }
    .background(Color.Summer.Background.nav)
    .padding(.vertical, 50)
    .background(.gray)
}
