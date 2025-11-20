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
    debugPrint("Account selected: \(account.account.displayInfo.name) - \(account.account.address)")
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
      account: .mockMain(),
      linkAccounts: []
    )

    let compatibleAccounts = [
      AuthnAccountProvider(
        account: .mockMain(),
        linkAccounts: [
          .mockChild()
        ]
      )
    ]

    return AuthnAccountsViewModel(
      selectedAccount: selectedAccount,
      compatibleAccounts: compatibleAccounts
    )
  }
}
