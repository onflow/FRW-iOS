//
//  UsernameView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 26/12/21.
//

import SwiftUI
import SwiftUIX

extension UsernameView {
    struct ViewState {
        var status: LL.TextField.Status = .normal
        var isRegisting: Bool = false
    }

    enum Action {
        case next
        case onEditingChanged(String)
    }
}

extension UsernameView {
    var title: String {
        ""
    }

    func backButtonAction() {
        UIApplication.shared.endEditing()
        Router.pop()
    }
}

// MARK: - UsernameView

struct UsernameView: RouteableView {
    // MARK: Lifecycle

    init(mnemonic: String?) {
        _viewModel = StateObject(wrappedValue: UsernameViewModel(mnemonic: mnemonic))
    }

    // MARK: Internal

    @StateObject
    var viewModel: UsernameViewModel

    @State
    var text: String = ""

    var buttonState: VPrimaryButtonState {
        if viewModel.state.isRegisting {
            return .loading
        }

        return highlight == .success ? .enabled : .disabled
    }

    var highlight: VTextFieldHighlight {
        switch viewModel.state.status {
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
        switch viewModel.state.status {
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
                text: $text,
                onChange: {
                    viewModel.trigger(.onEditingChanged(text))
                },
                onReturn: .returnAndCustom {
                    viewModel.trigger(.next)
                },
                onClear: .clearAndCustom {
                    viewModel.trigger(.onEditingChanged(text))
                }
            )
            .disabled(viewModel.state.isRegisting)
            .padding(.bottom, 10)

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: buttonState,
                action: {
                    viewModel.trigger(.next)
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
}

// MARK: - UsernameView_Previews

struct UsernameView_Previews: PreviewProvider {
    static var previews: some View {
        UsernameView(mnemonic: nil)
    }
}
