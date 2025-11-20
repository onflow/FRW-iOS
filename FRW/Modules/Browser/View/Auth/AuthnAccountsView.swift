//
//  AuthnAccountsView.swift
//  FRW
//
//  Created by cat on 11/5/25.
//

import SwiftUI

struct AuthnAccountsView: View {
  @State private var viewModel: AuthnAccountsViewModel

  init(viewModel: AuthnAccountsViewModel) {
    self._viewModel = State(initialValue: viewModel)
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
          provider: viewModel.selectedAccount,
          onTap: {
            viewModel.navigateBack()
          }
        )
        .background(Color.Brain.Light.lines5)
        .cornerRadius(16)

        // Divider
        divider

        // Compatible accounts
        if !viewModel.compatibleAccounts.isEmpty {
          compatibleAccountsList
        }
      }

      Spacer()
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.Brain.Core.cards)
  }

  private var header: some View {
    ZStack {
      HStack {
        Button(action: {
          viewModel.navigateBack()
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
      ForEach(viewModel.compatibleAccounts, id: \.account.address) { account in
        AccountRow(
          provider: account,
          onTap: {
            viewModel.selectAccount(account)
          }
        )
      }
    }
  }
}

#Preview {
  // Create mock ViewModel
  let viewModel = AuthnAccountsViewModel.mock()
  viewModel.onAccountSelected = { account in
  }

  return AuthnAccountsView(viewModel: viewModel)
          .background(Color.black)
}
