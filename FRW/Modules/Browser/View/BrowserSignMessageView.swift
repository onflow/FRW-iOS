//
//  BrowserSignMessageView.swift
//  Flow Wallet
//
//  Created by Selina on 7/9/2022.
//

import Kingfisher
import SwiftUI

// MARK: - BrowserSignMessageView

struct BrowserSignMessageView: View {
    // MARK: Lifecycle

    init(vm: BrowserSignMessageViewModel) {
        _vm = StateObject(wrappedValue: vm)
        UITextView.appearance().backgroundColor = UIColor(hex: "#313131")
    }

    // MARK: Internal

    @StateObject
    var vm: BrowserSignMessageViewModel

    var body: some View {
        normalView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThickMaterial)
    }

    var normalView: some View {
        VStack(spacing: 0) {
            titleView

            scriptView
                .padding(.top, 12)

            Spacer()
            actionView
        }
        .padding(.all, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .backgroundFill(Color.Theme.BG.bg1)
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
                Text("browser_sign_message_request_from".localized)
                    .font(.inter(size: 14))
                    .foregroundColor(.Theme.Text.text4)

                Text(vm.title)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(.Theme.Text.text1)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var scriptButton: some View {
        Button {
            vm.changeScriptViewShowingAction(true)
        } label: {
            HStack(spacing: 12) {
                Image("icon-script")

                Text("browser_script".localized)
                    .font(.inter(size: 14, weight: .regular))
                    .foregroundColor(.Theme.Text.black8)
                    .lineLimit(1)

                Spacer()

                Image("icon-search-arrow")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.Theme.Text.black8)
                    .frame(width: 12, height: 12)
            }
            .frame(height: 46)
            .padding(.horizontal, 18)
            .background(Color.Theme.BG.bg2)
            .cornerRadius(12)
        }
    }

    var actionView: some View {
        WalletSendButtonView(allowEnable: .constant(true), buttonText: "hold_to_sign".localized) {
            vm.didChooseAction(true)
        }
    }

    var scriptView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(vm.message)
                .font(.inter(size: 14))
                .foregroundColor(.Theme.Text.black8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.all, 18)
        }
        .background(Color.Theme.BG.bg2)
        .cornerRadius(12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.move(edge: .trailing))
    }
}

// MARK: - BrowserSignMessageView_Previews

struct BrowserSignMessageView_Previews: PreviewProvider {
    static let vm = BrowserSignMessageViewModel(
        title: "Test title",
        url: "https://lilico.app",
        logo: "",
        cadence: "464f4f"
    ) { _ in
    }

    static var previews: some View {
        BrowserSignMessageView(vm: vm)
    }
}
