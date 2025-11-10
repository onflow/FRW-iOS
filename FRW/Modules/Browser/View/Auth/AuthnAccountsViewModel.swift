//
//  AuthnAccountsViewModel.swift
//  FRW
//
//  Created by cat on 11/5/25.
//

import Foundation
import SwiftUI


final class AuthnAccountsViewModel: ObservableObject {
  // MARK: - Properties

  private(set) var selectedAccount: AuthnAccountProvider
  private(set) var compatibleAccounts: [AuthnAccountProvider]
  var onAccountSelected: ((AuthnAccountProvider) -> Void)?

  // MARK: - Initialization
  init(
    selectedAccount: AuthnAccountProvider,
    compatibleAccounts: [AuthnAccountProvider] = [],
    onAccountSelected: ((AuthnAccountProvider) -> Void)? = nil
  ) {
    self.selectedAccount = selectedAccount
    self.compatibleAccounts = compatibleAccounts
    self.onAccountSelected = onAccountSelected
    loadCompatibleAccounts()
  }

  // MARK: - Public Methods

  /// Select a new account from the compatible accounts list
  func selectAccount(_ account: AuthnAccountProvider) {
    // Update the selected account
    self.selectedAccount = account

    // Notify the callback
    onAccountSelected?(account)
    navigateBack()
    // Log the selection for debugging
    debugPrint("Account selected: \(account.account.name) - \(account.account.address)")
  }

  /// Handle back navigation
  func navigateBack() {
    Router.dismiss()
  }

  /// Filter out the selected account from compatible list if needed
  func loadCompatibleAccounts() {
    self.compatibleAccounts = compatibleAccounts.filter {
      $0.account.address != selectedAccount.account.address
    }
  }
}

// MARK: - Mock Data Extension

extension AuthnAccountsViewModel {
  /// Create a mock view model for previews and testing
  static func mock() -> AuthnAccountsViewModel {
    let selectedAccount = AuthnAccountProvider(
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
      linkAccounts: []
    )

    let compatibleAccounts = [
      AuthnAccountProvider(
        account: RNBridge.WalletAccount(
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
        ),
        linkAccounts: [
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
          )
        ]
      )
    ]

    return AuthnAccountsViewModel(
      selectedAccount: selectedAccount,
      compatibleAccounts: compatibleAccounts
    )
  }
}
