//
//  EVMTagView.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import SwiftUI

// MARK: - TagView

struct TagView: View {
    var type: Contact.WalletType = .flow

    var body: some View {
        HStack {
            if type != .flow {
                Text(title)
                    .font(.inter(size: 8))
                    .foregroundStyle(Color.white)
                    .frame(height: 10)
                    .padding(.horizontal, 4)
                    .background(BGColor)
                    .cornerRadius(16)
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
    TagView(type: .evm)
}
