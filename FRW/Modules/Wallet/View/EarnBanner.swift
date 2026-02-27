//
//  EarnBanner.swift
//  FRW
//
//  Created by cat on 28/1/26.
//

import SwiftUI

struct EarnBanner: View {
    var body: some View {
      Button{
        if let url  = URL(string: AppUrl.earnUrl) {
          Router.route(to: RouteMap.Explore.browser(url))
        } else {
          HUD.error(title: "don't have earn url")
        }
      } label: {
        HStack(alignment: .center, spacing: 0) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Don’t miss out on $1,203 this year")
              .font(.inter(size: 14))
              .lineLimit(1)
              .foregroundStyle(Color.white)
            
            Text("Earn 15% APY on Flow Vaults")
              .font(.inter(size: 16, weight: .semibold))
              .lineLimit(1)
              .foregroundStyle(Color.Brain.Primary.main)
          }
          Spacer()
          Image("earn_icon_36")
            .resizable()
            .frame(width: 20, height: 20)
            .padding(8)
            .background(Color.Brain.Primary.main)
            .clipShape(Circle())
        }
        .padding(18)
        .frame(width: .infinity, alignment: .leading)
        .background(
          LinearGradient(
            stops: [
              Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 0.00),
              Gradient.Stop(color: Color(red: 0, green: 0.94, blue: 0.55), location: 1.00),
            ],
            startPoint: UnitPoint(x: 0.75, y: 1),
            endPoint: UnitPoint(x: 0.75, y: -5)
          )
        )
        .cornerRadius(16)
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .inset(by: 0.25)
            .stroke(Color(red: 0.09, green: 1, blue: 0.6), lineWidth: 0.5)
        )
      }
    }
}

#Preview {
    EarnBanner()
}
