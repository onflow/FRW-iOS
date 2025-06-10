//
//  AvatarView.swift
//  FRW
//
//  Created by cat on 5/29/25.
//

import SwiftUI

enum AvatarSource {
    case user(WalletUserProfile.User)
    case url(URL)
    case system(String)
    case image(Image)
}

struct AvatarContentView: View {
    let source: AvatarSource
    let size: CGFloat
    var body: some View {
        Group {
            switch source {
            case let .user(user):
                ZStack {
                    user.emoji.icon(size: size)
                }
            case let .url(url):
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case let .success(image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Color.gray.overlay(Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().padding(size * 0.15))
                    @unknown default:
                        Color.gray
                    }
                }
            case let .system(name):
                Image(systemName: name)
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.accentColor)
            case let .image(image):
                image.resizable().scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct AvatarView: View {
    let mainAvatar: AvatarSource
    let subAvatar: AvatarSource?
    let backgroundColor: Color
    let isSelected: Bool
    let size: CGFloat

    private let borderWidth: CGFloat = 1
    private let selectedBorderColor: Color = Color.Theme.Accent.green

    init(mainAvatar: AvatarSource, subAvatar: AvatarSource? = nil, backgroundColor: Color = .clear, isSelected: Bool = false, size: CGFloat = 36) {
        self.mainAvatar = mainAvatar
        self.subAvatar = subAvatar
        self.isSelected = isSelected
        self.size = size
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AvatarContentView(source: mainAvatar, size: size)
                .padding(2)
                .overlay(
                    Circle()
                        .stroke(isSelected ? selectedBorderColor : Color.clear, lineWidth: borderWidth)
                )
                .contentShape(Circle())
                .accessibilityLabel(Text("main avatar"))
            if let subAvatar = subAvatar {
                AvatarContentView(source: subAvatar, size: size * 0.5)
                    .padding(2)
                    .background(
                        Circle()
                            .fill(backgroundColor)
                    )
                    .offset(x: -6, y: 0)
                    .accessibilityLabel(Text("sub avatar"))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(mainAvatar: .system("person.crop.circle.fill"), subAvatar: .user(.init(emoji: .avocado, address: "0x1234")), isSelected: true)
        AvatarView(mainAvatar: .user(.init(emoji: .cherry, address: "0xabc")), subAvatar: .url(URL(string: "https://avatars.githubusercontent.com/u/1?v=4")!), isSelected: false)
        AvatarView(mainAvatar: .user(.init(emoji: .lion, address: "0xabc")), isSelected: true)
        AvatarView(mainAvatar: .url(URL(string: "https://avatars.githubusercontent.com/u/2?v=4")!), subAvatar: .system("star.fill"), isSelected: false)
    }
}
