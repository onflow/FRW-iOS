//
//  PrivateKeyWarning.swift
//  FRW
//
//  Created by cat on 3/7/25.
//

import SwiftUI

struct PrivateKeyWarning: View {
    var body: some View {
        HStack(alignment: .top) {
            Image("icon-warning")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.Brain.System.red)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("not_share_secret_tips".localized)
                  .font(.inter(size: 14, weight: .bold))
                Text("not_share_secret_desc".localized)
                  .font(.inter(size: 14))
                  .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundColor(.Brain.System.red)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(Color.Brain.System.red.opacity(0.15))
        }
    }
}

#Preview {
    PrivateKeyWarning()
}
