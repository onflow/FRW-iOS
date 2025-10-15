//
//  DeleteSEKeychain.swift
//  FRW
//
//  Created by cat on 10/9/25.
//

import SwiftUI
import FlowWalletKit

struct DeleteSEKeychain: RouteableView {
  var title: String = "Delete SE"

  let isShow: Bool = true

  var body: some View {
    VStack {
      if isShow {
        content
      } else {
        Text("hahaha")
      }
    }
    .padding(18)
    .applyRouteable(self)
  }

  var content: some View {
    ScrollView {
      VStack(spacing: 10) {
        Button {
          deleteAllSEKeychain()
        } label: {
          HStack {
            Text("Delete All Secrect")
            Spacer()
          }
          .padding(16)
          .background(Color.Theme.Background.fill1)
        }
      }
      .cornerRadius(16)
    }
    .font(.inter())
    .foregroundStyle(Color.Theme.Text.black8)
    .background(
      Color.LL.Neutrals.background.ignoresSafeArea()
    )
  }
  
  private func deleteAllSEKeychain() {
    let keychain = SecureEnclaveKey.KeychainStorage
    let keys = keychain.allKeys
    do {
      try keychain.removeAll()
      HUD.success(title: "done")
    } catch {
      HUD.error(title: "Failed", message: error.localizedDescription)
    }
  }
}

#Preview {
  DeleteSEKeychain()
}
