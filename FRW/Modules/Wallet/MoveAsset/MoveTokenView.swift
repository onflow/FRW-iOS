//
//  MoveTokenView.swift
//  FRW
//
//  Created by cat on 2024/2/27.
//

import Kingfisher
import SwiftUI
import SwiftUIX

// MARK: - MoveTokenView

struct MoveTokenView: RouteableView, PresentActionDelegate {
    // MARK: Lifecycle

    init(tokenModel: TokenModel, isPresent: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MoveTokenViewModel(
            token: tokenModel,
            isPresent: isPresent
        ))
    }

    // MARK: Internal

    var changeHeight: (() -> Void)?

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("move_single_token".localized)
                    .font(.inter(size: 18, weight: .w700))
                    .foregroundStyle(Color.LL.Neutrals.text)
                    .padding(.top, 6)
                Spacer()

                Button {
                    viewModel.closeAction()
                } label: {
                    Image("icon_close_circle_gray")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.top, 8)

            Color.clear
                .frame(height: 20)

            VStack(spacing: 8) {
                ContactRelationView(
                    fromContact: viewModel.fromContact,
                    toContact: viewModel.toContact,
                    clickable: .all
                ) { contract in
                    viewModel.handleFromContact(contract)
                } clickTo: { contract in
                    viewModel.handleToContact(contract)
                } clickSwap: {
                    viewModel.handleSwap()
                }

                MoveTokenView
                    .AccountView(
                        isFree: viewModel.isFreeMove
                    ) { _ in
                    }
            }

            Color.clear
                .frame(height: 8)

            VStack(spacing: 0) {
                InsufficientStorageToastView<MoveTokenViewModel>()
                    .environmentObject(self.viewModel)

                VPrimaryButton(
                    model: ButtonStyle.primary,
                    state: viewModel.buttonState,
                    action: {
                        log.debug("[Move] click button")
                        UIImpactFeedbackGenerator.impactOccurred(.medium)
                        viewModel.onNext()
                        UIApplication.shared.endEditing()
                    },
                    title: "move".localized
                )
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 18)
        .hideKeyboardWhenTappedAround()
        .environmentObject(viewModel)
        .applyRouteable(self)
        .tracedView(self)
    }

    func customViewDidDismiss() {
        MoveAssetsAction.shared.endBrowser()
    }

    // MARK: Private

    @StateObject
    private var viewModel: MoveTokenViewModel
}

// MARK: - MoveUserView

struct MoveUserView: View {
    var contact: Contact
    var isEVM: Bool = false
    var placeholder: String?
    var allowChoose: Bool = false
    var onClick: EmptyClosure?

    var address: String {
        contact.address ?? "0x"
    }

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                if let user = contact.user {
                    user.emoji.icon(size: 32)
                } else {
                    KFImage.url(URL(string: contact.avatar ?? ""))
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .cornerRadius(16)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(contact.user?.name ?? contact.name)
                            .foregroundColor(Color.LL.Neutrals.text)
                            .font(.inter(size: 14, weight: .semibold))

                        TagView(type: .evm)
                            .visibility(isEVM ? .visible : .gone)
                    }
                    .frame(alignment: .leading)

                    Text(address)
                        .foregroundColor(Color.Theme.Text.black3)
                        .font(.inter(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(alignment: .leading)
            }

            Spacer()
            Button {
                onClick?()
            } label: {
                Image("icon_arrow_bottom_16")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(8)
            }
            .visibility(allowChoose ? .visible : .gone)
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .background(Color.Theme.Background.white)
        .cornerRadius(16)
    }
}

// MARK: - MoveTokenView.AccountView

extension MoveTokenView {
    struct AccountView: View {
        @EnvironmentObject
        private var viewModel: MoveTokenViewModel

        @FocusState
        private var isAmountFocused: Bool
        var isFree = false
        var textDidChanged: (String) -> Void

        var body: some View {
            VStack(spacing: 12) {
                HStack {
                    TextField("", text: $viewModel.showBalance)
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .modifier(PlaceholderStyle(
                            showPlaceHolder: viewModel.showBalance.isEmpty,
                            placeholder: "0.00",
                            font: .inter(size: 30, weight: .w700),
                            color: Color.Theme.Text.black3
                        ))
                        .font(.inter(size: 30, weight: .w700))
                        .onChange(of: viewModel.showBalance) { text in
                            viewModel.inputTextDidChangeAction(text: text)
                        }
                        .focused($isAmountFocused)

                    switchMenuButton
                }

                HStack {
                    Text("balance".localized + ": ")
                        .font(.inter(size: 16))
                        .foregroundStyle(Color.Theme.Text.black3)

                    Text(viewModel.currentBalance)
                        .font(.inter(size: 16))
                        .foregroundStyle(Color.Theme.Text.black3)
                        .mockPlaceholder(viewModel.loadingBalance)

                    Spacer()

                    Button {
                        viewModel.maxAction()
                    } label: {
                        Text("max".localized)
                            .font(.inter(size: 12, weight: .w500))
                            .foregroundStyle(Color.Theme.Accent.grey)
                            .padding(.horizontal, 8)
                            .frame(height: 24)
                            .background(Color.Theme.Accent.grey.fixedOpacity())
                            .cornerRadius(16)
                    }
                    .mockPlaceholder(viewModel.loadingBalance)
                }

                Divider()
                    .foregroundStyle(Color.Theme.Line.stroke)
                    .visibility(viewModel.showFee ? .visible : .gone)
                MoveFeeView(isFree: isFree)
                    .visibility(viewModel.showFee ? .visible : .gone)
            }
            .padding(16)
            .backgroundFill(Color.Theme.BG.bg3)
            .cornerRadius(16)
        }

        @ViewBuilder
        var switchMenuButton: some View {
            Button(action: {
                guard let address = FWAddressDector.create(address: viewModel.fromContact.address)
                else {
                    return
                }

                Router.route(to: RouteMap.Wallet.selectMoveToken(address) { selectedToken in
                    viewModel.changeTokenModelAction(token: selectedToken)
                })
            }, label: {
                HStack(spacing: 4) {
                    KFImage.url(viewModel.token.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    Text(viewModel.token.symbol?.uppercased() ?? "?")
                        .font(.inter(size: 14, weight: .medium))
                        .foregroundStyle(Color.LL.Neutrals.text2)
                    Image("icon_arrow_bottom_16")
                        .foregroundColor(.LL.Neutrals.neutrals3)
                }
                .padding(8)
                .background(Color.Theme.Background.fill1)
                .cornerRadius(16)
            })
        }
    }
}

#Preview {
    MoveTokenView(
        tokenModel: TokenModel.mock(),
        isPresent: .constant(true)
    )
}
