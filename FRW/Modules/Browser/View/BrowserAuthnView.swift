//
//  BrowserAuthnView.swift
//  Flow Wallet
//
//  Created by Selina on 6/9/2022.
//

import Flow
import Kingfisher
import SwiftUI

// MARK: - BrowserAuthnView

struct BrowserAuthnView: View {
    // MARK: Lifecycle

    init(vm: BrowserAuthnViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }

    // MARK: Internal

    @StateObject
    var vm: BrowserAuthnViewModel

    var body: some View {
        VStack(spacing: 12) {
            titleView

            WarningView(content: .blocklist)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .visibility(vm.inBlacklist ? .visible : .gone)

            sourceView

            detailView

            if vm.inBlacklist {
                Spacer()
                blocklistActionsView
            } else {
                HStack {
                    walletView
                    networkView
                }
                .padding(.bottom, 8)
                Spacer()
                actionView
            }
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
                Text("browser_connecting_to".localized)
                    .font(.inter(size: 14))
                    .foregroundColor(Color.Theme.Text.text4)

                Text(vm.title)
                    .font(.inter(size: 16, weight: .bold))
                    .foregroundColor(.Theme.Text.black)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                vm.didChooseAction(false)
            } label: {
                Image("icon-btn-close")
                    .renderingMode(.template)
                    .foregroundColor(.LL.Neutrals.note)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 64)
    }

    var sourceView: some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .foregroundColor(.Theme.Text.black3)

            Text(vm.urlString)
                .font(.inter(size: 14, weight: .medium))
                .foregroundColor(.Theme.Text.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
        .frame(height: 46)
        .padding(.horizontal, 18)
        .background(.Theme.BG.bg2)
        .cornerRadius(12)
    }

    var detailView: some View {
        VStack(alignment: .leading, spacing: 12) {
//            Text("browser_app_like_to".localized)
//                .font(.inter(size: 14, weight: .medium))
//                .foregroundColor(Color(hex: "#666666"))
//                .padding(.bottom, 18)

            createAuthDetailView(text: "browser_authn_tips1".localized)

            createAuthDetailView(text: "browser_authn_tips2".localized)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.Theme.BG.bg2)
        .cornerRadius(12)
    }

    var networkView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.Theme.Text.black3)

                Text("network".capitalized)
                    .foregroundColor(.Theme.Text.black3)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.Theme.Text.black3)
            }

            HStack(spacing: 12) {
                Text(vm.network?.name.capitalized ?? "unknown".localized)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(vm.network?.color ?? .Theme.Text.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                Spacer()
            }
        }
        //        .frame(height: 46)
        .padding(.vertical, 8)
        .padding(.horizontal, 18)
        .background(.Theme.BG.bg2)
        .cornerRadius(12)
    }

    var walletView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                user.emoji.icon(size: 20)

                Text(user.name.capitalized)
                    .foregroundColor(.Theme.Text.black8)

                Spacer()
            }

            HStack(spacing: 12) {
                Text(vm.walletAddress ?? "")
                    .truncationMode(.middle)
                    .font(.inter(size: 14, weight: .medium))
                    .foregroundColor(.Theme.Text.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                Spacer()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 18)
        .background(.Theme.BG.bg2)
        .cornerRadius(12)
    }

    var user: WalletAccount.User {
        WalletManager.shared.walletAccount.readInfo(at: vm.walletAddress ?? "")
    }

    var actionView: some View {
        HStack(spacing: 11) {
            Button {
                vm.didChooseAction(false)
            } label: {
                Text("cancel".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "#313131"))
                    .cornerRadius(12)
            }

            Button {
                vm.didChooseAction(true)
            } label: {
                Text("browser_connect".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.LL.Primary.salmonPrimary)
                    .cornerRadius(12)
            }
        }
    }

    var blocklistActionsView: some View {
        VStack(spacing: 12) {
            Button {
                vm.didChooseAction(true)
            } label: {
                ZStack {
                    Text("blocklist_ignore_connect".localized)
                        .font(.inter(size: 14, weight: .medium))
                        .foregroundColor(.Theme.Accent.red)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .cornerRadius(12)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.91, green: 0.23, blue: 0.23), lineWidth: 1)
                }
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                vm.didChooseAction(false)
            } label: {
                Text("cancel".localized)
                    .font(.inter(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "#313131"))
                    .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.bottom, 8)
    }

    func createAuthDetailView(text: String) -> some View {
        HStack(spacing: 12) {
            Image("icon-right-mark")

            Text(text)
                .font(.inter(size: 14, weight: .medium))
                .foregroundColor(.Theme.Text.black8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        }
    }
}

// MARK: - BrowserAuthnView_Previews

struct BrowserAuthnView_Previews: PreviewProvider {
    static let vm = BrowserAuthnViewModel(
        title: "This is title",
        url: "https://core.flow.com",
        logo: "https://web.api.wallet.flow.com/logo_mobile.png",
        walletAddress: "sadasdssadasdasda",
        network: .testnet
    ) { _ in
    }

    static var previews: some View {
        VStack(fill: .proportionally) {
            Color.black
                .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight / 2)
            BrowserAuthnView(vm: vm)
                .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight / 2)
        }
    }
}

extension Flow.ChainID {
    var color: Color {
        switch self {
        case .mainnet:
            return Color.LL.Primary.salmonPrimary
        case .testnet:
            return Color.LL.flow
        default:
            return Color.LL.note
        }
    }
}
