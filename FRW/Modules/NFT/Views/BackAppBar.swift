//
//  BackAppBar.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/31.
//

import SwiftUI

// MARK: - BackAppBar

// MARK: - BackBarButton

enum BackBarButton {
    case none
    case share(() -> Void)
    case search(() -> Void)
    case custom(icon: String, action: () -> Void)

    @ViewBuilder
    var view: some View {
        switch self {
        case .none:
            EmptyView()
        case let .share(action):
            Button(action: action) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.LL.Button.color)
                    .frame(width: 44, height: 44)
            }
        case let .search(action):
            Button(action: action) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.LL.Button.color)
                    .frame(width: 44, height: 44)
            }
        case let .custom(icon, action):
            Button(action: action) {
                Image(systemName: icon)
                    .foregroundColor(.LL.Button.color)
                    .frame(width: 44, height: 44)
            }
        }
    }
}

struct BackAppBar: View {
    var title: String?
    var rightButton: BackBarButton
    var onBack: () -> Void

    init(title: String? = nil,
         rightButton: BackBarButton = .none,
         onBack: @escaping () -> Void)
    {
        self.title = title
        self.rightButton = rightButton
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "arrow.backward")
                        .foregroundColor(.LL.Button.color)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }

            if let title = self.title {
                Text(title)
                    .font(.title2)
                    .foregroundColor(.LL.Neutrals.text)
                    .lineLimit(1)
                    .frame(maxWidth: screenWidth - 140)
            }

            HStack {
                Spacer()
                rightButton.view
            }
        }
        .frame(height: 44)
    }
}

// MARK: - Preview

struct BackAppBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BackAppBar(title: "title") {}

            BackAppBar(
                title: "with share",
                rightButton: .share {}
            ) {}

            BackAppBar(
                title: "custom",
                rightButton: .custom(icon: "bell") {}
            ) {}
        }
        .previewLayout(.sizeThatFits)
    }
}
