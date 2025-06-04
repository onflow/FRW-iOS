//
//  EVMTagView.swift
//  FRW
//
//  Created by cat on 2024/5/20.
//

import SwiftUI

// MARK: - TagView

struct TagView: View {
    var size: CGFloat = 8
    var type: Contact.WalletType = .flow

    var body: some View {
        HStack {
            if type != .flow {
                Text(title)
                    .font(.inter(size: size))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(BGColor)
                    .clipShape(Capsule())
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
