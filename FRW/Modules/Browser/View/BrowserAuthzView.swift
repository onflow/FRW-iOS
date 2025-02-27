//
//  BrowserAuthzView.swift
//  Flow Wallet
//
//  Created by Selina on 6/9/2022.
//

import Highlightr
import Kingfisher
import SwiftUI

// MARK: - BrowserAuthzView

struct BrowserAuthzView: View {
    // MARK: Lifecycle

    init(vm: BrowserAuthzViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    // MARK: Internal

    enum Selection: String, CaseIterable, Identifiable {
        case cadence
        case arguments

        // MARK: Internal

        var id: Self { self }
    }

    @StateObject
    var vm: BrowserAuthzViewModel

    @State
    var selection: Selection = .cadence

    var body: some View {
        ZStack {
            normalView.visibility(vm.isScriptShowing ? .invisible : .visible)
            scriptView.visibility(vm.isScriptShowing ? .visible : .invisible)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(Color.Theme.BG.bg1)
    }

    var normalView: some View {
        VStack(spacing: 10) {
            titleView

//            Divider()
//                .foregroundColor(.LL.Neutrals.neutrals8)

            if let template = vm.template {
                verifiedView
                    .transition(AnyTransition.move(edge: .top).combined(with: .opacity))

                VStack {
                    if let title = template.data.messages?.title?.i18N?.enUS {
                        Text(title)
                            .font(.LL.body)
                            .fontWeight(.bold)
                            .foregroundColor(Color.Theme.Text.black8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let description = template.data.messages?.messagesDescription?.i18N?.enUS {
                        Text(description)
                            .font(.LL.footnote)
                            .foregroundColor(Color.Theme.Text.black3)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .background(.Theme.BG.bg2)
                .cornerRadius(12)
                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
            } else {
                feeView
                    .padding(.top, 12)
            }
            scriptButton
                .padding(.top, 8)
                .visibility(vm.showEvmCard ? .gone : .visible)
            ScrollView {
                evmCard
                    .visibility(vm.showEvmCard ? .visible : .gone)
            }

            Spacer()

            actionView
        }
        .if(let: vm.template) {
            $0.animation(.spring(), value: $1)
        }
        .task {
            vm.checkTemplate()
            vm.formatCode()
            vm.formatArguments()
        }
        .preferredColorScheme(.dark)
        .padding(.all, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var verifiedView: some View {
        HStack(alignment: .center) {
            Image(systemName: "checkmark.shield.fill")
                .font(.LL.body)
            Text("This transaction is verified")
                .font(.LL.body)
                .fontWeight(.semibold)
        }
        .foregroundColor(.LL.success)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .backgroundFill(.LL.success.opacity(0.16))
        .cornerRadius(12)
    }

    var titleView: some View {
        HStack(spacing: 18) {
            KFImage.url(URL(string: vm.logo ?? ""))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("browser_transaction_request_from".localized)
                    .font(.inter(size: 14))
                    .foregroundColor(.Theme.Text.black3)

                Text(vm.title)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(.Theme.Text.black)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var feeView: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Image("icon-fee")

                Text("browser_transaction_fee".localized)
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(.Theme.Text.black8)
                    .lineLimit(1)

                Spacer()

                Text("0.001")
                    .font(.inter(size: 14))
                    .strikethrough()
                    .foregroundColor(.Theme.Text.text4)
                    .lineLimit(1)
                    .visibility(RemoteConfigManager.shared.freeGasEnabled ? .visible : .gone)

                Text(RemoteConfigManager.shared.freeGasEnabled ? "0.00" : "0.001")
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(.Theme.Text.text1)
                    .lineLimit(1)

                Image("Flow")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .frame(height: 20)

            HStack {
                Spacer()
                Text("Covered by Flow Wallet".localized)
                    .font(.inter(size: 12))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.Theme.Text.text4)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            .visibility(RemoteConfigManager.shared.freeGasEnabled ? .visible : .gone)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(.Theme.BG.bg2)
        .cornerRadius(16)
    }

    var scriptButton: some View {
        Button {
            vm.changeScriptViewShowingAction(true)
        } label: {
            HStack(spacing: 12) {
                Image("icon-script")

                Text("browser_script".localized)
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundColor(.Theme.Text.black8)
                    .lineLimit(1)

                Spacer()

                Image("icon-search-arrow")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.Theme.Accent.green)
                    .frame(width: 12, height: 12)
            }
            .frame(height: 46)
            .padding(.horizontal, 18)
            .background(.Theme.BG.bg2)
            .cornerRadius(12)
        }
    }

    var actionView: some View {
        VStack(spacing: 0) {
            InsufficientStorageToastView<BrowserAuthzViewModel>()
                .environmentObject(self.vm)

            WalletSendButtonView(allowEnable: .constant(true)) {
                vm.didChooseAction(true)
            }
        }
    }

    var scriptView: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    Button {
                        vm.changeScriptViewShowingAction(false)
                    } label: {
                        Image("icon-back-arrow-grey")
                            .frame(height: 72)
                            .contentShape(Rectangle())
                    }

                    Spacer()
                }

                Text("browser_script_title".localized)
                    .font(.inter(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#E8E8E8"))
            }
            .frame(height: 72)

            Picker("Cadence", selection: $selection) {
                ForEach(BrowserAuthzView.Selection.allCases) { topping in
                    Text(topping.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                Text(attributeString())
                    .font(.inter(
                        size: selection == .cadence ? 8 : 14,
                        weight: selection == .cadence ? .light : .regular
                    ))
                    .foregroundColor(Color(hex: "#B2B2B2"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.all, 18)
                    .background(Color(hex: "#313131"))
                    .cornerRadius(12)
            }
        }
        .preferredColorScheme(.dark)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(.Theme.Background.white)
        .transition(.move(edge: .trailing))
    }

    var evmCard: some View {
        VStack(spacing: 8) {
            infoView
            decodedDataView
            callDataView
                .visibility((vm.callData != nil) ? .visible : .gone)
        }
    }

    var infoView: some View {
        card(with: vm.infoList)
    }

    var callDataView: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Call Data".localized)
                    .font(.inter(size: 14, weight: .semibold))
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()

                Button {
                    UIPasteboard.general.string = vm.callData ?? ""
                    HUD.success(title: "copied".localized)

                } label: {
                    Image("icon_copy")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color.Theme.Accent.grey)
                        .frame(width: 20, height: 20)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
            }

            Text(vm.callData ?? "")
                .font(.inter(size: 14))
                .lineLimit(4)
                .foregroundStyle(Color.Theme.Text.black8)
                .padding(16)
                .background(Color.Theme.BG.bg1)
                .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.Theme.BG.bg2)
        .cornerRadius(16)
    }

    var decodedDataView: some View {
        VStack(spacing: 8) {
            ForEach(0 ..< vm.decodedDataList.count, id: \.self) { index in
                let list = vm.decodedDataList[index]
                card(with: list)
            }
        }
    }

    func attributeString() -> AttributedString {
        switch selection {
        case .cadence:
            vm.cadenceFormatted ?? AttributedString(vm.cadence.trim())
        case .arguments:
            vm.argumentsFormatted ?? AttributedString(vm.arguments?.jsonPrettyPrint()?.trim() ?? "")
        }
    }

    func card(with list: [FormItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(0 ..< list.count, id: \.self) { index in
                let model = list[index]
                BrowserAuthzView.Card(model: model)
                if index < list.count - 1 {
                    Divider()
                        .foregroundStyle(Color.Theme.Line.line)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.Theme.BG.bg2)
        .cornerRadius(16)
    }
}

// MARK: BrowserAuthzView.Card

extension BrowserAuthzView {
    struct Card: View {
        var model: FormItem

        var body: some View {
            VStack {
                titleView
                contentView()
            }
        }

        var titleView: some View {
            HStack(spacing: 4) {
                Text(model.value.title.uppercasedAllFirstLetter())
                    .font(.inter(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.Theme.Text.black8)
                Spacer()
                Text(model.value.content)
                    .font(.inter(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(Color.Theme.Text.black)
                    .visibility(model.value.contentIsArrayOrDic ? .gone : .visible)
                Image("check_circle_border")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .visibility(model.isCheck ? .visible : .gone)
            }
            .frame(height: 20)
            .padding(.vertical, 8)
        }

        func contentView() -> some View {
            VStack {
                if let subValue = model.value.subValue {
                    if case let .object(dictionary) = subValue {
                        let keys = dictionary.keys.map { $0 }.sorted()
                        ForEach(0 ..< keys.count, id: \.self) { index in
                            let key = keys[index]
                            let value = dictionary[key]?.toString() ?? ""
                            HStack(spacing: 12) {
                                Text(key.uppercasedFirstLetter())
                                    .font(.inter(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                    .foregroundStyle(Color.Theme.Text.black3)
                                Spacer()
                                Text(value)
                                    .font(.inter(size: 14, weight: .semibold))
                                    .truncationMode(.middle)
                                    .lineLimit(1)
                                    .foregroundStyle(Color.Theme.Text.black)
                            }
                            .frame(height: 20)
                        }
                    }
                    if case let .array(array) = subValue {
                        VStack {
                            ForEach(0 ..< array.count, id: \.self) { index in
                                let value = array[index]
                                innerCard(item: value)
                            }
                        }
                    }
                }
            }
        }

        func innerCard(item: JSONValue) -> some View {
            VStack {
                HStack(spacing: 12) {
                    Text(item.title)
                        .font(.inter(size: 14))
                        .lineLimit(1)
                        .foregroundStyle(Color.Theme.Text.text4)
                    Spacer()
                    Text(item.content)
                        .font(.inter(size: 14))
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .foregroundStyle(Color.Theme.Text.black8)
                }
                .frame(height: 20)
            }
        }
    }
}

// MARK: - BrowserAuthzView_Previews

struct BrowserAuthzView_Previews: PreviewProvider {
    static let vm = BrowserAuthzViewModel(
        title: "This is title",
        url: "This is URL",
        logo: "https://lilico.app/logo.png",
        cadence: """
        import FungibleToken from 0x9a0766d93b6608b7
        transaction(amount: UFix64, to: Address) {
        let vault: @FungibleToken.Vault
        prepare(signer: AuthAccount) {
        self.vault <- signer
        .borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!
        .withdraw(amount: amount)
        }
        execute {
        getAccount(to)
        .getCapability(/public/flowTokenReceiver)!
        .borrow<&{FungibleToken.Receiver}>()!
        .deposit(from: <-self.vault)
        }
        }
        """
    ) { _ in }

    static var previews: some View {
        BrowserAuthzView(vm: vm)
    }
}
