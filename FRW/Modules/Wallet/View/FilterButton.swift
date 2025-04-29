//
//  FilterButton.swift
//  FRW
//
//  Created by cat on 4/29/25.
//

import SwiftUI

struct FilterButton: View {
    var title: String
    var isSelected: Bool = false
    var icon: String? = nil
    var onClick: (String) -> Void

    var body: some View {
        Button(action: { onClick(title) }) {
            HStack(spacing: 4) {
                if let name = icon {
                    Image(name)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                Text(title)
                    .font(.inter(size: 14))
                    .foregroundColor(.Theme.Text.black8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.Theme.Special.white1 : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.Theme.Accent.green : Color.Theme.Text.black3, lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    HStack {
        FilterButton(title: "Verified", isSelected: false, icon: "icon-token-valid") { _ in
        }
        FilterButton(title: "All Token", isSelected: true) { _ in
        }
    }
}
