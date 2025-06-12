//
//  AccountCreatingCell.swift
//  FRW
//
//  Created by cat on 6/11/25.
//

import SwiftUI

struct AccountCreatingCell: View {
    @State private var rotation: Double = 0
    private let width: CGFloat = 40

    var body: some View {
        HStack(spacing: 16) {
            loading
            VStack(alignment: .leading, spacing: 2) {
                Text("    ")
                    .frame(height: 12)
                Text("              ")
                    .frame(height: 12)
                Text("        ")
                    .frame(height: 12)
            }
            .mockPlaceholder(true)
            Spacer()
        }
    }

    @ViewBuilder
    var loading: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.Theme.Accent.green.opacity(0.2),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: width, height: width)

            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(
                    Color.Theme.Accent.green,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: width, height: width)
                .rotationEffect(.degrees(rotation) - .degrees(45))
                .shadow(color: Color.green.opacity(0.3), radius: 20, x: 0, y: 10)
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }

            Image("icon_qr_flow")
                .resizable()
                .scaledToFit()
                .frame(width: 33, height: 33)
                .clipShape(Circle())
        }
        .frame(width: width, height: width)
    }
}

#Preview {
    AccountCreatingCell()
}
