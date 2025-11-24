//
//  BuyProvderView.swift
//  Flow Wallet
//
//  Created by Hao Fu on 8/9/2022.
//

import SwiftUI

// MARK: - BuyProvderView

struct BuyProvderView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("choose_provider".localized)
                .font(.inter(size: 20, weight: .semibold))

            Divider()

            Button {
                EventTrack.General.rampClick(source: .moonpay)
                Task {
                    await launchMoonPay()
                }

            } label: {
                Color(hex: "#242424")
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .overlay {
                        Image("moonpay")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 30)
                    }
                    .cornerRadius(12)
            }.buttonStyle(ScaleButtonStyle())

            if currentNetwork == .mainnet {
                Button {
                    EventTrack.General.rampClick(source: .coinbase)
                    Task {
                      await launchCoinbase()
                    }
                } label: {
                    Color(hex: "#0052FF")
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .overlay {
                            Image("coinbase-pay")
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                        }
                        .cornerRadius(12)
                }.buttonStyle(ScaleButtonStyle())
            }
            Spacer()
        }
        .padding(.top, 20)
        .padding(.horizontal, 18)
        .background(Color.LL.background)
    }

    func launchMoonPay() async {
        guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
            HUD.error(title: "Invaild Address")
            return
        }

        HUD.loading()

        let request =
            MoonPayRequest(
                url: "https://buy.moonpay.com?apiKey=pk_live_6YNhgtZH8nyxkJiQRZsotO69G2loIyv0&defaultCurrencyCode=FLOW&colorCode=%23FC814A&walletAddress=\(address)"
            )

        do {
            let response: MoonPayResponse = try await Network.request(FirebaseAPI.moonPay(request))
            HUD.dismissLoading()
            Router.dismiss(animated: true) {
                Router.route(to: RouteMap.Explore.safariBrowser(response.url))
            }

        } catch {
            HUD.error(title: "Open MoonPay Failed")
        }
    }

  private func launchCoinbase() async {
    guard let address = WalletManager.shared.getPrimaryWalletAddress() else {
        HUD.error(title: "Invaild Address")
        return
    }

    HUD.loading()

    do {
      let resp: BuyProvderView.Data = try await Network.request(FRWAPI.Utils.coinbase(address
          ))
        HUD.dismissLoading()
        Router.dismiss(animated: true) {
          if let url = URL(string: resp.session.onrampUrl) {
            Router.route(to: RouteMap.Explore.safariBrowser(url))
          }
        }

    } catch {
        HUD.dismissLoading()
        HUD.error(title: "Open Coinbase Failed")
    }
  }
}

extension BuyProvderView {
  struct Data: Codable {
    let session: BuyProvderView.Session
  }

  struct Session: Codable {
    let onrampUrl: String
  }
}

// MARK: - BuyProvderView_Previews

struct BuyProvderView_Previews: PreviewProvider {
    static var previews: some View {
        BuyProvderView()
    }
}
