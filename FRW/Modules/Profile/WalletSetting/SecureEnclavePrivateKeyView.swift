//
//  SecureEnclavePrivateKeyView.swift
//  FRW
//
//  Created by cat on 2024/9/16.
//

import SwiftUI

struct SecureEnclavePrivateKeyView: RouteableView {
    var title: String {
        "Private Key".localized.capitalized
    }

    var learnMoreUrl: String {
        "https://frw.gitbook.io/doc/faq/faq#where-is-my-seed-phrase-i-cant-find-it-on-flow-wallet-ios-or-android"
    }

    var publicKey: String {
        WalletManager.shared.getCurrentPublicKey() ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Section {
                    HStack {
                        Text(publicKey)
                            .font(.inter(size: 12))
                            .foregroundColor(.Theme.Text.black8)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.Theme.Fill.fill1)
                    .cornerRadius(16)
                    .padding(.bottom, 24)

                } header: {
                    HStack {
                        Text("account_key_key".localized)
                            .font(.inter(size: 14, weight: .semibold))
                            .foregroundColor(.Theme.Text.text4)

                        Spacer()
                        CopyButton {
                            UIPasteboard.general.string = publicKey
                            HUD.success(title: "copied".localized)
                        }
                    }
                }
                .visibility(publicKey.isEmpty ? .gone : .visible)

                Section {
                    VStack(spacing: 24) {
                        Text("private_key_secured_hint".localized)
                            .font(.inter(size: 12))
                            .foregroundColor(.Theme.Text.black8)

                        Button {
                            if let url = URL(string: learnMoreUrl) {
                                UIApplication.shared.open(url)
                            }

                        } label: {
                            Text("Learn__more::message".localized)
                                .font(.inter(size: 14, weight: .semibold))
                                .foregroundStyle(Color.Theme.Accent.blue)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(.Theme.Accent.blue.opacity(0.12))
                    .cornerRadius(16)
                    .padding(.bottom, 24)

                } header: {
                    HStack(spacing: 4) {
                        Text("Private Key".localized)
                            .font(.inter(size: 14, weight: .semibold))
                            .foregroundColor(.Theme.Text.text4)

                        Spacer()

                        Image(systemName: "shield.fill")
                            .foregroundStyle(Color.Theme.Accent.green)
                            .font(.system(size: 14))
                        Text("secured_by_se".localized)
                            .foregroundStyle(Color.Theme.Accent.green)
                            .font(.inter(size: 12, weight: .bold))
                    }
                }

                if let key = WalletManager.shared.currenFlowAccount?.fullWeightKey {
                    HStack {
                        HStack(spacing: 16) {
                            Divider()
                            VStack(alignment: .leading) {
                                Text("Hash__Algorithm::message".localized)
                                    .font(.inter(size: 14))
                                    .foregroundColor(Color.Theme.Text.text4)
                                
                                Text(key.hashAlgo.algorithm)
                                    .font(.inter(size: 14))
                                    .foregroundColor(Color.Theme.Text.text4)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Divider()
                            VStack(alignment: .leading) {
                                Text("Sign__Algorithm::message".localized)
                                    .font(.inter(size: 14))
                                    .foregroundColor(Color.Theme.Text.text4)
                                
                                Text(key.signAlgo.id)
                                    .font(.inter(size: 14))
                                    .foregroundColor(Color.Theme.Text.text4)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .backgroundFill(.LL.background)
        .applyRouteable(self)
    }
}

#Preview {
    SecureEnclavePrivateKeyView()
}
