//
//  NetworkMenuItem.swift
//  FRW
//
//  Created by cat on 2024/5/27.
//

import SwiftUI
import Flow

struct NetworkMenuItem: View {
    var network: Flow.ChainID
    var currentNetwork: Flow.ChainID

    var isSelected: Bool {
        network == currentNetwork
    }

    var body: some View {
        HStack {
            Text(network.rawValue.uppercasedFirstLetter())
                .font(.inter(size: 14, weight: .semibold))
                .foregroundStyle(network.color)
            Spacer()
            if isSelected {
                Image("evm_check_1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            } else {
                Image("check_fill_0")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.Theme.Text.black8)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            network.color.opacity(0.08)
                .visibility(isSelected ? .visible : .gone)
        )
        .cornerRadius(12)
    }
}

#Preview {
    NetworkMenuItem(network: .mainnet, currentNetwork: .testnet)
}
