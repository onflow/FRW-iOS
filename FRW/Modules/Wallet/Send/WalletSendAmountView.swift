//
//  WalletSendAmountView.swift
//  Flow Wallet
//
//  Created by Selina on 12/7/2022.
//

import Combine
import Kingfisher
import SwiftUI
import SwiftUIX

// MARK: - WalletSendAmountView

// struct WalletSendAmountView_Previews: PreviewProvider {
//    static var previews: some View {
////        WalletSendAmountView()
////        WalletSendAmountView.SendConfirmProgressView()
//    }
// }

struct WalletSendAmountView: RouteableView {
    // MARK: Lifecycle

    init(target: Contact, token: TokenModel) {
        _vm = StateObject(wrappedValue: WalletSendAmountViewModel(target: target, token: token))
    }

    // MARK: Internal

    var title: String {
        "send_to".localized
    }

    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        .large
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                targetView
                transferInputContainerView
                amountBalanceView

                Spacer()

                nextActionView
            }
        }
        .onAppear {
            isAmountFocused = true
        }
        .onDisappear {
            isAmountFocused = false
        }
        .hideKeyboardWhenTappedAround()
        //        .interactiveDismissDisabled()
        .buttonStyle(.plain)
        .backgroundFill(Color.LL.background)
        .halfSheet(showSheet: $vm.showConfirmView, autoResizing: true, backgroundColor: Color.LL.Neutrals.background, sheetView: {
            SendConfirmView()
                .environmentObject(vm)
        })
        .applyRouteable(self)
        .environmentObject(vm)
    }

    var targetView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 15) {
                // avatar
                ZStack {
                    if vm.targetContact.user?.emoji != nil {
                        vm.targetContact.user?.emoji.icon(size: 44)
                    } else if let avatar = vm.targetContact.avatar?.convertedAvatarString(),
                              avatar.isEmpty == false
                    {
                        KFImage.url(URL(string: avatar))
                            .placeholder {
                                Image("placeholder")
                                    .resizable()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                    } else if vm.targetContact.needShowLocalAvatar {
                        if let localAvatar = vm.targetContact.localAvatar {
                            Image(vm.targetContact.localAvatar ?? "")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                        } else {
                            Text(String((vm.targetContact.contactName?.first ?? "A").uppercased()))
                                .foregroundColor(.Theme.Accent.grey)
                                .font(.inter(size: 24, weight: .semibold))
                        }

                    } else {
                        if let contactType = vm.targetContact.contactType,
                           let contactName = vm.targetContact.contactName, contactType == .external,
                           contactName.isFlowOrEVMAddress
                        {
                            Text("0x")
                                .foregroundColor(.Theme.Accent.grey)
                                .font(.inter(size: 24, weight: .semibold))
                        } else {
                            Text(String((vm.targetContact.contactName?.first ?? "A").uppercased()))
                                .foregroundColor(.Theme.Accent.grey)
                                .font(.inter(size: 24, weight: .semibold))
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .background(.Theme.Accent.grey.opacity(0.16))
                .clipShape(Circle())

                // text
                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.targetContact.displayName)
                        .foregroundColor(.LL.Neutrals.text)
                        .font(.inter(size: 14, weight: .bold))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Text(vm.targetContact.address ?? "no address")
                        .foregroundColor(.LL.Neutrals.note)
                        .font(.inter(size: 14, weight: .regular))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    Router.pop()
                } label: {
                    Image(systemName: .delete)
                        .foregroundColor(.LL.Neutrals.note)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 73)
            .background(.LL.bgForIcon)
            .cornerRadius(16)
            .padding(.horizontal, 18)
            CalloutView(
                corners: [.bottomLeading, .bottomTrailing],
                content: "wallet_send_token_empty".localized
            )
            .padding(.horizontal, 30)
            .visibility(vm.isValidToken ? .gone : .visible)
            .transition(.move(edge: .top))
        }
    }

    var transferInputContainerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("transfer_amount".localized)
                .foregroundColor(.LL.Neutrals.note)
                .font(.inter(size: 14, weight: .medium))
                .padding(.bottom, 9)

            VStack(spacing: 34) {
                HStack(spacing: 8) {
                    // dollar type string
                    Text(CurrencyCache.cache.currencySymbol)
                        .foregroundColor(.LL.Neutrals.note)
                        .font(.inter(size: 16, weight: .bold))
                        .visibility(vm.exchangeType == .dollar ? .visible : .gone)

                    switchMenuButton
                        .visibility(vm.exchangeType == .token ? .visible : .gone)

                    // input view
                    TextField("", text: $vm.inputText)
                        .keyboardType(.decimalPad)
                        .disableAutocorrection(true)
                        .modifier(PlaceholderStyle(
                            showPlaceHolder: vm.inputText.isEmpty,
                            placeholder: "enter_amount".localized,
                            font: .inter(size: 14, weight: .medium),
                            color: Color.LL.Neutrals.note
                        ))
                        .font(.inter(size: 20, weight: .medium))
                        .onChange(of: vm.inputText) { text in
                            withAnimation {
                                let decimalSeparator = NumberFormatter().decimalSeparator ?? "."
                                if let dotIndex = text.firstIndex(of: Character(decimalSeparator)) {
                                    let decimals = text[text.index(after: dotIndex)...].count
                                    if decimals > vm.token.precision {
                                        vm.inputText = String(text.prefix(text.distance(from: text.startIndex, to: dotIndex) + vm.token.decimal + 1))
                                    }
                                }
                                vm.inputTextDidChangeAction(text: vm.inputText)
                            }
                        }
                        .focused($isAmountFocused)

                    // max btn
                    Button {
                        vm.maxAction()
                    } label: {
                        Text("max".localized)
                            .foregroundColor(.LL.Button.color)
                            .font(.inter(size: 14, weight: .medium))
                            .padding(.horizontal, 8)
                            .frame(height: 26)
                            .background(.LL.Neutrals.neutrals10)
                            .cornerRadius(16)
                    }
                }

                // rate container
                HStack {
                    Text("≈")
                        .foregroundColor(.LL.Neutrals.note)
                        .font(.inter(size: 16, weight: .medium))

                    Text(CurrencyCache.cache.currencySymbol)
                        .foregroundColor(.LL.Neutrals.note)
                        .font(.inter(size: 16, weight: .medium))
                        .visibility(vm.exchangeType == .token ? .visible : .gone)

                    KFImage.url(vm.token.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())
                        .visibility(vm.exchangeType == .dollar ? .visible : .gone)

                    Text(
                        vm.exchangeType == .token ? vm.inputDollarNum.formatCurrencyStringForDisplay() : vm
                            .inputTokenNum.formatCurrencyStringForDisplay()
                    )
                    .foregroundColor(.LL.Neutrals.note)
                    .font(.inter(size: 16, weight: .medium))
                    .lineLimit(1)

                    Button {
                        vm.toggleExchangeTypeAction()
                    } label: {
                        Image("icon-exchange").renderingMode(.template)
                            .foregroundColor(.LL.Neutrals.text)
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 121)
            .background(.LL.bgForIcon)
            .cornerRadius(16)
            .zIndex(1)

            errorTipsView
        }
        .padding(.horizontal, 18)
    }

    var switchMenuButton: some View {
        Menu {
            ForEach(WalletManager.shared.activatedCoins) { token in
                Button {
                    vm.changeTokenModelAction(token: token)
                } label: {
                    KFImage.url(token.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    Text(token.name)
                }
            }
        } label: {
            HStack(spacing: 8) {
                KFImage.url(vm.token.iconURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                Image("icon-arrow-bottom")
                    .foregroundColor(.LL.Neutrals.neutrals3)
            }
        }
    }

    var errorTipsView: some View {
        VStack {
            Spacer()

            HStack(spacing: 9) {
                Image(systemName: .error)
                    .foregroundColor(Color(hex: "#C44536"))

                Text(vm.errorType.desc)
                    .foregroundColor(.LL.Neutrals.note)
                    .font(.inter(size: 12, weight: .regular))
            }
            .padding(.bottom, 12)
            .padding(.horizontal, 13)
        }
        .frame(height: 61)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#C44536").opacity(0.08))
        .cornerRadius(16)
        .padding(.top, -23)
        .padding(.horizontal, 5)
        .visibility(vm.errorType == .none ? .gone : .visible)
        .transition(.move(edge: .top))
    }

    var amountBalanceView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("amount_balance".localized)
                .foregroundColor(.LL.Neutrals.note)
                .font(.inter(size: 14, weight: .medium))
                .padding(.bottom, 9)

            HStack {
                KFImage.url(vm.token.iconURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                Text(
                    "\(vm.amountBalance.formatCurrencyStringForDisplay()) \(vm.token.symbol?.uppercased() ?? "?")"
                )
                .foregroundColor(.LL.Neutrals.text)
                .font(.inter(size: 14, weight: .medium))

                Text(
                    "≈ \(CurrencyCache.cache.currencySymbol) \(vm.amountBalanceAsDollar.formatCurrencyStringForDisplay(considerCustomCurrency: true))"
                )
                .foregroundColor(.LL.Neutrals.text)
                .font(.inter(size: 14, weight: .medium))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
    }

    var nextActionView: some View {
        VStack(spacing: 0) {
            InsufficientStorageToastView<WalletSendAmountViewModel>()
                .environmentObject(self.vm)
                .padding(.horizontal, 22)

            Button {
                isAmountFocused = false
                vm.nextAction()
            } label: {
                ZStack {
                    Text("next".localized)
                        .foregroundColor(Color.LL.Button.text)
                        .font(.inter(size: 14, weight: .bold))
                }
                .frame(height: 54)
                .frame(maxWidth: .infinity)
                .background(Color.LL.Button.color)
                .cornerRadius(16)
                .padding(.horizontal, 18)
            }
            .disabled(!vm.isReadyForSend)
        }
    }

    // MARK: Private

    @StateObject
    private var vm: WalletSendAmountViewModel

    @FocusState
    private var isAmountFocused: Bool
}

extension WalletSendAmountView {
    struct SendConfirmView: View {
        @EnvironmentObject
        private var vm: WalletSendAmountViewModel

        var fromTargetContent: Contact {
            if let account = EVMAccountManager.shared.selectedAccount {
                let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
                let contact = Contact(
                    address: account.showAddress,
                    avatar: nil,
                    contactName: user.name,
                    contactType: .user,
                    domain: nil,
                    id: UUID().hashValue,
                    username: account.showName,
                    user: user
                )
                return contact
            } else if let account = ChildAccountManager.shared.selectedChildAccount {
                let contact = Contact(
                    address: account.showAddress,
                    avatar: account.icon,
                    contactName: account.aName,
                    contactType: .user,
                    domain: nil,
                    id: UUID().hashValue,
                    username: account.showName
                )
                return contact
            } else {
                return UserManager.shared.userInfo!.toContactWithCurrentUserAddress()
            }
        }

        var body: some View {
            VStack {
                SheetHeaderView(title: "confirmation".localized)

                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        fromToView
                        WalletSendAmountView.SendConfirmProgressView()
                            .padding(.bottom, 37)
                    }

                    amountDetailView
                        .padding(.top, 37)

                    Spacer()

                    sendButton
                        .padding(.bottom, 10)
                }
                .padding(.horizontal, 28)
            }
        }

        var fromToView: some View {
            HStack(spacing: 16) {
                contactView(contact: fromTargetContent)
                Spacer()
                contactView(contact: vm.targetContact)
            }
        }

        var amountDetailView: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text("amount_confirmation".localized)
                    .foregroundColor(.LL.Neutrals.note)
                    .font(.inter(size: 14, weight: .medium))

                HStack(spacing: 0) {
                    KFImage.url(vm.token.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                    Text(vm.token.name)
                        .foregroundColor(.LL.Neutrals.text)
                        .font(.inter(size: 18, weight: .medium))
                        .padding(.leading, 8)

                    Spacer()

                    Text(String(format: "%.\(vm.token.decimal)f", vm.inputTokenNum) + " \(vm.token.name.uppercased())")
                        .foregroundColor(.LL.Neutrals.text)
                        .font(.inter(size: 20, weight: .semibold))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(height: 32)
                .padding(.top, 25)

                HStack {
                    Spacer()

                    Text(
                        "\(CurrencyCache.cache.currentCurrency.rawValue) \(CurrencyCache.cache.currencySymbol) \(vm.inputDollarNum.formatCurrencyStringForDisplay())"
                    )
                    .foregroundColor(.LL.Neutrals.neutrals8)
                    .font(.inter(size: 14, weight: .medium))
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(Color.LL.bgForIcon)
            .cornerRadius(16)
        }

        var sendButton: some View {
            WalletSendButtonView(allowEnable: $vm.isEmptyTransation) {
                if vm.isEmptyTransation {
                    vm.sendWithVerifyAction()
                }
            }
        }

        func contactView(contact: Contact) -> some View {
            VStack(spacing: 5) {
                // avatar
                ZStack {
                    if contact.user?.emoji != nil {
                        contact.user?.emoji.icon(size: 44)
                    } else if let avatar = contact.avatar?.convertedAvatarString(),
                              avatar.isEmpty == false
                    {
                        KFImage.url(URL(string: avatar))
                            .placeholder {
                                Image("placeholder")
                                    .resizable()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                    } else if contact.needShowLocalAvatar {
                        if let localAvatar = contact.localAvatar {
                            Image(localAvatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                        } else {
                            Text(String((contact.contactName?.first ?? "A").uppercased()))
                                .foregroundColor(.Theme.Accent.grey)
                                .font(.inter(size: 24, weight: .semibold))
                        }

                    } else {
                        if let contactType = vm.targetContact.contactType,
                           let contactName = vm.targetContact.contactName, contactType == .external,
                           contactName.isFlowOrEVMAddress
                        {
                            Text("0x")
                                .foregroundColor(.Theme.Accent.grey)
                                .font(.inter(size: 24, weight: .semibold))
                        } else {
                            Text(String((vm.targetContact.contactName?.first ?? "A").uppercased()))
                                .foregroundColor(.Theme.Accent.grey)
                                .font(.inter(size: 24, weight: .semibold))
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .background(.Theme.Accent.grey.opacity(0.16))
                .clipShape(Circle())

                // contact name
                Text(contact.displayName)
                    .foregroundColor(.LL.Neutrals.neutrals1)
                    .font(.inter(size: 14, weight: .semibold))
                    .lineLimit(1)

                // address
                Text(contact.address ?? "0x")
                    .foregroundColor(.LL.Neutrals.note)
                    .font(.inter(size: 12, weight: .regular))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    struct SendConfirmProgressView: View {
        // MARK: Internal

        var body: some View {
            HStack(spacing: 12) {
                ForEach(0 ..< totalNum, id: \.self) { index in
                    if step == index {
                        Image("icon-right-arrow-1")
                            .renderingMode(.template)
                            .foregroundColor(.LL.Primary.salmonPrimary)
                    } else {
                        switch index {
                        case 0:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.25)
                        case 1:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.35)
                        case 2:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.50)
                        case 3:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.65)
                        case 4:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.80)
                        case 5:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary).opacity(0.95)
                        default:
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(.LL.Primary.salmonPrimary)
                        }
                    }
                }
            }
            .onReceive(timer) { _ in
                DispatchQueue.main.async {
                    if step < totalNum - 1 {
                        step += 1
                    } else {
                        step = 0
                    }
                }
            }
        }

        // MARK: Private

        private let totalNum: Int = 7
        @State
        private var step: Int = 0
        private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
}
