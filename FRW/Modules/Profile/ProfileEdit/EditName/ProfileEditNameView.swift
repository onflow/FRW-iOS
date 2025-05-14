//
//  ProfileEditNameView.swift
//  Flow Wallet
//
//  Created by Selina on 14/6/2022.
//

import SwiftUI

// MARK: - ProfileEditNameView_Previews

struct ProfileEditNameView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileEditNameView()
    }
}

// MARK: - ProfileEditNameView

struct ProfileEditNameView: RouteableView {
    // MARK: Internal

    var title: String {
        "edit_nickname".localized
    }

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                nameField
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
            .disabled(vm.status != .ok)
        })
        .backgroundFill(.LL.Neutrals.background)
        .applyRouteable(self)
        .tracedView(self)
    }

    // MARK: Private

    @StateObject
    private var vm = ProfileEditNameViewModel()
}

extension ProfileEditNameView {
    var nameField: some View {
        VStack(alignment: .leading) {
            ZStack {
                TextField("name".localized, text: $vm.name).frame(height: 50)
            }
            .padding(.horizontal, 10)
            .border(Color.LL.Neutrals.text, cornerRadius: 6)
        }
    }
}
