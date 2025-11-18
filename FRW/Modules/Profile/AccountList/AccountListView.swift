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
          LazyVStack {
            ForEach(0..<viewModel.allAccounts.count, id:\.self) { index in
              let list = viewModel.allAccounts[index]
              let type = viewModel.hideType(with: list)
              AccountInfoCard(list: list, hideType: type)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
          }
          Spacer()
        }
      }
      .applyRouteable(self)
    }
}

struct AccountInfoCard: View {
  let list:[RNBridge.WalletAccount]
  var hideType: AccountHideType = .none
  
  var body: some View {
    VStack {
      ForEach(0..<list.count, id:\.self) { index in
        let account = list[index]
        AccountInfoView(account: account, hideType: hideType)
      }
    }
    .padding(18)
    .background(Color.Brain.Core.cards)
    .cornerRadius(16)
  }
}

struct AccountInfoView: View {
  let account: RNBridge.WalletAccount
  var hideType: AccountHideType = .none
  
  var body: some View {
    Button {
      onClick()
    } label: {
      HStack(spacing: 8) {
        if account.type != .main && (account.parentAddress != nil) {
          Image("account_link_mark")
            .resizable()
            .frame(width: 20, height: 20)
        }
        WalletAvatarView(
          emoji: .init(name: account.emojiInfo?.emoji),
          avatar: account.avatar,
          showBorder: account.isActive
        )
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
              Text(account.name)
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black8)
                    .frame(height: 22)
              if !account.isActive {
                hideView
              }
              if account.type == .eoa {
                EVMTagView()
              }
              if account.type == .evm {
                COATagView()
              }
            }

          Text(account.address)
                .font(.inter(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(Color.Theme.Text.black3)
                .frame(height: 20)

          if let balance = account.balance {
              Text(balance)
                  .font(.inter(size: 12))
                  .lineLimit(1)
                  .truncationMode(.middle)
                  .foregroundStyle(Color.Theme.Text.black8)
          }
        }
        Spacer()
        
        Image("icon_arrow_right_28")
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(Color.Theme.Text.black3)
            .frame(width: 24, height: 24)
      }
      .frame(height: 56)
    }
    .buttonStyle(ScaleButtonStyle())
    
  }
  
  var hideView: some View {
    HStack {
      if hideType == .visible {
        Image("icon_eye_13")
          .resizable()
          .frame(width: 13, height: 13)
      }
      if hideType == .hidden {
        Text("(\("hidden".localized)")
          .font(.inter(size:14))
          .foregroundStyle(Color.Brain.Text.secondary)
      }
    }
  }
  
  func onClick() {

    switch account.type {
    case .main:
      Router.route(to: RouteMap.Profile.walletSetting(true, account.address))
    case .child:
      Router.route(to: RouteMap.Profile.walletSetting(true, account.address))
    case .evm:
      Router.route(to: RouteMap.Profile.walletSetting(true, account.address))
    case .eoa:
      Router.route(to: RouteMap.Profile.walletSetting(true, account.address))
    case .none:
      break
    }
  }
}


#Preview {
    AccountListView()
}
