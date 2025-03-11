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
            Image("Warning")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.LL.warning2)
                .width(16)

            VStack(alignment: .leading, spacing: 4) {
                Text("not_share_secret_tips".localized)
                    .font(.LL.caption)
                    .bold()
                Text("not_share_secret_desc".localized)
                    .font(.LL.footnote)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .foregroundColor(.LL.warning2)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundColor(.LL.warning6)
        }
    }
}

#Preview {
    PrivateKeyWarning()
}
