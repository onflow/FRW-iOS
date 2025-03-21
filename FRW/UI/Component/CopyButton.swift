//
//  CopyButton.swift
//  FRW
//
//  Created by cat on 3/7/25.
//

import SwiftUI

struct CopyButton: View {
    var title: String = "Copy".localized
    var iconName: String = "copy_key_button"
    var onClick: () -> Void

    var body: some View {
        Button {
            onClick()
        } label: {
            HStack {
                Image(iconName)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundStyle(Color.Theme.Accent.grey)
            }
        }
    }
}

#Preview {
    CopyButton {}
}
