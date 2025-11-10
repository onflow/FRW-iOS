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
            .font(.inter(size: 9))
            .kerning(0.144)
            .foregroundStyle(Color.white)
            .frame(width: 36, height: 16)
            .background(Color.Theme.evm)
            .cornerRadius(8)
    }
}

struct EOATagView: View {
  var body: some View {
    Text("EOA")
        .font(.inter(size: 9))
        .kerning(0.144)
        .foregroundStyle(Color.white)
        .frame(width: 36, height: 16)
        .background(Color.Theme.Accent.orange)
        .cornerRadius(8)
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
    TagView()
}
