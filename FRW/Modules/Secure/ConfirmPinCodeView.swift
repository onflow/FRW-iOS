//
//  ConfirmPinCodeView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 6/1/22.
//

import SwiftUI

extension ConfirmPinCodeView {
    struct ViewState {
        let lastPin: String
        var pinCodeErrorTimes: Int = 0
        var text: String = ""
    }

    enum Action {
        case match(String)
    }
}

// MARK: - ConfirmPinCodeView

struct ConfirmPinCodeView: RouteableView {
    // MARK: Lifecycle

    init(lastPin: String) {
        _viewModel = StateObject(wrappedValue: ConfirmPinCodeViewModel(pin: lastPin))
    }

    // MARK: Internal

    @StateObject
    var viewModel: ConfirmPinCodeViewModel

    var title: String {
        ""
    }

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(alignment: .leading) {
                Text("please_confirm".localized)
                    .bold()
                    .foregroundColor(Color.LL.text)
                    .font(.LL.largeTitle)
                HStack {
                    Text("your".localized)
                        .bold()
                        .foregroundColor(Color.LL.text)

                    Text("pin".localized)
                        .bold()
                        .foregroundColor(Color.LL.orange)
                }
                .font(.LL.largeTitle)

                Text("no_restore_desc".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 30)

            PinCodeTextField(text: $viewModel.state.text)
                .keyboardType(.numberPad)
                .fixedSize()
                .modifier(Shake(animatableData: CGFloat(viewModel.state.pinCodeErrorTimes)))
                .focused($pinCodeViewIsFocus)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pinCodeViewIsFocus = true
                    }
                }
                .onChange(of: viewModel.state.text) { value in
                    if value.count == 6 {
                        viewModel.trigger(.match(value))
                    }
                }

            Spacer()
        }
        .padding(.horizontal, 28)
        .background(Color.LL.background, ignoresSafeAreaEdges: .all)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @FocusState
    private var pinCodeViewIsFocus: Bool
}

// MARK: - ConfirmPinCodeView_Previews

struct ConfirmPinCodeView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmPinCodeView(lastPin: "111111")
    }
}
