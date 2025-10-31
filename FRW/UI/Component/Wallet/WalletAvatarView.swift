//
//  WalletAvatarView.swift
//  FRW
//
//  Created by cat on 10/31/25.
//

import SwiftUI
import Kingfisher



struct WalletAvatarView: View {
  let emoji: WalletAccount.Emoji?
  let avatar: String?
  let size: WalletAvatarSize
  var showBorder: Bool = false

  init(
    emoji: WalletAccount.Emoji? = nil,
    avatar: String? = nil,
    size: WalletAvatarSize = .normal,
    showBorder: Bool = false
  ) {
    self.emoji = emoji
    self.avatar = avatar
    self.size = size
    self.showBorder = showBorder
  }

  var body: some View {
    ZStack {
      // 圆环背景
      if showBorder {
        Circle()
          .strokeBorder(
            LinearGradient(
              colors: [.Brain.Primary.main],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: size.boarder
          )
          .frame(width: size.width, height: size.width)
      }
      
      // 内容
      ZStack {
        if let avatarURL = avatar, let url = URL(string: avatarURL) {
          KFImage.url(url)
            .placeholder {
              Circle()
                .fill(Color.gray.opacity(0.2))
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.content, height: size.content)
            .clipShape(Circle())
        } else if let emoji = emoji {
            emoji.icon(size: size.content)
        } else {
          Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size.content, height: size.content)
        }
      }
    }
  }
}

enum WalletAvatarSize {

  case normal
  case small
  
  var width: CGFloat {
    switch self {
    case .normal:
      return 42
    case .small:
      return 16
    }
  }
  var content: CGFloat {
    switch self {
    case .normal:
      return 36
    case .small:
      return 12
    }
  }
  
  var boarder: CGFloat {
    switch self {
    case .normal:
      return 1
    case .small:
      return 1
    }
  }
  
  var padding: CGFloat {
    switch self {
    case .normal:
      return 3
    case .small:
      return 2
    }
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 20) {
    // Avatar with emoji
    WalletAvatarView(
      emoji: .panda,
      size: .normal,
      showBorder: true
    )

    // Avatar with different emoji
    WalletAvatarView(
      emoji: .loong,
      size: .normal
    )

    // Avatar with emoji
    WalletAvatarView(
      emoji: .lion,
      size: .normal
    )

    // Avatar with URL
    WalletAvatarView(
      avatar: "https://example.com/avatar.png",
      size: .normal
    )

    // Default avatar (no emoji)
    WalletAvatarView(size: .normal)
  }
  .padding()
}


