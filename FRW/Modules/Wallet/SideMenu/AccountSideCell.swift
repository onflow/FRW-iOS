//
//  AccountSideCell.swift
//  FRW
//
//  Created by cat on 2024/5/27.
//

import Kingfisher
import SwiftUI

struct AccountSideCell: View {
    // MARK: Internal

    var address: String
    var currentAddress: String
    var name: String? = nil
    var logo: String? = nil
    
    @Binding
    var balance: String?
    
    var onClick: (String) -> Void
    
    var body: some View {
        Button {
            NotificationCenter.default.post(name: .toggleSideMenu)
            onClick(address)
        } label: {
            HStack(spacing: 0) {
                if let logoUrl = logo {
                    KFImage.url(URL(string: logoUrl))
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 24, height: 24)
                        .cornerRadius(12)
                        .padding(.trailing, 18)
                } else {
                    user.emoji.icon()
                        .padding(.trailing, 18)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(name ?? user.name)
                            .font(.inter(size: 14, weight: .semibold))
                            .foregroundStyle(Color.Theme.Text.black8)
                            .frame(height: 22)

                        EVMTagView()
                            .visibility(isEVM ? .visible : .gone)

                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundColor(Color.Theme.Accent.green)
                            .visibility(isSelected ? .visible : .gone)
                    }

                    Text(address)
                        .font(.inter(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(Color.Theme.Text.black3)
                        .frame(height: 20)

                    if let balance {
                        Text(balance)
                            .font(.inter(size: 12))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundStyle(Color.Theme.Text.black8)
                    }
                }
                Spacer()

                Button {
                    UIPasteboard.general.string = address
                    HUD.success(title: "Address Copied".localized)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        Image("icon_copy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(Color.Theme.Text.black3)
                            .frame(width: 20, height: 20)
                    }
                    .padding(12)
                    .offset(x: -4)
                }

//                Image("device_arrow_right")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 8, height: 14)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background {
                if isSelected {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(
                                color: Color.Theme.Accent.green.opacity(0),
                                location: 0.00
                            ),
                            Gradient.Stop(
                                color: Color.Theme.Accent.green.opacity(0.08),
                                location: 1.00
                            ),
                        ],
                        startPoint: UnitPoint(x: 1.11, y: 0.4),
                        endPoint: UnitPoint(x: 0, y: 0.4)
                    )
                }
            }
            .cornerRadius(12)
        }
    }

    // MARK: Private

    private var network: FlowNetworkType {
        LocalUserDefaults.shared.flowNetwork
    }

    private var user: WalletAccount.User {
        WalletManager.shared.walletAccount.readInfo(at: address)
    }

    private var isSelected: Bool {
        if address == currentAddress {
            return true
        }
        return false
    }

    private var isEVM: Bool {
        if let evmAddress = EVMAccountManager.shared.accounts.first?.showAddress {
            return evmAddress.lowercased() == address.lowercased()
        }
        return false
    }
}
