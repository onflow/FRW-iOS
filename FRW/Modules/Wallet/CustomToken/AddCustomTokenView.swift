//
//  AddCustomTokenView.swift
//  FRW
//
//  Created by cat on 10/30/24.
//

import SwiftUI

struct AddCustomTokenView: RouteableView {
    @StateObject
    var viewModel = AddCustomTokenViewModel()

    var title: String {
        "Add Custom Token".localized
    }

    var body: some View {
        VStack {
            TitleView(title: "Token Contract Address".localized, isStar: false)

            SingleInputView(content: $viewModel.customAddress) {
                viewModel.onSearch()
            }

            Button {
                viewModel.onPaste()
            } label: {
                Text("Paste Address".localized)
                    .font(.inter(size: 16))
                    .foregroundStyle(Color.Theme.Text.black8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.Theme.Background.white8)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding(16)
        .background(.Theme.Background.bg2)
        .applyRouteable(self)
        .tracedView(self)
    }
}

#Preview {
    AddCustomTokenView()
}
