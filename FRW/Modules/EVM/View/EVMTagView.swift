//
//  EVMTagView.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import SwiftUI

// MARK: - EVMTagView

struct EVMTagView: View {
    
    var body: some View {
        Text("EVM")
            .font(.inter(size: 8,weight: .w500))
            .foregroundStyle(Color.white)
            .frame(width: 26, height: 10)
            .background(Color.Theme.evm)
            .cornerRadius(5)
    }
}

struct COATagView: View {
  var body: some View {
    HStack(spacing: 2) {
      Text("EVM")
          .font(.inter(size: 8, weight: .w500))
          .foregroundStyle(Color.white)
          .padding(.leading, 4)

      Text("FLOW")
          .font(.inter(size: 8, weight: .w500))
          .foregroundStyle(Color.black)
          .frame(width: 32, height: 10)
          .background(Color.Theme.Accent.green)
          .cornerRadius(5)
    }
    .background(Color.Theme.evm)
    .cornerRadius(5)
  }
}

// MARK: - TagView

struct TagView: View {
    var type: Contact.WalletType = .flow

    var body: some View {
        HStack {
            if type != .flow {
                Text(title)
                    .font(.inter(size: 9))
                    .kerning(0.144)
                    .foregroundStyle(Color.white)
                    .frame(height: 16)
                    .padding(.horizontal, 8)
                    .background(BGColor)
                    .cornerRadius(8)
            }
        }
    }

    var title: String {
        switch type {
        case .flow:
            return ""
        case .evm:
            return "EVM"
        case .link:
            return "Linked"
        }
    }

    var BGColor: Color {
        switch type {
        case .flow:
            .clear
        case .evm:
            .Theme.evm
        case .link:
            .Theme.Accent.blue
        }
    }
}

#Preview {
  VStack(spacing: 10) {
    EVMTagView()
    COATagView()
  }
  
}
