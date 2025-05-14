//
//  MultiBackupConfirmPinView.swift
//  FRW
//
//  Created by cat on 2024/2/6.
//

import SwiftUI

struct MultiBackupConfirmPinView: RouteableView {
    // MARK: Lifecycle

    init(lastPin: String) {
        _viewModel = StateObject(wrappedValue: MultiBackupConfirmPinViewModel(pin: lastPin))
    }

    // MARK: Internal

    @StateObject
    var viewModel: MultiBackupConfirmPinViewModel

    var title: String {
        ""
    }

    var body: some View {
        VStack(spacing: 15) {
            Spacer()
            VStack(alignment: .leading) {
                Text("please_confirm".localized)
                    .bold()
                    .foregroundColor(Color.Theme.Text.black8)
                    .font(.LL.largeTitle)
                HStack {
                    Text("your".localized)
                        .bold()
                        .foregroundColor(Color.Theme.Text.black8)

                    Text("pin".localized)
                        .bold()
                        .foregroundColor(Color.Theme.Accent.green)
                }
                .font(.LL.largeTitle)

                Text("no_restore_desc".localized)
                    .font(.LL.body)
                    .foregroundColor(.LL.note)
                    .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 30)

            PinCodeTextField(text: $viewModel.text)
                .keyboardType(.numberPad)
                .fixedSize()
                .modifier(Shake(animatableData: CGFloat(viewModel.pinCodeErrorTimes)))
                .focused($pinCodeViewIsFocus)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        pinCodeViewIsFocus = true
                    }
                }
                .onChange(of: viewModel.text) { value in
                    if value.count == 6 {
                        viewModel.onMatch(confirmPin: value)
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

#Preview {
    MultiBackupConfirmPinView(lastPin: "123456")
}
