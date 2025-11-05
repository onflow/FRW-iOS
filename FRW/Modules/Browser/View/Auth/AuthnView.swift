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
    ZStack {
      // Main content
      VStack(spacing: 0) {
        VStack(spacing: 16) {
          headerSection
          networkCard
          permissionsTitleCard
          permissionsListCard
          accountSection
          actionButtons
        }
      }
      .padding(.horizontal, 16)
      .background(Color.Brain.Core.background)
      
      accountSelectionOverlay
    }
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
    VStack {
      if let account = viewModel.currentAccount {
        AccountRow(
          account: account,
          childAccounts: viewModel.linkedAccount,
          showArrow: viewModel.compatibleAccounts.count > 0,
          onTap: viewModel.toggleAccountSelection
        )
      }
    }
  }

  // MARK: - Account Selection Overlay

  private var accountSelectionOverlay: some View {
    GeometryReader { geometry in
      ZStack {
        // Dimmed background with fade animation
        if viewModel.showAccountSelection {
          Color.black.opacity(0.5)
            .ignoresSafeArea()
            .onTapGesture {
              viewModel.toggleAccountSelection()
            }
            .transition(.opacity)
        }

        // Account selection view with push-style animation
        if let selectedAccount = viewModel.currentAccount, viewModel.showAccountSelection {
          AuthnAccountsView(
            selectedAccount: selectedAccount,
            compatibleAccounts: viewModel.compatibleAccounts,
            childAccounts: viewModel.linkedAccount,
            onBack: {
              viewModel.toggleAccountSelection()
            },
            onSelectAccount: { account in
              viewModel.selectAccount(account)
            }
          )
          .frame(width: geometry.size.width, height: geometry.size.height)
          .background(Color.Brain.Core.background)
          .transition(.move(edge: .trailing))
          .zIndex(1)
        }
      }
    }
    .ignoresSafeArea()
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

// MARK: - Test Data

extension AuthnDataProvider {
  static func mock() -> AuthnDataProvider {
    AuthnDataProvider(title: "NBA Top Shot", url: "https://port.topshot.com", address: "0x23947239847", logo: "https://nbatopshot.com/static/favicon/apple-touch-icon.png")
  }
}

#Preview("AuthnView - Full Screen") {
  ZStack {
    Color.black.ignoresSafeArea()

    AuthnView(
      viewModel: .init(
        provider: AuthnDataProvider.mock(),
        callback: { result in
          print("User selected: \(result ? "Connect" : "Cancel")")
        }
      )
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
  }
}


