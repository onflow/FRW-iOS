//
//  AddTokenView.swift
//  Flow Wallet
//
//  Created by Selina on 27/6/2022.
//

import Kingfisher
import SwiftUI

// MARK: - AddTokenView

// struct AddTokenView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddTokenView.AddTokenConfirmView(token: nil)
//    }
// }

struct AddTokenView: RouteableView {
    // MARK: Lifecycle

    init(vm: AddTokenViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    // MARK: Internal

    @StateObject
    var vm: AddTokenViewModel

    var title: String {
        if vm.mode == .addToken {
            return "add_token".localized
        } else {
            return "swap_select_token".localized
        }
    }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Toggle(isOn: $vm.onlyShowVerified) {
                        HStack(spacing: 0) {
                            Text("only_show_tokens".localized)
                                .font(.inter(size: 14))
                                .foregroundStyle(Color.Theme.Text.black)
                            Image("icon-token-valid")
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                listView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .halfSheet(
            showSheet: $vm.confirmSheetIsPresented,
            autoResizing: true,
            backgroundColor: Color.LL.Neutrals.background,
            sheetView: {
                if let token = vm.pendingActiveToken {
                    AddTokenConfirmView(token: token)
                        .environmentObject(vm)
                }
            }
        )
        .environmentObject(vm)
        .disabled(vm.isRequesting)
        .applyRouteable(self)
    }

    var listView: some View {
        IndexedList(vm.searchResults) { section in
            Section {
                ForEach(section.tokenList) { token in
                    TokenItemCell(token: token, isActivated: vm.isActivatedToken(token), action: {
                        if vm.mode == .selectToken {
                            vm.selectTokenAction(token)
                        } else {
                            vm.willActiveTokenAction(token)
                        }
                    })
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .disabled(vm.isDisabledToken(token))
                }
                .buttonStyle(.plain)
                .environmentObject(vm)
            } header: {
                sectionHeader(section)
                    .id(section.id)
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 27))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .listStyle(.plain)
        .background(Color.LL.background)
        .searchable(text: $vm.searchText)
    }

    func backButtonAction() {
        if vm.mode == .addToken {
            Router.pop()
        } else {
            Router.dismiss()
        }
    }

    // MARK: Private

    @ViewBuilder
    private func sectionHeader(_ section: AddTokenViewModel.Section) -> some View {
        let sectionName = section.sectionName
        Text(sectionName)
            .foregroundColor(.LL.Neutrals.text2)
            .font(.inter(size: 12, weight: .semibold))
    }
}

private let TokenIconWidth: CGFloat = 40
private let TokenCellHeight: CGFloat = 64

// MARK: AddTokenView.TokenItemCell

extension AddTokenView {
    struct TokenItemCell: View {
        let token: TokenModel
        let isActivated: Bool
        let action: () -> Void
        @EnvironmentObject
        var vm: AddTokenViewModel

        var body: some View {
            Button {
                if isEVMAccount && vm.mode == .addToken {
                    return
                }
                action()
            } label: {
                HStack {
                    KFImage.url(token.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: TokenIconWidth, height: TokenIconWidth)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(token.name)
                                .foregroundColor(.LL.Neutrals.text)
                                .font(.inter(size: 14, weight: .semibold))
                            Image("icon-token-valid")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .visibility(token.isVerifiedValue ? .visible : .gone)
                        }

                        Text(token.symbol?.uppercased() ?? "")
                            .foregroundColor(.LL.Neutrals.note)
                            .font(.inter(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isEVMAccount && vm.mode == .addToken {
                        HStack {}
                    } else {
                        if isActivated {
                            Image(systemName: .checkmarkSelected)
                                .foregroundColor(.LL.Success.success3)
                        } else {
                            Image(systemName: .add).foregroundColor(.LL.Primary.salmonPrimary)
                                .visibility(vm.mode == .addToken ? .visible : .gone)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: TokenCellHeight)
                .background {
                    Color.LL.Neutrals.background.cornerRadius(16)
                }
            }
        }

        var isEVMAccount: Bool {
            EVMAccountManager.shared.selectedAccount != nil
        }
    }
}

// MARK: AddTokenView.AddTokenConfirmView

extension AddTokenView {
    struct AddTokenConfirmView: View {
        @EnvironmentObject
        var vm: AddTokenViewModel
        let token: TokenModel

        @State
        var color = Color.LL.Neutrals.note.opacity(0.1)

        var buttonState: VPrimaryButtonState {
            if vm.isRequesting {
                return .loading
            }
            return .enabled
        }

        var body: some View {
            VStack {
                SheetHeaderView(title: "add_token".localized) {
                    vm.confirmSheetIsPresented = false
                }

                VStack {
                    Spacer()

                    ZStack {
                        ZStack(alignment: .top) {
                            color
                                .frame(maxWidth: .infinity)
                                .frame(height: 188)
                                .cornerRadius(16)
                                .animation(.easeInOut, value: color)

                            Text(token.name)
                                .foregroundColor(.LL.Button.light)
                                .font(.inter(size: 18, weight: .bold))
                                .padding(.horizontal, 40)
                                .frame(height: 45)
                                .background(Color(hex: "#1A1A1A"))
                                .cornerRadius([.bottomLeading, .bottomTrailing], 16)
                        }

                        KFImage
                            .url(token.iconURL)
                            .placeholder {
                                Image("placeholder")
                                    .resizable()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 114, height: 114)
                            .clipShape(Circle())
                            .padding(.top, 45)
                    }

                    Spacer()

                    VPrimaryButton(
                        model: ButtonStyle.primary,
                        state: buttonState,
                        action: {
                            vm.confirmActiveTokenAction(token)
                        },
                        title: buttonState == .loading ? "working_on_it"
                            .localized : "enable".localized
                    )
                    .padding(.vertical)
                }
                .padding(.horizontal, 36)
            }
            .task {
                Task { @MainActor in
                    if let color = await ImageHelper
                        .colors(from: token.iconURL.absoluteString).first
                    {
                        self.color = color.opacity(0.1)
                    }
                }
            }
        }
    }
}
