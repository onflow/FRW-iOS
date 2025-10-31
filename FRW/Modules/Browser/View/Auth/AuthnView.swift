//
//  AuthnView.swift
//  FRW
//
//  Created by cat on 10/31/25.
//

import SwiftUI
import Kingfisher

struct AuthnView: View {
  @StateObject var viewModel: AuthnViewModel

  init(viewModel: AuthnViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    VStack(spacing: 0) {
      // Main content
      ScrollView {
        VStack(spacing: 13) {
          headerSection
          networkCard
          permissionsTitleCard
          permissionsListCard
          accountSection
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
      }

      // Bottom buttons (fixed)
      actionButtons
        .padding(.horizontal, 18)
        .padding(.bottom, 36)
    }
    .background(Color.Brain.Core.background)
    .cornerRadius(16, corners: [.topLeft, .topRight])
  }
}

// MARK: - Subviews

extension AuthnView {
  // MARK: - Header Section

  private var headerSection: some View {
    HStack(spacing: 8) {
        ZStack {
          KFImage.url(URL(string: viewModel.provider.logo ?? ""))
              .placeholder {
                  Image("placeholder")
                      .resizable()
              }
              .resizable()
              .aspectRatio(contentMode: .fill)
              .clipShape(Circle())
        }
        .padding(5)
        .frame(width: 64, height: 64)
        
      VStack(alignment: .leading, spacing: 0) {
        Text("browser_connecting_to".localized)
          .font(.inter(size: 14))
          .foregroundColor(Color.Theme.Text.text4)
          .lineLimit(1)

        Text(viewModel.provider.title)
          .font(.inter(size: 16, weight: .bold))
          .foregroundColor(.Theme.Text.black)
          .lineLimit(1)
      }

      Spacer()

      VStack {
        Button(action: {
          viewModel.didChooseAction(false)
        }) {
          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.Theme.Text.black)
            .frame(width: 24, height: 24)
        }
        
        Spacer()
      }
      
    }
  }
  
  // MARK: - Network Card
  private var networkCard: some View {
    HStack(spacing: 8) {
      // Flow badge
      Image("flow")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 20, height: 20)

      Text("Connecting on Flow \(viewModel.provider.network.name)")
        .font(.inter(size: 14))
        .foregroundColor(.Theme.Text.black)

      Spacer()
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .background(Color.Brain.Light.lines5)
    .cornerRadius(16)
  }
  // MARK: - Permissions Card
  private var permissionsTitleCard: some View {
    VStack(spacing: 8) {
      // Website requesting access
      HStack(spacing: 8) {
        Image(systemName: "globe")
          .font(.system(size: 16))
          .foregroundColor(.Brain.Core.icons)
          .frame(width: 16, height: 16)

        Text("\(extractDomain(from: viewModel.provider.url)) is requesting access to:")
          .font(.inter(size: 14))
          .foregroundColor(.Brain.Text.primary)
          .lineLimit(1)
          .frame(height: 20)

        Spacer()
      }
      .padding(16)
      .frame(maxWidth: .infinity)
      .background(Color.Brain.Light.lines5)
      .cornerRadius(16)

      // Permissions list
    }
  }
  
  private var permissionsListCard: some View {
    VStack(spacing: 8) {
      permissionRow(
        text: "View your wallet balance and activity",
        isFirst: true
      )

      permissionRow(
        text: "Request approval for transactions",
        isFirst: false
      )
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .background(Color.Brain.Light.lines5)
    .cornerRadius(16)
  }

  private func permissionRow(text: String, isFirst: Bool) -> some View {
    HStack(spacing: 8) {
      Image("evm_check_1")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 16, height: 16)

      Text(text)
        .font(.inter(size: 15, weight: .medium))
        .foregroundColor(.Brain.Text.primary)
        .lineLimit(1)
        .frame(height: 20)
      Spacer()
    }
    
  }

  // MARK: - Account Section

  private var accountSection: some View {
    VStack(spacing: 6) {
      // Section title
      HStack {
        Text("Connecting Account")
          .font(.inter(size: 14))
          .foregroundColor(.Brain.Text.primary)
        Spacer()
      }
      .frame(height: 34)
      // Account card
      accountCard
    }
  }

  private var accountCard: some View {
    // TODO: Replace with actual account data from ViewModel
    let mockAccount = RNBridge.WalletAccount(
      id: "1",
      name: "Panda",
      address: viewModel.provider.address,
      emojiInfo: RNBridge.EmojiInfo(
        emoji: "🐼",
        name: "Panda",
        color: "#D6D6D6"
      ),
      parentEmoji: nil,
      parentAddress: nil,
      avatar: nil,
      isActive: true,
      type: .main,
      balance: "550.66",
      nfts: nil
    )

    let mockChildAccounts = [
      RNBridge.WalletAccount(
        id: "2",
        name: "Penguin",
        address: "0x123456",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🐧",
          name: "Penguin",
          color: "#FFCB6C"
        ),
        parentEmoji: nil,
        parentAddress: nil,
        avatar: nil,
        isActive: false,
        type: .child,
        balance: nil,
        nfts: nil
      ),
      RNBridge.WalletAccount(
        id: "3",
        name: "Fox",
        address: "0x789abc",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🦊",
          name: "Fox",
          color: "#FFB6C1"
        ),
        parentEmoji: nil,
        parentAddress: nil,
        avatar: nil,
        isActive: false,
        type: .child,
        balance: nil,
        nfts: nil
      ),
    ]

    return AuthnAccountView(
      account: mockAccount,
      childAccounts: mockChildAccounts,
      onTap: {
        // TODO: Handle account selection
        print("Account tapped")
      }
    )
  }

  // MARK: - Action Buttons

  private var actionButtons: some View {
    HStack(spacing: 17) {
      cancelButton
      connectButton
    }
  }
  
  private var cancelButton: some View {
    Button(action: {
      viewModel.didChooseAction(false)
    }) {
      Text("Cancel")
        .font(.inter(size: 16, weight: .bold))
        .foregroundColor(.Theme.Text.black)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.Brain.Light.lines25)
        )
    }
  }
  
  private var connectButton: some View {
    Button(action: {
      viewModel.didChooseAction(true)
    }) {
      Text("Connect")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.Theme.Text.white9)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.Brain.Light.lines)
        )
    }
  }
}

struct AuthnAccountView: View {
  let account: RNBridge.WalletAccount
  let childAccounts: [RNBridge.WalletAccount]
  var onTap: (() -> Void)?

  init(
    account: RNBridge.WalletAccount,
    childAccounts: [RNBridge.WalletAccount] = [],
    onTap: (() -> Void)? = nil
  ) {
    self.account = account
    self.childAccounts = childAccounts
    self.onTap = onTap
  }

  var body: some View {
    Button(action: {
      onTap?()
    }) {
      accountCardContent
    }
    .buttonStyle(PlainButtonStyle())
  }
  
  private var accountCardContent: some View {
    let content = HStack(spacing: 12) {
      // Account avatar
      WalletAvatarView(
        emoji: .init(name: account.emojiInfo?.emoji),
        avatar: account.avatar
      )

      // Account info
      accountInfo

      Spacer()

      // Chevron
      chevronIcon
    }
    
    return content
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .frame(maxWidth: .infinity)
      .background(Color.Brain.Light.lines5)
      .cornerRadius(16)
  }
  
  private var chevronIcon: some View {
    Image(systemName: "chevron.right")
      .font(.system(size: 14, weight: .medium))
      .foregroundColor(.Brain.Core.icons)
  }
  
  private var accountInfo: some View {
    VStack(alignment: .leading, spacing: 2) {
      // Name and address
      nameAndAddressRow

      // Balance
      if let balance = account.balance {
        Text("\(balance) FLOW")
          .font(.inter(size: 12))
          .foregroundColor(.Brain.Text.secondary)
          .lineLimit(1)
      }

      // Child accounts indicators
      if !childAccounts.isEmpty {
        childAccountsRow
      }
    }
  }
  
  private var nameAndAddressRow: some View {
    HStack(spacing: 8) {
      Text(account.name)
        .font(.inter(size: 14, weight: .semibold))
        .foregroundColor(.Brain.Text.primary)

      Text("(\(account.address))")
        .font(.inter(size: 12))
        .foregroundColor(.Brain.Text.secondary)
    }
  }
  
  private var childAccountsRow: some View {
    HStack(spacing: 4) {
      // Parent indicator (if has children)
      Image("account_link_mark")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 12, height: 12)
        .padding(2)

      // Child account avatars
      childAccountAvatars
    }
  }
  
  private var childAccountAvatars: some View {
    HStack(spacing: 4) {
      ForEach(childAccounts, id: \.id) { child in
        WalletAvatarView(
          emoji: .init(name: child.emojiInfo?.name),
          avatar: child.avatar,
          size: .small
        )
      }
    }
  }
}

// MARK: - Helper Methods

extension AuthnView {
  private func extractDomain(from urlString: String) -> String {
    guard let url = URL(string: urlString),
      let host = url.host
    else {
      return urlString
    }
    return host
  }
}

// MARK: - Helper Extensions

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners

  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

// MARK: - Test Data

private struct TestAuthnData: AuthnDataProvider {
  var title: String
  var url: String
  var address: String
  var logo: String?

  init() {
    title = "NBA Top Shot"
    url = "https://port.topshot.com"
    logo = "https://nbatopshot.com/static/favicon/apple-touch-icon.png"
    address = "0x8888888888888ab"
  }
}

#Preview("AuthnView - Full Screen") {
  ZStack {
    Color.black.ignoresSafeArea()

    AuthnView(
      viewModel: .init(
        provider: TestAuthnData(),
        callback: { result in
          print("User selected: \(result ? "Connect" : "Cancel")")
        }
      )
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
  }
}

#Preview("AuthnAccountView - Account Card") {
  VStack(spacing: 20) {
    // Main account with child accounts
    AuthnAccountView(
      account: RNBridge.WalletAccount(
        id: "1",
        name: "Panda",
        address: "0x8888888888888ab",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🐼",
          name: "Panda",
          color: "#D6D6D6"
        ),
        parentEmoji: nil,
        parentAddress: nil,
        avatar: nil,
        isActive: true,
        type: .main,
        balance: "550.66",
        nfts: nil
      ),
      childAccounts: [
        RNBridge.WalletAccount(
          id: "2",
          name: "Penguin",
          address: "0x123456",
          emojiInfo: RNBridge.EmojiInfo(
            emoji: "🐧",
            name: "Penguin",
            color: "#FFCB6C"
          ),
          parentEmoji: nil,
          parentAddress: nil,
          avatar: nil,
          isActive: false,
          type: .child,
          balance: nil,
          nfts: nil
        ),
        RNBridge.WalletAccount(
          id: "3",
          name: "Fox",
          address: "0x789abc",
          emojiInfo: RNBridge.EmojiInfo(
            emoji: "🦊",
            name: "Fox",
            color: "#FFB6C1"
          ),
          parentEmoji: nil,
          parentAddress: nil,
          avatar: nil,
          isActive: false,
          type: .child,
          balance: nil,
          nfts: nil
        ),
      ],
      onTap: {
        print("Account tapped")
      }
    )

    // Account without balance or children
    AuthnAccountView(
      account: RNBridge.WalletAccount(
        id: "4",
        name: "Lion",
        address: "0xabcdef123456",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🦁",
          name: "Lion",
          color: "#FFD700"
        ),
        parentEmoji: nil,
        parentAddress: nil,
        avatar: nil,
        isActive: false,
        type: .child,
        balance: nil,
        nfts: nil
      )
    )

    // EVM account
    AuthnAccountView(
      account: RNBridge.WalletAccount(
        id: "5",
        name: "EVM Account",
        address: "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "⚡",
          name: "EVM",
          color: "#627EEA"
        ),
        parentEmoji: nil,
        parentAddress: nil,
        avatar: nil,
        isActive: false,
        type: .evm,
        balance: "1.23",
        nfts: nil
      )
    )
  }
  .padding()
  .background(Color.Brain.Core.background)
}
