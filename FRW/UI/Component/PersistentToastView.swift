//
//  PersistentToastView.swift
//  FRW
//
//  Created by Antonio Bello on 11/11/24.
//

import SwiftUI

// Note: this seems to be a clone of `CalloutView`, but in the opposite vertical direction.
struct PersistentToastView: View {
    let message: String
    let imageRes: ImageResource

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(self.imageRes)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(.init(self.message))
                    .foregroundColor(Color(.orange1))
                    .font(.inter(size: 12, weight: .w400))
                    .fixedSize(horizontal: true, vertical: true)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.orange5))
        }
        .background(Color.LL.Neutrals.background.opacity(0.95))
        .cornerRadius(8)
        .padding(.horizontal, 8)
    }
}

//#Preview {
//    PersistentToastView(
//        message: "Insufficient Funds.",
//        imageRes: .Storage.insufficient
//    )
//}
