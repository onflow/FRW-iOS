//
//  AuthnAccountView.swift
//  FRW
//
//  Created by cat on 11/1/25.
//

import SwiftUI

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
      WalletAvatarView(
        emoji: .init(name: account.emojiInfo?.emoji),
        avatar: account.avatar,
        showBorder: account.isActive
      )
      accountInfo
      Spacer()
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
      if account.type == .main {
        HStack {
          nameView
          addressView
        }
      } else {
        nameView
        addressView
      }
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
  
  private var nameView: some View {
    Text(account.name)
      .font(.inter(size: 14, weight: .semibold))
      .lineLimit(1)
      .foregroundColor(.Brain.Text.primary)
  }
  
  private var addressView: some View {
    Text(showAddress)
      .font(.inter(size: 12))
      .lineLimit(1)
      .foregroundColor(.Brain.Text.secondary)
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
  
  var showAddress: String {
    if account.type == .main {
      return "(\(account.address))"
    } else {
      return account.address
    }
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
