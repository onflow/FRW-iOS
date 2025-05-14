//
//  AddressBookView.swift
//  Flow Wallet
//
//  Created by Selina on 24/5/2022.
//

import Kingfisher
import SwiftUI

// MARK: - AddressBookView.Mode

// struct AddressBookView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView.NoLoginTipsView()
//        ProfileView.GeneralSectionView()
//        AddressBookView()
//        ProfileView.InfoView()
//        ProfileView.InfoActionView()
//        let contacts = [
//            Contact(address: "0x55ad22f01ef568a1", avatar: nil, contactName: "Angel", contactType: nil, domain: nil, id: 0, username: "angel"),
//            Contact(address: "0x55ad22f01ef568a1", avatar: nil, contactName: "Angel", contactType: nil, domain: nil, id: 1, username: "angel"),
//            Contact(address: "0x55ad22f01ef568a1", avatar: nil, contactName: "Angel", contactType: nil, domain: nil, id: 2, username: "angel"),
//            Contact(address: "0x55ad22f01ef568a1", avatar: nil, contactName: "Angel", contactType: nil, domain: nil, id: 3, username: "angel")
//        ]
//    }
// }

extension AddressBookView {
    enum Mode {
        case normal
        case inline
    }
}

// MARK: - AddressBookView

struct AddressBookView: RouteableView {
    // MARK: Lifecycle

    init() {
        self.init(mode: .normal)
    }

    init(mode: Mode, vm: AddressBookViewModel? = nil) {
        self.mode = mode

        if let vm = vm {
            _vm = StateObject(wrappedValue: vm)
        } else {
            _vm = StateObject(wrappedValue: AddressBookViewModel())
        }
        UITableView.appearance().backgroundColor = UIColor.LL.background
    }

    // MARK: Internal

    var title: String {
        "address_book".localized
    }

    var body: some View {
        let view =
            ZStack {
                listView
                loadingView
                errorView
            }

        if mode == .normal {
            return AnyView(
                view
                    .applyRouteable(self)
        .tracedView(self)
                    .navigationBarItems(trailing: HStack(spacing: 6) {
                        Button {
                            Router.route(to: RouteMap.AddressBook.add(vm))
                        } label: {
                            Image("btn-add")
                                .renderingMode(.template)
                                .foregroundColor(.LL.Primary.salmonPrimary)
                        }

//                    Button {
//                        debugPrint("scan btn click")
//                    } label: {
//                        Image("btn-scan")
//                            .renderingMode(.template)
//                            .foregroundColor(.LL.Primary.salmonPrimary)
//                    }
                    })
                    .alert("contact_delete_alert".localized, isPresented: $showAlert) {
                        Button("delete".localized, role: .destructive) {
                            if let sectionVM = self.pendingDeleteModel.sectionVM,
                               let contact = self.pendingDeleteModel.contact {
                                self.vm.trigger(.delete(sectionVM, contact))
                            }
                        }
                    }
                    .opacity(opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                opacity = 1
                            }
                        }
                    }
            )
        }

        return AnyView(view)
    }

    // MARK: Private

    @StateObject
    private var vm: AddressBookViewModel

    @StateObject
    private var pendingDeleteModel = PendingDeleteModel()
    @State
    private var showAlert = false

    @State
    private var mode: Mode
    @State
    private var opacity: Double = 0
}

extension AddressBookView {
    var loadingView: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<5, id: \.self) { _ in
                    loadingItemPlaceHolder
                }
            }
            .padding(.all, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .disabled(true)
        .redacted(reason: .placeholder)
        .shimmering(active: vm.state.stateType == .loading)
        .visibility(vm.state.stateType == .loading ? .visible : .gone)
    }

    var loadingItemPlaceHolder: some View {
        Color.systemGray4
            .height(60)
            .cornerRadius(16)
    }

    var errorView: some View {
        VStack {
            Text("address_book_request_failed".localized)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.LL.Neutrals.background)
        .visibility(vm.state.stateType == .error ? .visible : .gone)
    }

    var listView: some View {
        let list =

            IndexedList(vm.searchResults) { sectionVM in
                Section {
                    ForEach(sectionVM.state.list) { row in
                        let cell =
                            ContactCell(contact: row)
                                .listRowSeparator(.hidden)
                                .listRowInsets(.zero)
                                .onTapGestureOnBackground {
                                    vm.trigger(.select(row))
                                }

                        if mode == .normal {
                            cell.swipeActions(allowsFullSwipe: false) {
                                Button(action: {
                                    self.pendingDeleteModel.sectionVM = sectionVM
                                    self.pendingDeleteModel.contact = row
                                    self.showAlert = true
                                }, label: {
                                    Text("delete".localized)
                                })
                                .tint(Color.systemRed)

                                Button(action: {
                                    self.vm.trigger(.edit(row))
                                }, label: {
                                    Text("edit".localized)
                                })
                            }
                        } else {
                            cell
                        }
                    }
                } header: {
                    sectionHeader(sectionVM)
                        .id(sectionVM.id)
                }
                .listRowBackground(Color.LL.background)
            }
            .frame(maxHeight: .infinity)
            .listStyle(.plain)
            .visibility(vm.state.stateType == .idle ? .visible : .gone)

        var anyView: AnyView
        if mode == .normal {
            anyView = AnyView(list.searchable(text: $vm.searchText))
        } else {
            anyView = AnyView(list)
        }

        #if compiler(>=5.7)
//            return anyView.scrollContentBackground(.hidden)
        return anyView
            .backgroundFill(.LL.background)
        #else
        return anyView
        #endif
    }

    @ViewBuilder
    private func sectionHeader(_ sectionVM: SectionViewModel) -> some View {
        let sectionName = sectionVM.state.sectionName
        Text(sectionName).foregroundColor(.LL.Neutrals.text2).font(.inter(
            size: 14,
            weight: .semibold
        ))
    }
}

// MARK: AddressBookView.ContactCell

extension AddressBookView {
    struct ContactCell: View {
        let contact: Contact
        var showAddBtn: Bool? = false
        var addAction: (() -> Void)? = nil

        var body: some View {
            HStack(spacing: 20) {
                // avatar
                ZStack {
                    switch contact.contactType {
                    case .user:
                        if contact.user?.emoji != nil {
                            contact.user?.emoji.icon(size: 48)
                        } else {
                            KFImage
                                .url(URL(
                                    string: contact.avatar?
                                        .convertedAvatarString() ?? placeholder
                                ))
                                .placeholder {
                                    Image("placeholder")
                                        .resizable()
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                        }

                    case .domain:
                        if let localAvatar = contact.localAvatar {
                            Image(localAvatar)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                        } else {
                            Text(String((contact.contactName?.first ?? "A").uppercased()))
                                .foregroundColor(.Theme.Accent.grey)
                                .font(.inter(size: 24, weight: .semibold))
                        }

                    default:
                        Text(String((contact.contactName?.first ?? "A").uppercased()))
                            .foregroundColor(.Theme.Accent.grey)
                            .font(.inter(size: 24, weight: .semibold))
                    }
                }
                .frame(width: 48, height: 48)
                .background(.Theme.Accent.grey.opacity(0.16))
                .clipShape(Circle())

                // text
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.contactName ?? contact.user?.name ?? contact.name)
                        .foregroundColor(.LL.Neutrals.text)
                        .font(.inter(size: 14, weight: .bold))
                        .frame(height: 18)

//                    if let userName = contact.username, !userName.isEmpty {
//                        Text("@\(userName)")
//                            .foregroundColor(.LL.Neutrals.note)
//                            .font(.inter(size: 14, weight: .medium))
//                    }

                    Text(contact.address ?? "no address")
                        .truncationMode(.middle)
                        .foregroundColor(.LL.Neutrals.note)
                        .font(.inter(size: 14))
                        .frame(height: 20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    addAction?()
                } label: {
                    Image("icon-add-friends")
                }
                .visibility(showAddBtn ?? false ? .visible : .gone)
            }
            .padding(EdgeInsets(top: 10, leading: 34, bottom: 10, trailing: 34))
        }
    }
}

// MARK: AddressBookView.PendingDeleteModel

extension AddressBookView {
    class PendingDeleteModel: ObservableObject {
        var sectionVM: SectionViewModel?
        var contact: Contact?
    }
}
