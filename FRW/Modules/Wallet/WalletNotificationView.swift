//
//  WalletNotificationView.swift
//  FRW
//
//  Created by cat on 2024/6/27.
//

import Kingfisher
import SwiftUI

// MARK: - WalletNotificationView

struct WalletNotificationView: View {
    // MARK: Internal

    let item: RemoteConfigManager.News
    var onClose: (String) -> Void
    var onAction: (String) -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 12) {
                if item.iconURL != nil {
                    KFImage.url(item.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
//                        .cornerRadius(12)
                        .clipped()
                        .allowsHitTesting(false)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title)
                        .font(.inter(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Color.Theme.Text.black)
                        .frame(height: 24)
                        .allowsHitTesting(false)

                    if let subtitle = item.body {
                        Text(subtitle)
                            .font(.inter(size: 14))
                            .underline(item.url != nil)
                            .lineLimit(2)
                            .foregroundStyle(Color.Theme.Text.black8)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
        }
        .background(content: {
            if let bgImage = item.image, item.type == .image {
                KFImage.url(URL(string: bgImage))
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        })
        .overlay(alignment: .topTrailing) {
            Button {
                onClose(item.id)
            } label: {
                Image("icon_close_circle_gray")
                    .foregroundColor(.gray)
                    .frame(width: 16, height: 16)
                    .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(Color.Theme.Background.grey)
        .cornerRadius(16)
        .shadow(color: Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.32), radius: 2, x: 0, y: 4)
        .opacity(opacity)
    }

    // MARK: Private

    @State
    private var opacity: Double = 1.0
}

// MARK: - Demo

extension RemoteConfigManager.News {
    static let sample = RemoteConfigManager.News(
        id: "22722ad7-fd47-4167-a7e6-c4c69973bc5d",
        priority: .high,
        type: .image,
        title: "Missing USDC?",
        body: "Please upgrade USDC to USDCf",
        icon: "https://cdn.jsdelivr.net/gh/FlowFans/flow-token-list@main/token-registry/A.b19436aae4d94622.FiatToken/logo.svg",
        image: "https://w.wallhaven.cc/full/3l/wallhaven-3lv8j6.jpg",
        url: "https://port.flow.com/transaction?hash=a32bf0cabf37d52ca3c60daccc10b9ba79db5975d29e7a105d96983b918788e4",
        expiryTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
        displayType: .click,
        conditions: nil
    )
}

// MARK: - WalletNotificationView_Previews

struct WalletNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        WalletNotificationView(
            item: .sample,
            onClose: { _ in },
            onAction: { _ in }
        )
        .previewDisplayName("Missing USDC")
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

#Preview("Insufficient Storage") {
    let insufficientStorage = RemoteConfigManager.News(
        id: "22722ad7-fd47-4167-a7e6-c4c69973bc5d",
        priority: .urgent,
        type: .message,
        title: "Insufficient storage",
        body: "Add FLOW to earn more storage.",
        icon: "https://i.imgur.com/aGrNKe9.png",
        image: nil,
        url: "fw://buyFlow",
        expiryTime: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
        displayType: .expiry,
        conditions: nil)
    
    WalletNotificationView(
        item: insufficientStorage,
        onClose: {_ in },
        onAction: {_ in }
    )
    .padding()
}
