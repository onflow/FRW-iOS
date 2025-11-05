//
//  AuthnAccountsView.swift
//  FRW
//
//  Created by cat on 11/5/25.
//

import SwiftUI

struct AuthnAccountsView: View {
  let selectedAccount: RNBridge.WalletAccount
  let compatibleAccounts: [RNBridge.WalletAccount]
  let childAccounts: [RNBridge.WalletAccount]
  var onBack: (() -> Void)?
  var onSelectAccount: ((RNBridge.WalletAccount) -> Void)?

  init(
    selectedAccount: RNBridge.WalletAccount,
    compatibleAccounts: [RNBridge.WalletAccount] = [],
    childAccounts: [RNBridge.WalletAccount] = [],
    onBack: (() -> Void)? = nil,
    onSelectAccount: ((RNBridge.WalletAccount) -> Void)? = nil
  ) {
    self.selectedAccount = selectedAccount
    self.compatibleAccounts = compatibleAccounts
    self.childAccounts = childAccounts
    self.onBack = onBack
    self.onSelectAccount = onSelectAccount
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      // Header
      header

      // Content
      VStack(alignment: .leading, spacing: 15) {
        // Selected account label
        Text("Selected account")
          .font(.inter(size: 14))
          .foregroundColor(Color.Theme.Text.black8)

        // Selected account row with darker background
        AccountRow(
          account: selectedAccount,
          childAccounts: childAccounts
        )
        .background(Color.Brain.Light.lines5)
        .cornerRadius(16)

        // Divider
        divider

        // Compatible accounts
        if !compatibleAccounts.isEmpty {
          compatibleAccountsList
        }
      }

      Spacer()
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.Brain.Core.background)
    .cornerRadius(16, corners: [.topLeft, .topRight])
  }

  private var header: some View {
    ZStack {
      HStack {
        Button(action: {
          onBack?()
        }) {
          Image("icon-back-arrow-grey")
            .resizable()
            .renderingMode(.template)
            .foregroundColor(Color.Brain.Text.primary)
            .frame(width: 16, height: 16)
        }
        Spacer()
      }

      // Centered title
      Text("Select Account")
        .font(.inter(size: 18, weight: .bold))
        .foregroundColor(Color.Brain.Text.primary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
    .frame(height: 32)
  }

  private var divider: some View {
    Rectangle()
      .fill(Color.Theme.Line.line)
      .frame(height: 1)
  }

  private var compatibleAccountsList: some View {
    VStack(spacing: 15) {
      ForEach(compatibleAccounts, id: \.id) { account in
        AccountRow(
          account: account,
          onTap: {
            onSelectAccount?(account)
          }
        )
      }
    }
  }
}

#Preview {
  AuthnAccountsView(
    selectedAccount: RNBridge.WalletAccount(
      id: "1",
      name: "Panda",
      address: "0x8888...888ab",
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
    compatibleAccounts: [
      RNBridge.WalletAccount(
        id: "2",
        name: "Fox",
        address: "0x0c666c888d8fb259",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🦊",
          name: "Fox",
          color: "#FFD787"
        ),
        parentEmoji: nil,
        parentAddress: nil,
        avatar: nil,
        isActive: false,
        type: .main,
        balance: "550.66",
        nfts: nil
      )
    ],
    childAccounts: [
      RNBridge.WalletAccount(
        id: "3",
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
        id: "4",
        name: "Cat",
        address: "0x789abc",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🐱",
          name: "Cat",
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
      RNBridge.WalletAccount(
        id: "5",
        name: "Dog",
        address: "0xdef456",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🐶",
          name: "Dog",
          color: "#87CEEB"
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
        id: "6",
        name: "Bear",
        address: "0xabc789",
        emojiInfo: RNBridge.EmojiInfo(
          emoji: "🐻",
          name: "Bear",
          color: "#CD853F"
        ),
        parentEmoji: nil,
        parentAddress: nil,
        avatar: nil,
        isActive: false,
        type: .child,
        balance: nil,
        nfts: nil
      )
    ],
    onBack: {
      print("Back tapped")
    },
    onSelectAccount: { account in
      print("Selected account: \(account.name)")
    }
  )
  .background(Color.black)
}
