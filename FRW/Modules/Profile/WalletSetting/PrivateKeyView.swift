//
//  PrivateKeyView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 7/9/2022.
//

import SwiftUI

// MARK: - PrivateKeyView

struct PrivateKeyView: RouteableView {
    @State
    var isBlur: Bool = true

    var title: String {
        "Private Key".localized.capitalized
    }

    var privateKey: String {
        WalletManager.shared.getCurrentPrivateKey() ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Section {
                    Text(WalletManager.shared.getCurrentPublicKey() ?? "")
                        .font(.inter(size: 12))
                        .foregroundColor(.Theme.Text.black8)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .background(Color.Theme.Fill.fill1)
                        .cornerRadius(16)

                } header: {
                    HStack {
                        Text("account_key_key".localized)
                            .foregroundColor(.Theme.Text.text4)
                            .font(.inter(size: 14, weight: .semibold))
                        Spacer()
                        CopyButton {
                            UIPasteboard.general.string = WalletManager.shared
                                .getCurrentPublicKey() ?? ""
                            HUD.success(title: "copied".localized)
                        }
                    }
                }

                Section {
                    ZStack(alignment: .center) {
                        Text(privateKey)
                            .font(.inter(size: 12))
                            .foregroundColor(.Theme.Text.black8)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .blur(radius: isBlur ? 5 : 0)

                        if isBlur {
                            Label("Click to reveal".localized, systemImage: "eyes")
                                .foregroundColor(.LL.Neutrals.neutrals3)
                        }
                    }
                    .onTapGesture {
                        isBlur.toggle()
                    }
                    .background(Color.Theme.Fill.fill1)
                    .cornerRadius(16)
                    .onTapGesture {}
                    .animation(.easeInOut, value: isBlur)
                    .instabug_privateView()

                } header: {
                    HStack {
                        Text("Private Key".localized)
                            .foregroundColor(.Theme.Text.text4)
                            .font(.inter(size: 14, weight: .semibold))
                        Spacer()

                        CopyButton {
                            UIPasteboard.general.string = WalletManager.shared
                                .getCurrentPrivateKey() ?? ""
                            HUD.success(title: "copied".localized)
                        }
                    }
                }

                if let key = WalletManager.shared.mainAccount?.fullWeightKey {
                    HStack {
                        HStack {
                            Divider()
                            VStack(alignment: .leading) {
                                Text("Hash__Algorithm::message".localized)
                                    .font(.inter(size: 14))
                                    .foregroundColor(.Theme.Text.text4)
                                Text(key.hashAlgo.algorithm)
                                    .font(.inter(size: 14))
                                    .foregroundColor(.Theme.Text.text4)
                            }
                        }
                        
                        Spacer()
                        
                        HStack {
                            Divider()
                            VStack(alignment: .leading) {
                                Text("Sign__Algorithm::message".localized)
                                    .font(.inter(size: 14))
                                    .foregroundColor(.Theme.Text.text4)
                                Text(key.signAlgo.id)
                                    .font(.inter(size: 14))
                                    .foregroundColor(.Theme.Text.text4)
                            }
                        }
                    }.padding(.vertical, 10)
                }

                PrivateKeyWarning()
                    .padding(.top)
                    .padding(.bottom)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .backgroundFill(Color.Theme.BG.bg1)
        .applyRouteable(self)
    }
}

// MARK: - PrivateKeyScreen_Previews

struct PrivateKeyScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivateKeyView()
        }
    }
}

extension Label where Title == Text, Icon == Image {
    init(_ title: LocalizedStringKey, colorImage: String) {
        self.init {
            Text(title)
        } icon: {
            Image(colorImage)
                .renderingMode(.template)
        }
    }
}
