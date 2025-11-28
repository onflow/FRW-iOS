//
//  EOAPrivateKeyView.swift
//  Flow Wallet
//
//  Created by cat on 28/11/2025.
//

import SwiftUI
import FlowWalletKit

// MARK: - EOAPrivateKeyView

struct EOAPrivateKeyView: RouteableView {
    @State
    var isBlur: Bool = true

    var title: String {
        "Private Key".localized.capitalized
    }

    var privateKey: String {
      if let provider = WalletManager.shared.keyProvider as? EthereumKeyProtocol {
        return (try? provider.ethPrivateKey())?.hexString ?? ""
      }
      return  ""
    }

  var publickKey: String {
    if let provider = WalletManager.shared.keyProvider as? EthereumKeyProtocol {
      return (try? provider.ethPublicKey())?.hexString ?? ""
    }
    return  ""
  }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Section {
                  Text(publickKey)
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
                          UIPasteboard.general.string = publickKey
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
                          UIPasteboard.general.string = privateKey
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
        .tracedView(self)
    }
}

