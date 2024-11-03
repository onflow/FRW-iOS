//
//  MoveTokenView.swift
//  FRW
//
//  Created by cat on 2024/2/27.
//

import Kingfisher
import SwiftUI
import SwiftUIX

struct MoveTokenView: RouteableView, PresentActionDelegate {
    var changeHeight: (() -> Void)?
    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    @StateObject var viewModel: MoveTokenViewModel

    init(tokenModel: TokenModel, isPresent: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: MoveTokenViewModel(token: tokenModel, isPresent: isPresent))
    }

    var body: some View {
        GeometryReader { _ in
            VStack {
                ScrollView(showsIndicators: false) {
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
                            ContactRelationView(fromContact: viewModel.fromContact, toContact: viewModel.toContact)

                            MoveTokenView.AccountView(isFree: viewModel.fromContact.walletType == viewModel.toContact.walletType) { _ in
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(18)
                }
                Spacer()
            }
            .hideKeyboardWhenTappedAround()
            .backgroundFill(Color.Theme.BG.bg1)
            .cornerRadius([.topLeading, .topTrailing], 16)
            .environmentObject(viewModel)
            .edgesIgnoringSafeArea(.bottom)
            .overlay(alignment: .bottom) {
                VPrimaryButton(model: ButtonStyle.primary,
                               state: viewModel.buttonState,
                               action: {
                                   log.debug("[Move] click button")
                                   viewModel.onNext()
                                   UIApplication.shared.endEditing()
                               }, title: "move".localized)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 8)
            }
        }
        .applyRouteable(self)
    }

    func customViewDidDismiss() {
        MoveAssetsAction.shared.endBrowser()
    }
}

// MARK: - MoveUserView

struct MoveUserView: View {
    var contact: Contact
    var isEVM: Bool = false
    var placeholder: String?
    var allowChoose: Bool = false
    var onClick: EmptyClosure? = nil

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

                        EVMTagView()
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

// MARK: - MoveTokenView

extension MoveTokenView {
    struct AccountView: View {
        @EnvironmentObject private var viewModel: MoveTokenViewModel

        @FocusState private var isAmountFocused: Bool
        var isFree = false
        var textDidChanged: (String) -> Void

        var body: some View {
            VStack(spacing: 12) {
                HStack {
                    TextField("", text: $viewModel.showBalance)
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .modifier(PlaceholderStyle(showPlaceHolder: viewModel.showBalance.isEmpty,
                                                   placeholder: "0.00",
                                                   font: .inter(size: 30, weight: .w700),
                                                   color: Color.Theme.Text.black3))
                        .font(.inter(size: 30, weight: .w700))
                        .onChange(of: viewModel.showBalance) { text in
                            viewModel.inputTextDidChangeAction(text: text)
                        }
                        .focused($isAmountFocused)

                    switchMenuButton
                }

                HStack {
                    Text(viewModel.currentBalance)
                        .font(.inter(size: 16))
                        .foregroundStyle(Color.Theme.Text.black3)

                    Spacer()

                    Button {
                        viewModel.maxAction()
                    } label: {
                        Text("max".localized)
                            .font(.inter(size: 12, weight: .w500))
                            .foregroundStyle(Color.Theme.Accent.grey)
                            .padding(.horizontal, 5)
                            .frame(height: 24)
                            .background(Color.Theme.Accent.grey.fixedOpacity())
                            .cornerRadius(16)
                    }
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
                Router.route(to: RouteMap.Wallet.selectMoveToken(viewModel.token) { selectedToken in
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
                    Image("icon-arrow-bottom")
                        .foregroundColor(.LL.Neutrals.neutrals3)
                }
                .padding(8)
                .background(Color.Theme.Line.line)
                .cornerRadius(16)
            })
        }
    }
}

#Preview {
    MoveTokenView(tokenModel: TokenModel(name: "Flow", address: FlowNetworkModel(mainnet: "", testnet: "", crescendo: "", previewnet: ""), contractName: "", storagePath: FlowTokenStoragePath(balance: "100", vault: "a", receiver: ""), decimal: 30, icon: nil, symbol: nil, website: nil, evmAddress: nil, flowIdentifier: nil), isPresent: .constant(true))
//
}
