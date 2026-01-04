//
//  AccountShowView.swift
//  FRW
//
//  Created by cat on 11/19/25.
//

import SwiftUI

struct AccountShowView: View {
    var address: String
    var uid: String
    @State var isShow: Bool

    init(address: String, uid: String) {
      self.address = address
      self.uid = uid
      self.isShow = !LocalUserDefaults.shared.isAddressHidden(address, for: uid)
    }

    var body: some View {
      AccountOptionView(title: "show_account_title".localized, style: .toggle, isOn: isShow) { toggle in
        showStatusDidChange(toggle: toggle)
      }
    }

    private func showStatusDidChange(toggle: Bool) {
      isShow = toggle
      LocalUserDefaults.shared.toggleHiddenAddress(address, for: uid)
    }
}

#Preview {
//    AccountShowView()
}
