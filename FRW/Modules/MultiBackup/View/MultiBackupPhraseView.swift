//
//  MultiBackupPhraseView.swift
//  FRW
//
//  Created by cat on 2024/1/8.
//

import SwiftUI

struct MultiBackupPhraseView: RouteableView {
    // MARK: Lifecycle

    init(mnemonic: String) {
        self.mnemonic = mnemonic
        dataSource = mnemonic.split(separator: " ").enumerated().map { item in
            WordListView.WordItem(id: item.offset + 1, word: String(item.element))
        }
    }

    // MARK: Internal

    enum From {
        case create
        case backup
    }

    @State
    var isBlur: Bool = false
    var from: MultiBackupPhraseView.From = .backup
    var mnemonic: String

    var title: String {
        ""
    }

    var copyBtn: some View {
        Button {
            UIPasteboard.general.string = self.mnemonic
            HUD.success(title: "copied".localized)
        } label: {
            Image("icon-copy-phrase")
        }
    }

    var body: some View {
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("recovery".localized)
                                .bold()
                                .foregroundColor(Color.LL.text)

                            Text("phrase".localized)
                                .bold()
                                .foregroundColor(Color.LL.orange)
                        }
                        .font(.LL.largeTitle)

                        Text("words_save_tips".localized)
                            .font(.LL.body)
                            .foregroundColor(.LL.note)
                            .padding(.top, 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()

                    VStack {
                        HStack {
                            Spacer()
                            WordListView(data: Array(dataSource.prefix(8)))
                            Spacer()
                            WordListView(data: Array(dataSource.suffix(from: 8)))
                            Spacer()
                        }

                        Text("hide".localized)
                            .padding(5)
                            .padding(.horizontal, 5)
                            .foregroundColor(.LL.background)
                            .font(.LL.body)
                            .background(.LL.note)
                            .cornerRadius(12)
                            .onTapGesture {
                                isBlur = true
                            }
                            .visibility(from == .backup ? .gone : .visible)
                    }
                    .onTapGesture {
//                        isBlur.toggle()
                    }
                    .blur(radius: isBlur ? 10 : 0)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                    .overlay {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(lineWidth: 0.5)
                            VStack(spacing: 10) {
                                Image(systemName: "eyes")
                                    .font(.largeTitle)
                                Text("private_place_tips".localized)
                                    .foregroundColor(.LL.note)
                                    .font(.LL.body)
                                    .fontWeight(.semibold)
                                Text("reveal".localized)
                                    .padding(5)
                                    .padding(.horizontal, 2)
                                    .foregroundColor(.LL.background)
                                    .font(.LL.body)
                                    .background(.LL.note)
                                    .cornerRadius(12)
                                    .padding(.top, 10)
                            }
                            .opacity(isBlur ? 1 : 0)
                            .foregroundColor(.LL.note)
                        }
                        .allowsHitTesting(false)
                    }
                    .animation(.linear(duration: 0.2), value: isBlur)
                    .padding(.top, 20)

                    VStack(alignment: .leading) {
                        copyBtn
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    PrivateKeyWarning()
                        .padding(.top)
                        .padding(.bottom)

                    Spacer()
                }
            }
            Spacer()
            VPrimaryButton(
                model: ButtonStyle.primary,
                state: .enabled,
                action: {
                    Router.pop(animated: false)
                },
                title: "next".localized
            )
            .padding(.bottom)
            .visibility(from == .backup ? .gone : .visible)
        }

        .padding(.horizontal, 28)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    private var dataSource: [WordListView.WordItem]
}

#Preview {
    MultiBackupPhraseView(
        mnemonic: "tent breeze custom call thought mixed humble dilemma fold share feel food destroy arrive capable"
    )
}
