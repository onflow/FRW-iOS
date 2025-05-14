//
//  ImportUserNameView.swift
//  FRW
//
//  Created by cat on 2024/9/13.
//

import SwiftUI

struct ImportUserNameView: RouteableView {
    // MARK: Lifecycle

    init(viewModel: ImportUserNameViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    @State
    var status: LL.TextField.Status = .normal
    @StateObject
    var viewModel: ImportUserNameViewModel

    var title: String {
        ""
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                Text("pick_your".localized)
                    .font(.LL.largeTitle)
                    .bold()
                    .foregroundColor(Color.LL.rebackground)
                Text("username".localized)
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(Color.Theme.Accent.green)
                Text("username_desc".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()

            VTextField(
                model: TextFieldStyle.primary,
                type: .userName,
                highlight: highlight,
                placeholder: "username".localized,
                footerTitle: footerText,
                text: $viewModel.userName,
                onChange: {
                    viewModel.onEditingChanged(viewModel.userName)
                },
                onReturn: .returnAndCustom {
                    viewModel.onEditingChanged(viewModel.userName)
                },
                onClear: .clearAndCustom {
                    viewModel.onEditingChanged(viewModel.userName)
                }
            )
            .padding(.bottom, 10)

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: buttonState,
                action: {
                    viewModel.onConfirm()
                },
                title: "next".localized
            )
            .padding(.bottom)
        }
        .dismissKeyboardOnDrag()
        .padding(.horizontal, 28)
        .background(Color.LL.background, ignoresSafeAreaEdges: .all)
        .applyRouteable(self)
        .tracedView(self)
    }

    var highlight: VTextFieldHighlight {
        switch status {
        case .success:
            return .success
        case .error:
            return .error
        case .normal:
            return .none
        case .loading:
            return .loading
        }
    }

    var footerText: String {
        switch status {
        case .success:
            return "nice_one".localized
        case let .error(message):
            return message
        case .normal:
            return " "
        case .loading:
            return "checking".localized
        }
    }

    var buttonState: VPrimaryButtonState {
        viewModel.userName.isEmpty ? .disabled : .enabled
    }

    func backButtonAction() {
        UIApplication.shared.endEditing()
        Router.pop()
    }
}

#Preview {
    ImportUserNameView(viewModel: ImportUserNameViewModel(callback: { _ in

    }))
}
