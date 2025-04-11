//
//  InputMnemonicView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 8/1/22.
//

import SwiftUI
import SwiftUIX

extension InputMnemonicView {
    struct ViewState {
        var nextEnable: Bool = false
        var hasError: Bool = false
        var suggestions: [String] = []
        var text: String = ""
        var isAlertViewPresented: Bool = false
    }

    enum Action {
        case next
        case onEditingChanged(String)
        case confirmCreateWallet
    }
}

// MARK: - InputMnemonicView

struct InputMnemonicView: RouteableView {
    @StateObject
    private var viewModel = InputMnemonicViewModel()

    var model: VTextFieldModel = {
        var model = TextFieldStyle.primary
        model.colors.clearButtonIcon = .clear
        model.layout.height = 150
        return model
    }()

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

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("sign_in_with".localized)
                    .foregroundColor(Color.LL.text)
                    .bold()
                    .font(.LL.largeTitle)

                Text("recovery_phrase".localized)
                    .foregroundColor(Color.LL.orange)
                    .bold()
                    .font(.LL.largeTitle)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .minimumScaleFactor(0.5)

                Text("phrase_you_created_desc".localized)
                    .lineSpacing(5)
                    .font(.inter(size: 14, weight: .regular))
                    .foregroundColor(.LL.note)
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 25)
            .padding(.horizontal, 28)

            ZStack(alignment: .topLeading) {
                if viewModel.state.text.isEmpty {
                    Text("enter_rp_placeholder".localized)
                        .font(.LL.body)
                        .foregroundColor(.LL.note)
                        .padding(.all, 10)
                        .padding(.top, 2)
                }

                TextEditor(text: $viewModel.state.text)
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
                    .onChange(of: viewModel.state.text, perform: { value in
                        viewModel.trigger(.onEditingChanged(value))
                    })
                    .font(.LL.body)
                    .frame(height: 120)
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1)
                            .foregroundColor(viewModel.state.hasError ? .LL.error : .LL.text)
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
            .foregroundColor(viewModel.state.hasError ? .LL.error : .LL.text)
            .padding(.horizontal, 28)
            .padding(.vertical, 4)
            .opacity(viewModel.state.hasError ? 1 : 0)
            .animation(.linear, value: viewModel.state.hasError)

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.state.nextEnable ? .enabled : .disabled,
                action: {
                    viewModel.trigger(.next)
                },
                title: "next".localized
            )
            .padding(.horizontal, 28)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false, content: {
                LazyHStack(alignment: .center, spacing: 10, content: {
                    Text("  ")
                    ForEach(viewModel.state.suggestions, id: \.self) { word in

                        Button {
                            let last = viewModel.state.text.split(separator: " ").last ?? ""
                            viewModel.state.text.removeLast(last.count)
                            viewModel.state.text.append(word)
                            viewModel.state.text.append(" ")

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
            isPresented: $viewModel.state.isAlertViewPresented,
            title: "account_not_found".localized,
            attributedDesc: accountNotFoundDesc,
            buttons: [AlertView.ButtonItem(
                type: .confirm,
                title: "create_wallet".localized,
                action: {
                    viewModel.trigger(.confirmCreateWallet)
                }
            )]
        )
    }
}

extension InputMnemonicView {
    var title: String {
        ""
    }
}

// MARK: - InputMnemonicView_Previews

struct InputMnemonicView_Previews: PreviewProvider {
    static var previews: some View {
        InputMnemonicView().previewDevice("iPhone 13 mini")
    }
}
