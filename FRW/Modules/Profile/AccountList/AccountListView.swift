//
//  AccountListView.swift
//  FRW
//
//  Created by cat on 11/13/25.
//

import SwiftUI

struct AccountListView: RouteableView {
      
    @StateObject var viewModel = AccountListViewModel()
  
    var title: String {
        "wallet_list".localized
    }
  
    var body: some View {
      VStack(spacing: 0) {
        ScrollView(showsIndicators: false){
          LazyVStack(spacing: 10) {
            ForEach(0..<viewModel.allAccounts.count, id:\.self) { index in
              let list = viewModel.allAccounts[index]
              let type = viewModel.hideType(with: list)
              AccountInfoCard(list: list, hideType: type) { address in
                viewModel.showAddress(at: address)
              }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
          }
          Spacer()
        }
      }
      .applyRouteable(self)
    }
}

struct AccountInfoCard: View {
  let list:[WalletAccount]
  var hideType: AccountHideType = .none
  var onClickHidden: ((String)->())? = nil

  var body: some View {
    VStack {
      ForEach(0..<list.count, id:\.self) { index in
        let account = list[index]
        AccountInfoView(account: account,parent: parent() ,hideType: hideType, onClickHidden: onClickHidden)
      }
    }
    .padding(18)
    .background(Color.Brain.Core.cards)
    .cornerRadius(16)
  }

  func parent() -> WalletAccount? {
    list.first { $0.type == .main }
  }
}

struct AccountInfoView: View {
  let account: WalletAccount
  let parent: WalletAccount?
  var hideType: AccountHideType = .none
  var onClickHidden: ((String)->())? = nil

  var allowShowEye: Bool {
    !isActivity && (account.type == .main || account.type == .eoa)
  }

  var body: some View {
    Button {
      onClick()
    } label: {
      HStack(spacing: 12) {
        HStack(spacing: 0) {
          if account.type != .main && (account.parent?.address != nil) {
            Image("account_link_mark")
              .resizable()
              .frame(width: 20, height: 20)
              .padding(.leading, 18)
              .padding(.trailing, 10)
          }
          WalletAvatarView(
            emoji: account.displayInfo.emoji,
            avatar: account.displayInfo.avatar,
            showBorder: isActivity
          )
        }
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
              Text(account.displayInfo.name)
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black8)
                    .frame(height: 22)
              if allowShowEye {
                hideView
              }
              if account.type == .eoa {
                EVMTagView()
              }
              if account.type == .coa {
                COATagView()
              }
            }

          Text(account.address)
                .font(.inter(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(Color.Theme.Text.black3)
                .frame(height: 20)

          Text(account.displayBalance)
              .font(.inter(size: 12))
              .lineLimit(1)
              .truncationMode(.middle)
              .foregroundStyle(Color.Theme.Text.black8)
        }
        Spacer()
        if allowShowEye && hideType == .hidden {
          Button {
            onShowAction()
          } label: {
            Image("icon_eye_close")
              .resizable()
              .renderingMode(.template)
              .foregroundStyle(Color.Theme.Text.black3)
              .frame(width: 24, height: 24)
          }
        }
        Image("icon_arrow_right_28")
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Color.Theme.Text.black3)
            .frame(width: 24, height: 24)
      }
      .frame(height: 56)
      .contentShape(Rectangle())
    }
    .buttonStyle(ScaleButtonStyle())
    
  }
  
  var hideView: some View {
    HStack {
      if hideType == .visible {
        Image("icon_eye_13")
          .resizable()
          .renderingMode(.template)
          .foregroundStyle(Color.Brain.Core.icons)
          .frame(width: 13, height: 13)
      }
      if hideType == .hidden {
        Text("(\("hidden".localized))")
          .font(.inter(size:14))
          .foregroundStyle(Color.Brain.Text.secondary)
      }
    }
  }

  var isActivity: Bool {
    WalletManager.shared.selectedAccount?.hexAddr == account.address
  }

  func onShowAction() {
    onClickHidden?(account.address)
  }

  func onClick() {
    guard let profile = ProfileManager.shared.currentProfile else {
      return
    }
    Router.route(to: RouteMap.Profile.account(account, parent, profile))
  }
}


#Preview {
    AccountListView()
}
