//
//  File.swift
//  FRW
//
//  Created by Hao Fu on 5/4/2025.
//

import Foundation
import SwiftUI

// MARK: - WalletActionButton

struct WalletActionButton: View {
    enum Action: String {
        case send, receive, swap, stake, buy

        // MARK: Internal

        var icon: String {
            switch self {
            case .send:
                return "icon_token_send"
            case .receive:
                return "icon_token_recieve"
            case .swap:
                return "wallet-swap-stroke"
            case .stake:
                return "icon_wallet_action_stake"
            case .buy:
                return "WalletIconBuy"
            }
        }

        // MARK: Private

        private func incrementUrl() -> String {
            if LocalUserDefaults.shared.flowNetwork == .mainnet {
                return "https://app.increment.fi/swap"
            } else {
                return "https://demo.increment.fi/swap"
            }
        }
    }

    let event: Action
    let allowClick: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack {
                HStack(alignment: .center) {
                    VStack {
                        Image(event.icon)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.white.opacity(allowClick ? 1 : 0.3))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.vertical, 10)
                .frame(width: 50, height: 50, alignment: .center)
                .background(Color.Theme.Accent.green)
                .cornerRadius(25)

                Text(event.rawValue.localized.capitalized)
                    .font(.inter(size: 12))
                    .foregroundStyle(Color.Theme.Text.black8.opacity(allowClick ? 1 : 0.3))
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!allowClick)
    }
}
