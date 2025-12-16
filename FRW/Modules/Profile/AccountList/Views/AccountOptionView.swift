//
//  AccountOptionView.swift
//  FRW
//
//  Created by cat on 11/18/25.
//

import SwiftUI

struct AccountOptionView: View {
  let title: String
  let style: AccountOptionView.Style
  @State var isOn: Bool = false
  var toggleAction: ((Bool) -> Void)? = nil

  var body: some View {
      HStack(spacing: 0) {
          Text(title)
            .font(.inter(size: 16, weight: .w600))
            .lineLimit(1)
            .foregroundColor(Color.Brain.Text.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        if style == .toggle {
          Toggle(isOn: $isOn) {}
              .tint(.LL.Primary.salmonPrimary)
              .onChange(of: isOn) { value in
                  toggleAction?(value)
              }
        }
        if style == .arrow {
          Image("icon-black-right-arrow")
              .renderingMode(.template)
              .foregroundColor(Color.Brain.Core.icons)
        }
      }
      .frame(maxWidth: .infinity)
      .accountStyle()
  }
}

extension AccountOptionView {
  enum Style {
    case none
    case arrow
    case toggle
  }
}

#Preview {
  VStack {
    AccountOptionView(title: "Private", style: .none, isOn: true, toggleAction: nil)
    AccountOptionView(title: "Private", style: .arrow, isOn: true, toggleAction: nil)
    AccountOptionView(title: "Private", style: .toggle, isOn: true, toggleAction: nil)
  }

}
