//
//  AddAddressView.swift
//  Flow Wallet
//
//  Created by Selina on 1/6/2022.
//

import SwiftUI

struct AddAddressView: RouteableView {
    // MARK: Lifecycle

    init(addressBookVM: AddressBookView.AddressBookViewModel) {
        _vm = StateObject(wrappedValue: AddAddressViewModel(addressBookVM: addressBookVM))
        confirmedTitle = "add_contact".localized
    }

    init(editingContact: Contact, addressBookVM: AddressBookView.AddressBookViewModel) {
        _vm = StateObject(wrappedValue: AddAddressViewModel(
            contact: editingContact,
            addressBookVM: addressBookVM
        ))
        confirmedTitle = "edit_contact".localized
    }

    // MARK: Internal

    @StateObject
    var vm: AddAddressViewModel

    var title: String {
        confirmedTitle
    }

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                nameField
                addressField
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .navigationBarItems(trailing: HStack {
            Button {
                vm.trigger(.save)
            } label: {
                Text("save".localized)
            }
            .buttonStyle(.plain)
            .foregroundColor(.LL.Primary.salmonPrimary)
            .disabled(!vm.state.isReadyForSave)
        })
        .backgroundFill(.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    var nameField: some View {
        VStack(alignment: .leading) {
            ZStack {
                TextField("name".localized, text: $vm.state.name).frame(height: 50)
            }
            .padding(.horizontal, 10)
            .border(Color.LL.Neutrals.text, cornerRadius: 6)

            Text("enter_a_name".localized).foregroundColor(.LL.Neutrals.text)
                .font(.inter(size: 14, weight: .regular))
        }
    }

    var addressField: some View {
        VStack(alignment: .leading) {
            ZStack {
                TextField("address".localized, text: $vm.state.address).frame(height: 50)
                    .onChange(of: vm.state.address) { _ in
                        vm.trigger(.checkAddress)
                    }
            }
            .padding(.horizontal, 10)
            .border(Color.LL.Neutrals.text, cornerRadius: 6)

            let addressNormalView = Text("enter_address".localized)
                .foregroundColor(.LL.Neutrals.text)
                .font(.inter(size: 14, weight: .regular))

            switch vm.state.addressStateType {
            case .idle, .checking, .passed:
                addressNormalView.visibility(.visible)
            default:
                addressNormalView.visibility(.gone)
            }

            let addressErrorView =
                HStack(spacing: 5) {
                    Image(systemName: .error).foregroundColor(.red)
                    Text(vm.state.addressStateType.desc).foregroundColor(.LL.Neutrals.text)
                        .font(.inter(
                            size: 14,
                            weight: .regular
                        ))
                }

            switch vm.state.addressStateType {
            case .idle, .checking, .passed:
                addressErrorView.visibility(.gone)
            default:
                addressErrorView.visibility(.visible)
            }
        }
    }

    // MARK: Private

    private let confirmedTitle: String
}

// struct AddAddressView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            AddAddressView()
//        }
//    }
// }
