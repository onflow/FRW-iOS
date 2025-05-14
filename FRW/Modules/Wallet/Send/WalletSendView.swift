//
//  WalletSendView.swift
//  Flow Wallet
//
//  Created by Selina on 6/7/2022.
//

import SwiftUI
import SwiftUIPager
import SwiftUIX

// MARK: - WalletSendView.WalletSendViewSelectTargetCallback

// struct WalletSendView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            WalletSendView()
//        }
//    }
// }

extension WalletSendView {
    typealias WalletSendViewSelectTargetCallback = (Contact) -> Void
}

// MARK: - WalletSendView

struct WalletSendView: RouteableView {
    // MARK: Lifecycle

    init(address: String = "", callback: WalletSendView.WalletSendViewSelectTargetCallback? = nil) {
        let vm = WalletSendViewModel(selectCallback: callback)
        vm.searchText = address
        _vm = StateObject(wrappedValue: vm)
    }

    // MARK: Internal

    var title: String {
        "send_to".localized
    }

    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        .large
    }

    var body: some View {
        VStack(spacing: 32) {
            searchBar

            ZStack {
                VStack(spacing: 0) {
                    switchBar
                    contentView
                }

                searchContainerView
                    .visibility(vm.status == .normal ? .gone : .visible)
            }
        }
//        .interactiveDismissDisabled()
        .buttonStyle(.plain)
        .backgroundFill(Color.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    var switchBar: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        vm.changeTabTypeAction(type: .accounts)
                    } label: {
                        SwitchButton(
                            icon: "profile-tab",
                            title: "my_accounts".localized,
                            isSelected: vm.tabType == .accounts
                        )
                        .contentShape(Rectangle())
                    }

                    Button {
                        vm.changeTabTypeAction(type: .recent)
                    } label: {
                        SwitchButton(
                            icon: "icon-recent",
                            title: "recent".localized,
                            isSelected: vm.tabType == .recent
                        )
                        .contentShape(Rectangle())
                    }

                    Button {
                        vm.changeTabTypeAction(type: .addressBook)
                    } label: {
                        SwitchButton(
                            icon: "icon-addressbook",
                            title: "address_book".localized,
                            isSelected: vm.tabType == .addressBook
                        )
                        .contentShape(Rectangle())
                    }
                }

                // indicator
                let widthPerTab = geo.size.width / CGFloat(tabCount)
                Color.Theme.Text.black1
                    .frame(width: widthPerTab, height: 2)
                    .padding(.leading, widthPerTab * CGFloat(vm.tabType.rawValue))
                    .padding(.bottom, 16)
            }
        }
        .frame(height: 70)
    }

    var contentView: some View {
        ZStack {
            Pager(page: vm.page, data: TabType.allCases, id: \.self) { type in
                switch type {
                case .recent:
                    recentContainerView
                case .addressBook:
                    addressBookContainerView
                case .accounts:
                    accountView
                }
            }
            .onPageChanged { newIndex in
                vm.changeTabTypeAction(type: TabType(rawValue: newIndex) ?? .recent)
            }
        }
    }

    func backButtonAction() {
        Router.dismiss()
    }

    // MARK: Private

    @StateObject
    private var vm: WalletSendViewModel
    @FocusState
    private var searchIsFocused: Bool
}

// MARK: - Search

extension WalletSendView {
    var searchBar: some View {
        HStack(spacing: 8) {
            Image("icon-search")
                .renderingMode(.template)
                .foregroundStyle(Color.Theme.Text.black8)
            TextField("", text: $vm.searchText)
                .disableAutocorrection(true)
                .modifier(PlaceholderStyle(
                    showPlaceHolder: vm.searchText.isEmpty,
                    placeholder: "send_search_placeholder".localized,
                    font: .inter(size: 14, weight: .medium),
                    color: Color.Theme.Text.black3
                ))
                .submitLabel(.search)
                .onChange(of: vm.searchText) { st in
                    vm.searchTextDidChangeAction(text: st)
                }
                .onSubmit {
                    vm.searchCommitAction()
                }
                .focused($searchIsFocused)
            Spacer()

            Button {
                vm.scan()
            } label: {
                Image("icon-wallet-scan")
                    .renderingMode(.template)
                    .foregroundColor(.Theme.Accent.grey)
            }
        }
        .frame(height: 52)
        .padding(.horizontal, 16)
        .background(.LL.Neutrals.background)
        .cornerRadius(16)
        .padding(.horizontal, 18)
    }

    var searchContainerView: some View {
        VStack {
            searchLocalView
                .visibility(vm.status == .prepareSearching ? .visible : .gone)

            errorMsgView
                .visibility(vm.status == .error ? .visible : .gone)

            searchingView
                .visibility(vm.status == .searching ? .visible : .gone)

            remoteSearchListView
                .visibility(vm.status == .searchResult ? .visible : .gone)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 27)
        .backgroundFill(Color.LL.background)
    }

    var searchLocalView: some View {
        VStack(spacing: 10) {
            // tips
            Button {
                vm.searchCommitAction()
                searchIsFocused = false
            } label: {
                HStack(spacing: 0) {
                    Image("icon-add-friends")
                        .frame(width: 40, height: 40)
                        .background(.LL.bgForIcon)
                        .clipShape(Circle())

                    Text("search_the_id".localized)
                        .foregroundColor(.LL.Neutrals.neutrals6)
                        .font(.inter(size: 14, weight: .semibold))
                        .padding(.leading, 16)

                    Text(vm.searchText)
                        .foregroundColor(.LL.Primary.salmonPrimary)
                        .font(.inter(size: 14, weight: .medium))
                        .underline()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 5)
                        .lineLimit(1)
                }
                .frame(height: 50)
                .padding(.horizontal, 18)
                .contentShape(Rectangle())
            }

            // local search table view
            localSearchListView
        }
    }

    var localSearchListView: some View {
        VSectionList(
            model: searchSectionListConfig,
            sections: vm.localSearchResults,
            headerContent: { section in
                searchResultSectionHeader(title: section.title)
            },
            footerContent: { _ in
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
            },
            rowContent: { row in
                AddressBookView.ContactCell(contact: row)
                    .onTapGestureOnBackground {
                        vm.sendToTargetAction(target: row)
                    }
            }
        )
    }

    var searchingView: some View {
        Text("searching")
            .foregroundColor(.LL.Neutrals.note)
            .font(.inter(size: 12, weight: .medium))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var errorMsgView: some View {
        HStack(alignment: .top, spacing: 8) {
            Image("icon-info")
            Text("no_account_found_msg".localized)
                .foregroundColor(.LL.Neutrals.note)
                .font(.inter(size: 12, weight: .medium))
                .lineSpacing(10)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
    }

    var remoteSearchListView: some View {
        VSectionList(
            model: searchSectionListConfig,
            sections: vm.remoteSearchResults,
            headerContent: { section in
                searchResultSectionHeader(title: section.title)
            },
            footerContent: { _ in
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 20)
            },
            rowContent: { row in
                AddressBookView.ContactCell(
                    contact: row,
                    showAddBtn: !vm.addressBookVM.isFriend(contact: row)
                ) {
                    vm.addContactAction(contact: row)
                }.onTapGestureOnBackground {
                    vm.sendToTargetAction(target: row)
                }
            }
        )
    }

    var searchSectionListConfig: VSectionListModel {
        var model = VSectionListModel()
        model.layout.dividerHeight = 0
        model.layout.contentMargin = 0
        model.layout.sectionSpacing = 0
        model.layout.rowSpacing = 0
        model.layout.headerMarginBottom = 8
        model.layout.footerMarginTop = 0
        model.colors.background = Color.LL.background

        return model
    }

    private func searchResultSectionHeader(title: String) -> some View {
        Text(title)
            .foregroundColor(.LL.Neutrals.note)
            .font(.inter(size: 14, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 33)
    }
}

// MARK: - Recent

extension WalletSendView {
    var recentContainerView: some View {
        ZStack {
            ScrollView {
                LazyVStack {
                    ForEach(vm.recentList, id: \.id) { contact in
                        AddressBookView.ContactCell(contact: contact)
                            .onTapGestureOnBackground {
                                vm.sendToTargetAction(target: contact)
                            }
                    }
                }
            }

            emptyView.visibility(vm.recentList.isEmpty ? .visible : .gone)
        }
        .frame(maxHeight: .infinity)
    }

    var emptyView: some View {
        VStack {
            Image("icon-send-empty-users")
            Text("send_user_empty".localized)
                .foregroundColor(Color.LL.note)
                .font(.inter(size: 18, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Address Book

extension WalletSendView {
    var addressBookContainerView: some View {
        ZStack {
            AddressBookView(mode: .inline, vm: vm.addressBookVM)
        }
        .frame(maxHeight: .infinity)
    }
}

extension WalletSendView {
    var accountView: some View {
        VStack {
            ZStack {
                ScrollView {
                    LazyVStack {
                        ForEach(vm.ownAccountList, id: \.id) { contact in
                            AddressBookView.ContactCell(contact: contact)
                                .onTapGestureOnBackground {
                                    vm.sendToTargetAction(target: contact)
                                }
                        }
                    }

                    if !vm.linkedWalletList.isEmpty {
                        HStack {
                            Text("linked_account".localized)
                                .font(.inter(size: 16, weight: .bold))
                                .foregroundStyle(Color.Theme.Text.black3)
                            Spacer()
                        }
                        .padding(.horizontal, 20)

                        LazyVStack {
                            ForEach(vm.linkedWalletList, id: \.id) { contact in
                                AddressBookView.ContactCell(contact: contact)
                                    .onTapGestureOnBackground {
                                        vm.sendToTargetAction(target: contact)
                                    }
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}

// MARK: WalletSendView.SwitchButton

extension WalletSendView {
    struct SwitchButton: View {
        var icon: String
        var title: String
        var isSelected: Bool = false

        var body: some View {
            VStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color.Theme.Accent.grey)

                Text(title)
                    .font(.inter(size: 12))
                    .foregroundColor(.LL.Neutrals.text)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Helper

extension WalletSendView {
    var tabCount: Int {
        TabType.allCases.count
    }
}
