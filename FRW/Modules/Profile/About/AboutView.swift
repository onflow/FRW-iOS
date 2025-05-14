//
//  AboutView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 20/9/2022.
//

import SwiftUI

// MARK: - AboutView

struct AboutView: RouteableView {
    struct SocialButton: View {
        let imageName: String
        let text: String
        var showDivider: Bool = true
        var isEmoji: Bool = false
        let action: () -> Void

        var body: some View {
            VStack(spacing: 0) {
                Button {
                    action()
                } label: {
                    HStack {
                        if isEmoji {
                            Text(imageName)
                                .font(.system(size: 22))
                                .frame(width: 35, height: 35)
                        } else {
                            Image(imageName)
                                .resizable()
                                .frame(width: 35, height: 35)
                        }

                        Text(text)
                            .font(.LL.body)
                            .foregroundColor(.LL.text)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.LL.body)
                            .foregroundColor(.LL.note)
                    }
                    .padding(18)
                }

                if showDivider {
                    Divider()
                        .background(.LL.bgForIcon)
                        .padding(.horizontal, 12)
                }
            }
            .background(.LL.bgForIcon)
        }
    }

    let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

    let buildVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    var title: String {
        "About"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image("logo")
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.top, 20)
                .padding(.bottom, 8)

            Text("app_name_full".localized)
                .font(.inter(size: 24, weight: .semibold))

            HStack {
                Text("version")
                    .textCase(.lowercase)

                Text("\(buildVersion ?? "") (\(version ?? ""))")
                    .textCase(.lowercase)
            }
            .font(.inter(size: 13, weight: .regular))
            .foregroundColor(.LL.note.opacity(0.5))
            .padding(.bottom, 50)

            Section {
                VStack(spacing: 0) {
                    SocialButton(
                        imageName: "discord",
                        text: "Discord"
                    ) {
                        UIApplication.shared
                            .open(URL(string: "https://discord.com/invite/J6fFnh2xx6")!)
                    }

                    SocialButton(
                        imageName: "twitter",
                        text: "X",
                        showDivider: true
                    ) {
                        UIApplication.shared
                            .open(URL(string: "https://twitter.com/flow_blockchain")!)
                    }

                    SocialButton(imageName: "🔏",
                                 text: "privacy_policy".localized,
                                 showDivider: true,
                                 isEmoji: true)
                    {
                        UIApplication.shared.open(URL(string: "https://wallet.flow.com/privacy-policy")!)
                    }

                    SocialButton(imageName: "📃",
                                 text: "terms_of_service".localized,
                                 showDivider: false,
                                 isEmoji: true)
                    {
                        UIApplication.shared.open(URL(string: "https://wallet.flow.com/terms-of-service")!)
                    }
                }
                .cornerRadius(16)
            } header: {
                Text("contact_us".localized)
                    .textCase(.uppercase)
                    .font(.inter(size: 14, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.LL.note)
                    .padding(.bottom, 8)
            }

//            Section {
//                VStack(spacing: 0) {
//
//                    SocialButton(imageName: "logo",
//                                 text: "lilico".localized + " Extension",
//                                 showDivider: false) {
//                        UIApplication.shared.open(URL(string: "https://chrome.google.com/webstore/detail/lilico/hpclkefagolihohboafpheddmmgdffjm")!)
//                    }
//
//                }
//                .cornerRadius(16)
//            } header: {
//                Text("more".localized)
//                    .textCase(.uppercase)
//                    .font(.inter(size: 14, weight: .regular))
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                    .foregroundColor(.LL.note)
//                    .padding(.top, 20)
//            }

            Spacer()

            Image("Flow")
                .resizable()
                .frame(width: 50, height: 50)
                .onTapGesture {
                    UIApplication.shared.open(URL(string: "https://flow.com")!)
                }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity, alignment: .top)
        .backgroundFill(.LL.background)
        .applyRouteable(self)
        .tracedView(self)
    }
}

// MARK: - AboutView_Previews

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
