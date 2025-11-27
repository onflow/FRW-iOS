//
//  RecoveryPhraseView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 3/1/22.
//

import SwiftUI

extension RecoveryPhraseView {
    struct ViewState {
        var dataSource: [WordListView.WordItem]
        var icloudLoading: Bool = false
    }

    enum Action {
        case icloudBackup
        case googleBackup
        case manualBackup
        case copy
    }
}

// MARK: - RecoveryPhraseView

struct RecoveryPhraseView: RouteableView {
    // MARK: Lifecycle

    init(backupMode: Bool) {
        isInBackupMode = backupMode
    }

    // MARK: Internal

    @StateObject
    var viewModel = RecoveryPhraseViewModel()
    @State
    var isBlur: Bool = true

    var title: String {
        ""
    }

    var copyBtn: some View {
        Button {
            viewModel.trigger(.copy)
        } label: {
          HStack(spacing: 12) {
            Image("profile_back_copy")
              .resizable()
              .renderingMode(.template)
              .foregroundStyle(Color.Brain.Primary.main)
              .frame(width: 24, height: 24)
            Text("copy".localized)
              .font(.inter(size:14, weight: .bold))
              .foregroundStyle(Color.Brain.Primary.main)
          }
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(alignment: .center, spacing: 10) {
                    Text("recovery_phrase".localized)
                      .font(.inter(size: 20, weight: .w700))
                      .foregroundStyle(Color.Brain.Text.primary)

                    Text("words_save_tips".localized)
                      .font(.inter(size: 14))
                      .multilineTextAlignment(.center)
                      .foregroundStyle(Color.Brain.Text.primary)
                }

                VStack {
                    HStack {
                        Spacer()
                        WordListView(data: Array(viewModel.state.dataSource.prefix(6)))
                        Spacer()
                        WordListView(data: Array(viewModel.state.dataSource.suffix(from: 6)))
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
                }
                .onTapGesture {
                    isBlur.toggle()
                }
                .blur(radius: isBlur ? 10 : 0)
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(lineWidth: 0.5)
                        VStack(spacing: 10) {

                          Image("profile-lock")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(Color.Brain.Core.cards)
                            .frame(width: 16, height: 16)

                          Text("reveal".localized)
                            .font(.inter(size: 16, weight: .medium))
                            .foregroundStyle(Color.Brain.Text.primary)

                        }
                        .opacity(isBlur ? 1 : 0)
                        .foregroundColor(.LL.note)
                    }
                    .allowsHitTesting(false)
                }
                .animation(.linear(duration: 0.2), value: isBlur)

                copyBtn

                PrivateKeyWarning()

                Spacer()

                VPrimaryButton(
                    model: ButtonStyle.primary,
                    state: viewModel.state.icloudLoading ? .loading : .enabled,
                    action: {
                        viewModel.trigger(.icloudBackup)
                    },
                    title: "backup_to_icloud".localized
                )
                .padding(.top, 20)
                .visibility(isInBackupMode ? .gone : .visible)

                VPrimaryButton(
                    model: ButtonStyle.primary,
                    action: {
                        viewModel.trigger(.googleBackup)
                    },
                    title: "backup_to_gd".localized
                )
                .padding(.top, 8)
                .visibility(isInBackupMode ? .gone : .visible)

                VPrimaryButton(
                    model: ButtonStyle.border,
                    action: {
                        viewModel.trigger(.manualBackup)
                    },
                    title: "backup_manually".localized
                )
                .padding(.top, 8)
                .padding(.bottom, 20)
                .visibility(isInBackupMode ? .gone : .visible)
            }
        }
        .padding(.horizontal, 18)
        .backgroundFill(Color.Brain.Core.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    private var isInBackupMode = false
}

//// MARK: - RecoveryPhraseView_Previews
//
//struct RecoveryPhraseView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecoveryPhraseView(backupMode: false)
//    }
//}

// MARK: - WordListView

struct WordListView: View {
    struct WordItem: Identifiable {
        var id: Int
        let word: String
    }

    var data: [WordItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(data) { item in
                HStack(spacing: 18) {
                    Circle()
                        .aspectRatio(1, contentMode: .fit)
                        .height(30)
                        .foregroundColor(.separator.opacity(0.3))
                        .overlay {
                            Text(String(item.id))
                                .font(.caption)
                                .foregroundColor(Color.LL.rebackground)
                                .padding(8)
                                .minimumScaleFactor(0.8)
                        }
                    Text(item.word)
                        .fontWeight(.semibold)
                        .minimumScaleFactor(0.5)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .instabug_privateView()
    }
}
