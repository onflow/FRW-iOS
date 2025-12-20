//
//  PrivateKeyLoginView.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import SwiftUI
import SwiftUIX

struct PrivateKeyLoginView: RouteableView {
    var title: String {
        "import_wallet".localized
    }

    private let backupType: RestoreWalletViewModel.ImportType = .privateKey

    @StateObject var viewModel: PrivateKeyLoginViewModel

    init(privateKey: String? = nil) {
      _viewModel = StateObject(wrappedValue: PrivateKeyLoginViewModel(key: privateKey))
    }

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ImportTitleHeader(backupType: .privateKey)
                        .padding(.top, 48)

                    Section {
                        ImportTextView(
                            content: $viewModel.key,
                            placeholder: "private_key_placeholder".localized
                        ) { value in
                            viewModel.update(key: value)
                        }
                        .frame(height: 120)

                    } header: {
                        ImportSectionTitleView(title: "private_key".localized, isStar: true)
                    }

                  HStack {
                    Button {
                        viewModel.pickPDF()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "text.document.fill")
                                .font(.system(size: 14))
                            Text("import_from_pdf".localized)
                                .font(.inter(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color.LL.frontColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.LL.rebackground)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()
                  }
                  .frame(maxWidth: .infinity)

                    Section {
                        AnimatedSecureTextField(
                            placeholder: "keystore_address".localized,
                            text: $viewModel.wantedAddress
                        ) { text in
                            viewModel.update(address: text)
                        }
                        .frame(height: 64)

                    } header: {
                        ImportSectionTitleView(title: "address".localized, isStar: false)
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
                title: "import_btn_text".localized.lowercased()
                    .uppercasedFirstLetter()
            )
            .padding(.bottom)
        }
        .padding(.horizontal, 24)
        .backgroundFill(Color.Theme.Background.grey)
        .applyRouteable(self)
        .tracedView(self)
        .sheet(isPresented: $viewModel.showPDFPicker) {
            viewModel.documentPicker
        }
    }
}

#Preview {
    PrivateKeyLoginView()
}
