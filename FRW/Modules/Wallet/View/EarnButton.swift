//
//  EarnButton.swift
//  FRW
//
//  Created by cat on 28/1/26.
//

import SwiftUI

struct EarnButton: View {
    var body: some View {
      Button {
        if let url  = URL(string: AppUrl.earnUrl) {
          Router.route(to: RouteMap.Explore.browser(url))
        } else {
          HUD.error(title: "don't have earn url")
        }
      } label: {
        HStack(spacing: 10) {
          Text("earn".localized)
            .font(.inter(size: 16, weight: .medium))
            .foregroundStyle(Color.Brain.Core.icons)
          Image("earn_icon")
            .resizable()
            .frame(width: 20, height: 20)
        }
        .frame(height: 40)
        .padding(.horizontal, 12)
        .background(Color.Brain.Light.lines10)
        .cornerRadius(20)
      }
    }
}

#Preview {
    EarnButton()
}
