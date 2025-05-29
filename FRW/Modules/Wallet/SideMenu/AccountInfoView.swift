//
//  AccountInfoView.swift
//  FRW
//
//  Created by cat on 5/29/25.
//

import FlowWalletKit
import SwiftUI

struct AccountInfoView: View {
    var info: AccountInfoProtocol
    var isActivity: Bool = false
    var isSelected: Bool = false
    var backgroundColor: Color = Color.Summer.Background.nav
    var mainAccount: AccountInfoProtocol? = nil

    var body: some View {
        ZStack {
            HStack(spacing: 12) {
                if !info.isMain && !isActivity {
                    Image("icon-link")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding(.leading, 8)
                }
                if let data = mainAccount?.walletMetadata {
                    info.avatar(isSelected: isSelected, subAvatar: isActivity ? .user(data) : nil)
                } else {
                    info.avatar(isSelected: isSelected, subAvatar: nil)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        if !info.isMain && isActivity {
                            Image("icon-link")
                                .resizable()
                                .frame(width: 12, height: 12)
                        }
                        Text(info.infoName)
                            .font(.inter(size: 14, weight: .w600))
                            .foregroundStyle(Color.Summer.Text.primary)
                        if info.isCoa {
                            TagView(type: .evm)
                        }
                    }

                    Text(info.infoAddress)
                        .font(.inter(size: 12))
                        .truncationMode(.middle)
                        .foregroundStyle(Color.Summer.Text.secondary)

                    HStack(spacing: 0) {
                        Text(info.tokenCount)
                            .font(.inter(size: 12))
                            .foregroundStyle(Color.Summer.Text.secondary)

                        Text(" | ")
                            .font(.inter(size: 12))
                            .foregroundStyle(Color.Summer.Text.secondary)

                        Text(info.nftCount)
                            .font(.inter(size: 12))
                            .foregroundStyle(Color.Summer.Text.secondary)
                        Spacer()
                    }
                }
                Spacer(minLength: 2)

                Button {
                    UIPasteboard.general.string = info.infoAddress
                    HUD.success(title: "Address Copied".localized)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image("icon_button_copy")
                        .resizable()
                        .frame(width: 24, height: 24)
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
        }
    }
}

#Preview {
    VStack {
        AccountInfoView(info: MockAccountInfo(), isActivity: true, isSelected: true, backgroundColor: Color.Summer.Background.nav)

        AccountInfoView(info: MockAccountInfo.linkAccount, isActivity: true, isSelected: true, backgroundColor: Color.Summer.Background.nav, mainAccount: MockAccountInfo())

        AccountInfoView(info: MockAccountInfo.linkAccount, isActivity: false, isSelected: false, backgroundColor: Color.Summer.Background.nav)
        AccountInfoView(info: MockAccountInfo.evmAccount, isActivity: false, isSelected: true, backgroundColor: Color.Summer.Background.nav)
    }
    .background(Color.Summer.Background.nav)
    .padding(.vertical, 50)
    .background(.gray)
}
