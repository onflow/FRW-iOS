//
//  CircleButton.swift
//  FRW
//
//  Created by cat on 5/6/25.
//

import SwiftUI

// MARK: - Style

extension CircleButton {
    enum Style {
        case menu, add
        case custom(String)

        var imageName: String {
            switch self {
            case .menu:
                "icon-wallet-manager"
            case .add:
                "icon-wallet-coin-add"
            case let .custom(name):
                name
            }
        }

        var size: CGFloat {
            switch self {
            case .menu:
                28
            default:
                24
            }
        }
    }
}

// MARK: - CircleButton

struct CircleButton: View {
    let image: CircleButton.Style
    let size: CGFloat = 40
    let onClick: EmptyClosure

    var body: some View {
        Button {
            onClick()
        } label: {
            HStack {
                Image(image.imageName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.Theme.Text.black8)
                    .frame(width: image.size, height: image.size)
            }
            .frame(width: size, height: size)
            .background(Color.Theme.Special.white1)
            .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    HStack {
        CircleButton(image: .menu) {}
        CircleButton(image: .add) {}
    }
}
