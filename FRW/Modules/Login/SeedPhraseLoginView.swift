//
//  SeedPhraseLoginView.swift
//  FRW
//
//  Created by cat on 2024/9/27.
//

import SwiftUI

struct SeedPhraseLoginView: RouteableView {
    var title: String {
        "import_wallet".localized
    }

    private let backupType: RestoreWalletViewModel.ImportType = .seedPhrase

    @StateObject
    var viewModel = SeedPhraseLoginViewModel()

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ImportTitleHeader(backupType: .seedPhrase)
                        .padding(.top, 48)

                    Section {
                        ImportTextView(
                            content: $viewModel.words,
                            placeholder: "seedphrase_hint".localized
                        ) { text in
                            viewModel.updateWords(text)
                        }
                        .frame(height: 120)

                    } header: {
                        ImportSectionTitleView(title: "Seed Phrase".localized, isStar: true)
                    }

                    Section {
                        AnimatedSecureTextField(
                            placeholder: "keystore_address".localized,
                            text: $viewModel.wantedAddress
                        ) { _ in
                            viewModel.updateState()
                        }
                        .frame(height: 64)

                    } header: {
                        ImportSectionTitleView(title: "address".localized, isStar: false)
                    }

                    HStack {
                        HStack {
                            Image(systemName: viewModel.isAdvanced ? "minus.circle" : "plus.circle")
                                .font(.inter(size: 20))
                                .foregroundStyle(Color.Theme.Text.black)

                            Text("advanced".localized)
                                .font(.inter(size: 14, weight: .semibold))
                                .foregroundStyle(Color.Theme.Text.black)
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                viewModel.isAdvanced.toggle()
                            }
                        }

                        Spacer()
                    }

                    VStack(spacing: 16) {
                        Section {
                            AnimatedSecureTextField(
                                placeholder: "Derivation Path".localized + " (m/44'/539'/0'/0/0)",
                                text: $viewModel.derivationPath
                            ) { _ in
                                viewModel.updateState()
                            }
                            .frame(height: 64)

                        } header: {
                            ImportSectionTitleView(title: "Derivation Path".localized, isStar: true)
                        }

                        Section {
                            AnimatedSecureTextField(
                                placeholder: "Passphrase".localized + " " + "Optional".localized,
                                text: $viewModel.passphrase
                            ) { _ in
                                viewModel.updateState()
                            }
                            .frame(height: 64)

                        } header: {
                            ImportSectionTitleView(title: "Passphrase".localized, isStar: false)
                        }
                    }
                    .visibility(viewModel.isAdvanced ? .visible : .gone)
                    .animation(.smooth, value: viewModel.isAdvanced)
                }
            }
            .padding(.bottom, 24)

            Spacer()

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.buttonState,
                action: {
                    viewModel.onSubmit()
                },
                title: "import_btn_text".localized.lowercased()
                    .uppercasedFirstLetter()
            )
            .padding(.bottom)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false, content: {
                LazyHStack(alignment: .center, spacing: 10, content: {
                    Text("  ")
                    ForEach(viewModel.suggestions, id: \.self) { word in

                        Button {
                            let last = viewModel.words.split(separator: " ").last ?? ""
                            viewModel.words.removeLast(last.count)
                            viewModel.words.append(word)
                            viewModel.words.append(" ")

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
        .padding(.horizontal, 24)
        .backgroundFill(Color.Theme.Background.grey)
        .hideKeyboardWhenTappedAround()
        .applyRouteable(self)
        .tracedView(self)
    }
}

#Preview(body: {
    SeedPhraseLoginView()
})
