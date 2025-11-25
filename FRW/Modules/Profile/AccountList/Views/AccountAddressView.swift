//
//  AccountAddressView.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import SwiftUI

struct AccountAddressView: View {
  
    var account: WalletAccount
    var body: some View {
      HStack {
        VStack(alignment: .leading,spacing: 8) {
          Text("address".localized)
            .font(.inter(size: 14, weight: .medium))
            .foregroundStyle(Color.Brain.Text.primary)
          Text(account.address)
            .font(.inter(size: 16))
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(Color.Brain.Text.secondary)
        }
        Spacer()
        CopyAddressView(account: account)
        
      }
      .accountStyle()
    }
}

#Preview {
  AccountAddressView(account: .mockMain())
}
