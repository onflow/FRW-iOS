//
//  RestoreMultiInputMnemonicView.swift
//  FRW
//
//  Created by cat on 2024/1/8.
//

import SwiftUI

struct RestoreMultiInputMnemonicView: RouteableView {
    // MARK: Lifecycle

    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }

    // MARK: Internal

    var callback: (String) -> Void

    var model: VTextFieldModel = {
        var model = TextFieldStyle.primary
        model.colors.clearButtonIcon = .clear
        model.layout.height = 150
        return model
    }()

    var title: String {
        ""
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("recovery_phrase".localized)
                    .foregroundColor(Color.LL.orange)
                    .bold()
                    .font(.LL.largeTitle)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.5)

                Text("restore_phrase_you_created_desc".localized)
                    .lineSpacing(5)
                    .font(.inter(size: 14, weight: .regular))
                    .foregroundColor(.LL.note)
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 25)
            .padding(.horizontal, 28)

            ZStack(alignment: .topLeading) {
                if viewModel.text.isEmpty {
                    Text("restore_enter_rp_placeholder".localized)
                        .font(.LL.body)
                        .foregroundColor(.LL.note)
                        .padding(.all, 10)
                        .padding(.top, 2)
                }

                TextEditor(text: $viewModel.text)
                    .introspectTextView { view in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            view.becomeFirstResponder()
                        }
                        view.tintColor = Color.LL.orange.toUIColor()
                        view.backgroundColor = .clear
                    }
                    .keyboardType(.alphabet)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: viewModel.text, perform: { value in
                        viewModel.onEditingChanged(text: value)
                    })
                    .font(.LL.body)
                    .frame(height: 120)
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1)
                            .foregroundColor(viewModel.hasError ? .LL.error : .LL.text)
                    }
                    .instabug_privateView()
            }
            .padding(.horizontal, 28)

            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.LL.footnote)
                Text("words_not_found".localized)
                    .font(.LL.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(viewModel.hasError ? .LL.error : .LL.text)
            .padding(.horizontal, 28)
            .opacity(viewModel.hasError ? 1 : 0)
            .animation(.linear, value: viewModel.hasError)

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.nextEnable ? .enabled : .disabled,
                action: {
                    callback(viewModel.getRawMnemonic())
                    Router.pop()
                },
                title: "confirm_tag".localized
            )
            .padding(.horizontal, 28)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false, content: {
                LazyHStack(alignment: .center, spacing: 10, content: {
                    Text("  ")
                    ForEach(viewModel.suggestions, id: \.self) { word in

                        Button {
                            let last = viewModel.text.split(separator: " ").last ?? ""
                            viewModel.text.removeLast(last.count)
                            viewModel.text.append(word)
                            viewModel.text.append(" ")

                        } label: {
                            Text(word)
                                .foregroundColor(.LL.text)
                                .font(.LL.subheadline)
                                .padding(5)
                                .padding(.horizontal, 5)
                                .background(.LL.outline)
                                .cornerRadius(10)
                        }
                    }
                    Text("  ")
                })
            })
            .frame(height: 30, alignment: .leading)
            .padding(.bottom)
        }
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .customAlertView(
            isPresented: $viewModel.isAlertViewPresented,
            title: "account_not_found".localized,
            attributedDesc: accountNotFoundDesc,
            buttons: [AlertView.ButtonItem(
                type: .confirm,
                title: "create_wallet".localized,
                action: {}
            )]
        )
    }

    // MARK: Private

    @StateObject
    private var viewModel = RestoreMultiInputMnemonicViewModel()
    private var accountNotFoundDesc: NSAttributedString = {
        let normalDict = [NSAttributedString.Key.foregroundColor: UIColor.LL.Neutrals.text]
        let highlightDict =
            [NSAttributedString.Key.foregroundColor: UIColor.LL.Primary.salmonPrimary]

        var str = NSMutableAttributedString(
            string: "account_not_found_prev".localized,
            attributes: normalDict
        )
        str.append(NSAttributedString(
            string: "account_not_found_highlight".localized,
            attributes: highlightDict
        ))
        str.append(NSAttributedString(
            string: "account_not_found_suff".localized,
            attributes: normalDict
        ))

        return str
    }()
}

#Preview {
    RestoreMultiInputMnemonicView { _ in
    }
}
