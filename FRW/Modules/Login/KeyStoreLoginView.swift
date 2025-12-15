//
//  KeyStoreLoginView.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import SwiftUI
import SwiftUIX

struct KeyStoreLoginView: RouteableView {
    var title: String {
        "import_wallet".localized
    }

    private let backupType: RestoreWalletViewModel.ImportType = .keyStore

    @StateObject
    var viewModel = KeyStoreLoginViewModel()

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ImportTitleHeader(backupType: .keyStore)
                        .padding(.top, 48)

                    Section {
                        VStack(spacing: 0) {
                            ImportTextView(
                                content: $viewModel.json,
                                placeholder: "keystore_json".localized
                            ) { value in
                                viewModel.update(json: value)
                            }
                            .frame(height: 120)
                        }

                        // Import from PDF button
                        Button {
                            viewModel.pickPDF()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 14))
                                Text("import_from_pdf".localized)
                                    .font(.inter(size: 14, weight: .medium))
                            }
                            .foregroundColor(Color.Theme.Accent.green)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 8)

                    } header: {
                        ImportSectionTitleView(title: "JSON", isStar: true)
                    }

                    Section {
                        AnimatedSecureTextField(
                            placeholder: "keystore_password".localized,
                            text: $viewModel.password
                        ) { value in
                            viewModel.update(password: value)
                        }
                        .frame(height: 64)

                    } header: {
                        ImportSectionTitleView(title: "password", isStar: true)
                    }

                    Section {
                        AnimatedSecureTextField(
                            placeholder: "keystore_address".localized,
                            text: $viewModel.wantedAddress
                        ) { text in
                            viewModel.update(address: text)
                        }
                        .frame(height: 64)

                    } header: {
                        ImportSectionTitleView(title: "address", isStar: false)
                    }
                }
            }
            .padding(.bottom, 24)

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.buttonState,
                action: {
                    viewModel.onSumbit()
                },
                title: "import_btn_text".localized.lowercased().uppercasedFirstLetter()
            )
            .padding(.bottom)
        }
        .padding(.horizontal, 24)
        .backgroundColor(Color.Theme.Background.grey)
        .hideKeyboardWhenTappedAround()
        .applyRouteable(self)
        .tracedView(self)
        .sheet(isPresented: $viewModel.showPDFPicker) {
            viewModel.documentPicker
        }
        .overlay {
            if viewModel.isPDFProcessing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }
}

#Preview {
    KeyStoreLoginView()
        .background(.yellow)
}
