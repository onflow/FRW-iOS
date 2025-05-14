//
//  ImportAccountsView.swift
//  FRW
//
//  Created by cat on 2024/8/19.
//

import Flow
import SwiftUI
import SwiftUIX

// MARK: - ImportAccountsViewModel

class ImportAccountsViewModel: ObservableObject {
    // MARK: Lifecycle

    init(list: [Flow.Account], onSelectAddress: @escaping (Flow.Account) -> Void) {
        self.list = list
        self.onSelectAddress = onSelectAddress
    }

    // MARK: Internal

    var list: [Flow.Account] = []
    var onSelectAddress: (Flow.Account) -> Void
}

// MARK: - ImportAccountsView

struct ImportAccountsView: RouteableView, PresentActionDelegate {
    // MARK: Lifecycle

    init(viewModel: ImportAccountsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    var changeHeight: (() -> Void)?

    @StateObject
    var viewModel: ImportAccountsViewModel

    var title: String {
        ""
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .center) {
                    Spacer()
                    Text(headerTitle)
                        .font(.inter(size: 24, weight: .bold))
                        .foregroundStyle(
                            viewModel.list.isEmpty ? Color.Theme.Accent.orange : Color
                                .Theme.Accent.green
                        )
                    Spacer()
                }

                Button {
                    onClose()
                } label: {
                    Image("icon_close_circle_gray")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(4)
                        .offset(y: -6)
                }
            }
            .frame(height: 40)
            .padding(.top, 18)

            Text("choose_account_import".localized)
                .font(.inter(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.Text.black3)
                .padding(.top, 20)
                .visibility(viewModel.list.isEmpty ? .gone : .visible)

            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(viewModel.list.indices, id: \.self) { index in
                        let account = viewModel.list[index]
                        let isSelected = (account.address.hex == selectedAccount?.address.hex)
                        ImportAccountsView
                            .Item(account: account, isSelected: isSelected) { itemAccount in
                                self.selectedAccount = itemAccount
                            }
                    }
                }
            }
            .padding(.top, 28)
            .visibility(viewModel.list.isEmpty ? .gone : .visible)

            Spacer()
            Text("import_no_account_found".localized)
                .font(.inter(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Theme.Text.black)
                .padding(.horizontal, 27)
                .visibility(viewModel.list.isEmpty ? .visible : .gone)

            Spacer()

            Button {
                if let account = selectedAccount {
                    onClose()
                    viewModel.onSelectAddress(account)
                }
            } label: {
                Text(buttonTitle())
                    .font(.inter(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundColor(Color.LL.frontColor)
                    .background(selectedAccount == nil ? Color.LL.disable : Color.LL.rebackground)
                    .cornerRadius(16)
            }
            .disabled(selectedAccount == nil)
            .padding(.bottom, 42)
        }
        .padding(.horizontal, 18)
        .backgroundFill(.Theme.Background.bg2)
        .cornerRadius([.topLeading, .topTrailing], 16)
        .applyRouteable(self)
        .tracedView(self)
        .ignoresSafeArea()
    }

    var headerTitle: String {
        if viewModel.list.isEmpty {
            return "no_account_found".localized
        }
        return "x_account_found_title".localized("\(viewModel.list.count)")
    }

    func onClose() {
        Router.dismiss()
    }

    // MARK: Private

    @State
    private var selectedAccount: Flow.Account?

    private func buttonTitle() -> String {
        if selectedAccount == nil {
            return "import_btn_text".localized.uppercasedFirstLetter()
        }
        return "import_x_wallet".localized("1")
    }
}

// MARK: ImportAccountsView.Item

extension ImportAccountsView {
    struct Item: View {
        let account: Flow.Account
        var isSelected: Bool = false
        var onClick: (Flow.Account) -> Void

        var body: some View {
            HStack {
                Text(account.address.hex)
                    .font(.inter(size: 14, weight: isSelected ? .semibold : .regular))
                    .truncationMode(.middle)
                    .lineLimit(1)
                    .foregroundStyle(Color.Theme.Text.black)

                Spacer()

                Image(isSelected ? "icon_check_rounde_1" : "icon_check_rounde_0")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .padding(.horizontal, 24)
            .frame(height: 56)
            .contentShape(Rectangle())
            .background(isSelected ? Color.Theme.Background.pureWhite : .clear)
            .onTapGesture {
                onClick(account)
            }
            .cornerRadius(16)
        }
    }
}

#Preview {
    ImportAccountsView(viewModel: ImportAccountsViewModel(list: [], onSelectAddress: { _ in

    }))
}
