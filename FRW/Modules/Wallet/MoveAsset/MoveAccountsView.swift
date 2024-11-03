//
//  MoveAccountsView.swift
//  FRW
//
//  Created by cat on 2024/7/13.
//

import Kingfisher
import SwiftUI
import SwiftUIX

struct MoveAccountsView: RouteableView, PresentActionDelegate {
    var changeHeight: (() -> Void)?

    var title: String {
        return ""
    }

    @StateObject var viewModel: MoveAccountsViewModel

    init(viewModel: MoveAccountsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                HStack {
                    Text("choose_account".localized)
                        .font(.inter(size: 18, weight: .w700))
                        .foregroundStyle(Color.LL.Neutrals.text)
                        .frame(height: 28)
                    Spacer()

                    Button {
                        viewModel.closeAction()
                    } label: {
                        Image("icon_close_circle_gray")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(3)
                            .offset(x: -3)
                    }
                }
                .padding(.top, 18)

                Color.clear
                    .frame(height: 20)
                VStack {
                    ForEach(viewModel.list.indices, id: \.self) { index in
                        let model = viewModel.list[index]
                        let isSelected = viewModel.selectedAddr == model.address
                        MoveAccountsView.AccountCell(contact: model, isSelected: isSelected)
                            .onTapGesture {
                                viewModel.onSelect(contact: model)
                            }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
        .backgroundFill(Color.Theme.Background.grey)
        .cornerRadius([.topLeading, .topTrailing], 16)
        .applyRouteable(self)
        .ignoresSafeArea()
    }
}

extension MoveAccountsView {
    struct AccountCell: View {
        var contact: Contact
        var isSelected: Bool
        var name: String {
            contact.user?.name ?? contact.name
        }

        var address: String {
            contact.address ?? "0x"
        }

        var isEVM: Bool {
            guard let evmAdd = EVMAccountManager.shared.accounts.first?.showAddress else { return false }
            return evmAdd == address
        }

        var body: some View {
            HStack(spacing: 12) {
                if let user = contact.user {
                    user.emoji.icon(size: 40)
                } else {
                    KFImage.url(URL(string: contact.avatar ?? ""))
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .cornerRadius(20)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(name)
                            .foregroundColor(Color.LL.Neutrals.text)
                            .font(.inter(size: 12, weight: .semibold))

                        EVMTagView()
                            .visibility(isEVM ? .visible : .gone)
                    }
                    .frame(alignment: .leading)
                    .frame(height: 22)

                    Text(address)
                        .foregroundColor(Color.Theme.Text.black3)
                        .font(.inter(size: 12))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(height: 16)
                }
                .frame(alignment: .leading)

                Spacer()

                Image("evm_check_1")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .visibility(isSelected ? .visible : .gone)
            }
            .padding(16)
            .background(Color.Theme.Background.white)
            .cornerRadius(16)
        }
    }
}

class MoveAccountsViewModel: ObservableObject {
    @Published var list: [Contact] = []
    var selectedAddr: String
    var callback: (Contact?) -> Void

    init(selected address: String, callback: @escaping (Contact?) -> Void) {
        selectedAddr = address
        self.callback = callback
        let currentAddr = WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress()

        let isChild = ChildAccountManager.shared.selectedChildAccount != nil
        let isEVM = EVMAccountManager.shared.selectedAccount != nil

        if let primaryAddr = WalletManager.shared.getPrimaryWalletAddressOrCustomWatchAddress(), currentAddr != primaryAddr {
            let user = WalletManager.shared.walletAccount.readInfo(at: primaryAddr)
            let contact = Contact(address: primaryAddr, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .flow)
            list.append(contact)
        }

        EVMAccountManager.shared.accounts.forEach { account in
            
            if currentAddr != account.showAddress {
                let user = WalletManager.shared.walletAccount.readInfo(at: account.showAddress)
                let contact = Contact(address: account.showAddress, avatar: nil, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: user.name, user: user, walletType: .evm)
                list.append(contact)
            }
        }

        ChildAccountManager.shared.childAccounts.forEach { account in
            
            if currentAddr != account.showAddress {
                let contact = Contact(address: account.showAddress, avatar: account.showIcon, contactName: nil, contactType: .user, domain: nil, id: UUID().hashValue, username: account.showName, walletType: .link)
                list.append(contact)
            }
        }
    }

    func onSelect(contact: Contact) {
        callback(contact)
        closeAction()
    }

    func closeAction() {
        Router.dismiss()
    }
}

#Preview {
    MoveAccountsView(viewModel: MoveAccountsViewModel(selected: "", callback: { _ in

    }))
}
