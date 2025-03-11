//
//  ShowRecoveryPhraseBackup.swift
//  FRW
//
//  Created by cat on 2024/9/19.
//

import SwiftUI

struct ShowRecoveryPhraseBackup: RouteableView {
    // MARK: Lifecycle

    init(mnemonic: String) {
        _viewModel =
            StateObject(wrappedValue: CreateRecoveryPhraseBackupViewModel(mnemonic: mnemonic))
    }

    // MARK: Internal

    @StateObject
    var viewModel: CreateRecoveryPhraseBackupViewModel

    var title: String {
        "backup".localized
    }

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(alignment: .center, spacing: 8) {
                        HStack {
                            Text("Recovery__Phrase::message".localized)
                                .font(.inter(size: 20, weight: .bold))
                                .foregroundColor(Color.Theme.Text.black)
                        }

                        Text("words_save_tips".localized)
                            .font(.inter(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.LL.note)
                    }

                    VStack {
                        HStack {
                            Spacer()
                            WordListView(data: Array(viewModel.dataSource.prefix(6)))
                            Spacer()
                            WordListView(data: Array(viewModel.dataSource.suffix(from: 6)))
                            Spacer()
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .overlay {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(lineWidth: 0.5)
                        }
                        .allowsHitTesting(false)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading) {
                        Button {
                            viewModel.onCopy()
                        } label: {
                            Image("icon-copy-phrase")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(Color.Theme.Accent.green)
                                .frame(width: 100, height: 40)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    PrivateKeyWarning()
                        .padding(.top)
                        .padding(.bottom)
                }
            }
            Spacer()

            VPrimaryButton(
                model: ButtonStyle.primary,
                action: {
                    viewModel.onCreate()
                },
                title: "done".localized
            )
            .padding(.bottom, 20)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 28)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
    }
}

#Preview {
    ShowRecoveryPhraseBackup(mnemonic: "")
}
