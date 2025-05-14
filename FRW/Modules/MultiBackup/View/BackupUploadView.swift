//
//  BackupUploadView.swift
//  FRW
//
//  Created by cat on 2023/12/14.
//

import SwiftUI

// MARK: - BackupUploadView

struct BackupUploadView: RouteableView {
    // MARK: Lifecycle

    init(items: [MultiBackupType]) {
        _viewModel = StateObject(wrappedValue: BackupUploadViewModel(items: items))
    }

    // MARK: Internal

    @StateObject
    var viewModel: BackupUploadViewModel

    var title: String {
        "multi_backup".localized
    }

    var body: some View {
        VStack(alignment: .center) {
            BackupUploadView.ProgressView(
                items: viewModel.items,
                currentIndex: $viewModel.currentIndex
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.horizontal, 56)
            .visibility(viewModel.process == .end ? .gone : .visible)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if viewModel.process != .end {
                        Image(viewModel.currentIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .background(.Theme.Background.white)
                            .cornerRadius(60)
                            .clipped()
                            .visibility((
                                viewModel.currentType == .phrase && viewModel
                                    .process != .idle
                            ) ? .gone : .visible)
                    }

                    BackupUploadView.CompletedView(items: viewModel.items)
                        .visibility(viewModel.process == .end ? .visible : .gone)

                    Text(viewModel.currentTitle)
                        .font(.inter(size: 20, weight: .bold))
                        .foregroundStyle(Color.Theme.Text.black)

                    Text(viewModel.currentNote)
                        .font(.inter(size: 12))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.Theme.Accent.grey)
                        .frame(alignment: .top)
                        .visibility(viewModel.process == .end ? .gone : .visible)
                }
                .padding(.top, 32)
                .padding(.horizontal, 40)

                if viewModel.currentType != .phrase {
                    BackupUploadTimeline(
                        backupType: viewModel.currentType,
                        isError: viewModel.hasError,
                        process: viewModel.process
                    )
                    .padding(.top, 64)
                    .visibility(viewModel.showTimeline() ? .visible : .gone)
                }

                if viewModel.currentType == .phrase {
                    ScrollView(showsIndicators: false, content: {
                        if viewModel.process == .idle {
                            VStack {
                                TextCheckListView(titles: [
                                    "multi_check_phrase_1".localized,
                                    "multi_check_phrase_2".localized,
                                    "multi_check_phrase_3".localized,
                                ], allChecked: $viewModel.checkAllPhrase)

                                Button {
                                    viewModel.learnMore()
                                } label: {
                                    Text("Learn__more::message".localized)
                                        .font(.inter(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.Theme.Accent.blue)
                                        .padding(.vertical, 16)
                                }
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 40)
                        } else if viewModel.process == .regist || viewModel
                            .process == .upload || viewModel.process == .finish
                        {
                            if let mnemonic = MultiBackupManager.shared.mnemonic {
                                BackupUploadView.PhraseWords(
                                    isBlur: viewModel.mnemonicBlur,
                                    mnemonic: mnemonic
                                )
                                .padding(.horizontal, 24)
                            }
                        }
                    })
                }

                if viewModel.process == .end {
                    VStack {
                        VStack {
                            ForEach(viewModel.items, id: \.self) { backupType in
                                BackupedItemView(backupType: backupType)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.top, 8)
                }
            }
            .clipped()

            Spacer()

            VPrimaryButton(
                model: ButtonStyle.primary,
                state: viewModel.buttonState,
                action: {
                    viewModel.onClickButton()
                },
                title: viewModel.currentButton
            )
            .padding(.horizontal, 18)
            .padding(.bottom)
        }
        .applyRouteable(self)
        .tracedView(self)
        .backgroundFill(Color.LL.Neutrals.background)
    }

    func backButtonAction() {
        Router.popToRoot()
    }
}

extension BackupUploadView {
    struct ProgressView: View {
        let items: [MultiBackupType]
        @Binding
        var currentIndex: Int

        var body: some View {
            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    let isSelected = currentIndex >= index
                    let isProgressed = currentIndex > index
                    BackupUploadView.ProgressItem(
                        itemType: items[index],
                        isSelected: isSelected
                    )
                    .zIndex(1)
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 1)
                        .background(
                            isProgressed ? .Theme.Accent.green
                                : .Theme.Background.silver
                        )
                }

                Image("icon.finish.32")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .inset(by: -0.5)
                            .stroke(Color.Theme.Accent.green, lineWidth: currentIndex >= items.count ? 1 : 0)
                    }
            }
            .frame(maxWidth: .infinity)
        }
    }

    struct ProgressItem: View {
        let itemType: MultiBackupType
        var isSelected: Bool = false

        var body: some View {
            ZStack {
                Image(itemType.normalIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .inset(by: -0.5)
                            .stroke(Color.Theme.Accent.green, lineWidth: isSelected ? 1 : 0)
                    }
            }
        }
    }
}

// MARK: BackupUploadView.CompletedView

extension BackupUploadView {
    struct CompletedView: View {
        // MARK: Internal

        let items: [MultiBackupType]

        var body: some View {
            build()
        }

        func build() -> some View {
            VStack {
                if items.count == 1 {
                    firstBuild()
                } else if items.count == 2 {
                    twoBuild()
                } else {
                    moreBuild()
                }
            }
        }

        // MARK: Private

        private func firstBuild() -> some View {
            icon(name: items.first!.iconName())
        }

        private func twoBuild() -> some View {
            HStack {
                if items.count == 2 {
                    icon(name: items[0].iconName())
                    linkIcon()
                    icon(name: items[1].iconName())
                }
            }
        }

        private func moreBuild() -> some View {
            VStack(spacing: 0) {
                HStack {
                    if items.count >= 2 {
                        icon(name: items[0].iconName())
                        Spacer()
                        icon(name: items[1].iconName())
                    }
                }
                linkIcon()
                    .offset(y: -12)
                    .rotationEffect(items.count > 3 ? Angle(degrees: 30) : .zero)
                HStack {
                    if items.count >= 3 {
                        icon(name: items[2].iconName())
                    }
                    if items.count >= 4 {
                        Spacer()
                        icon(name: items[3].iconName())
                    }
                }
                .padding(.top, 16)
            }
        }

        private func icon(name: String) -> some View {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .background(.Theme.Background.white)
                .cornerRadius(40)
                .clipped()
        }

        private func linkIcon() -> some View {
            Image("icon.backup.link")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 24, height: 24)
                .cornerRadius(12)
                .clipped()
        }
    }
}

// MARK: BackupUploadView.PhraseWords

extension BackupUploadView {
    struct PhraseWords: View {
        // MARK: Lifecycle

        init(isBlur: Bool, mnemonic: String) {
            self.mnemonic = mnemonic
            self.isBlur = isBlur
            dataSource = mnemonic.split(separator: " ").enumerated().map { item in
                WordListView.WordItem(id: item.offset + 1, word: String(item.element))
            }
        }

        // MARK: Internal

        var isBlur: Bool = true
        var mnemonic: String

        var body: some View {
            VStack {
                VStack {
                    HStack {
                        Spacer()
                        WordListView(data: Array(dataSource.prefix(8)))
                        Spacer()
                        WordListView(data: Array(dataSource.suffix(from: 8)))
                        Spacer()
                    }
                }
                .blur(radius: isBlur ? 10 : 0)
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .border(Color.Theme.Text.black, cornerRadius: 16)
                .animation(.linear(duration: 0.2), value: isBlur)
                .padding(.top, 20)

                VStack(alignment: .leading) {
                    Button {
                        UIPasteboard.general.string = self.mnemonic
                        HUD.success(title: "copied".localized)
                    } label: {
                        Image("icon-copy-phrase")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(Color.Theme.Accent.green)
                            .frame(width: 100, height: 40)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .visibility(isBlur ? .gone : .visible)

                PrivateKeyWarning()
                    .padding(.top)
                    .padding(.bottom)
                    .visibility(isBlur ? .gone : .visible)
            }
        }

        // MARK: Private

        private var dataSource: [WordListView.WordItem]
    }
}

// MARK: BackupUploadView.AllBackupView

extension BackupUploadView {
    struct AllBackupView: View {
        var body: some View {
            VStack {}
        }
    }
}

#Preview {
    BackupUploadView.ProgressView(items: [.google, .dropbox], currentIndex: .constant(0))
//    BackupUploadView.CompletedView(items: [.google,.passkey, .icloud, ])
//    BackupUploadView.PhraseWords(
//        isBlur: true,
//        mnemonic: "timber bulk peace tree cannon vault tomorrow case violin decade bread song song song song"
//    )
}
