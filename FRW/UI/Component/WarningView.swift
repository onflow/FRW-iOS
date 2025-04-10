//
//  WarningView.swift
//  FRW
//
//  Created by cat on 4/10/25.
//

import SwiftUI

extension WarningView {
    enum Content {
        case blocklist

        var title: String {
            switch self {
            case .blocklist:
                "dapp_block_flag".localized
            }
        }
    }
}

struct WarningView: View {
    let content: WarningView.Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image("callout_icon_warning")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.Theme.Accent.red)
                .frame(width: 20, height: 20)

            Text(content.title)
                .font(.inter(size: 14, weight: .semibold))
                .foregroundStyle(Color.Theme.Accent.red)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.Theme.Accent.red.fixedOpacity())
        .cornerRadius(12)
        .frame(height: 16)
    }
}

#Preview {
    WarningView(content: .blocklist)
}
