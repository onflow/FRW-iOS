//
//  COAAccountDetailView.swift
//  FRW
//
//  Created by cat on 6/6/25.
//

import FlowWalletKit
import SwiftUI

struct COAAccountDetailView: RouteableView {
    var account: FlowWalletKit.COA

    @State var showAccountEditor = false
    @State private var reloadFlag = false

    var title: String {
        "linked_account".localized
    }

    var body: some View {
        ScrollView {
            VStack {
                AccountInfoCard(account: account) {
                    showAccountEditor.toggle()
                }
                .id(reloadFlag)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .backgroundFill(Color.Theme.Background.white)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                removeAccount()
            } label: {
                Text("remove_account".localized)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.Theme.Accent.red)
                    .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 18)
        }
        .popup(isPresented: $showAccountEditor) {
            WalletAccountEditor(address: account.infoAddress) {
                reload()
                showAccountEditor = false
            }
        } customize: {
            $0
                .closeOnTap(false)
                .closeOnTapOutside(true)
                .backgroundColor(.black.opacity(0.4))
        }
        .applyRouteable(self)
        .tracedView(self)
    }

    func reload() {
        reloadFlag.toggle()
    }

    private func removeAccount() {
        Router.route(to: RouteMap.Profile.removeWallet(account))
    }
}
