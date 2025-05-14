//
//  WalletConnectView.swift
//  Flow Wallet
//
//  Created by Selina on 2/8/2022.
//

import Kingfisher
import Lottie
import SwiftUI
import WalletConnectSign

// MARK: - WalletConnectView

struct WalletConnectView: RouteableView {
    @StateObject
    private var vm = WalletConnectViewModel()

    @StateObject
    var manager = WalletConnectManager.shared

    var title: String {
        "walletconnect".localized
    }

    var connectedViews: some View {
        VStack(alignment: .leading) {
            Text("connected_site".localized)
                .font(.inter(size: 14, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text2)

            ForEach(manager.activeSessions, id: \.topic) { session in
                Menu {
                    Text(session.peer.description)
                        .font(.inter(size: 8, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.LL.Neutrals.neutrals7)

                    Divider()
                        .foregroundColor(.LL.Neutrals.neutrals3)

                    Button(role: .destructive) {
                        Task {
                            await WalletConnectManager.shared.disconnect(topic: session.topic)
                        }
                    } label: {
                        Label("Disconnect", systemImage: "xmark.circle")
                            .foregroundColor(.LL.warning2)
                    }
                } label: {
                    ItemCell(
                        title: session.peer.name,
                        url: session.peer.url,
                        network: String(
                            session.namespaces.values.first?.accounts.first?
                                .reference ?? ""
                        ),
                        icon: session.peer.icons.first ?? AppPlaceholder.image
                    )
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 16)
                    .roundedBg()
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    var pendingViews: some View {
        VStack(alignment: .leading) {
            Text("pending_request".localized)
                .font(.inter(size: 14, weight: .medium))
                .foregroundColor(Color.LL.Neutrals.text2)

            ForEach(manager.pendingRequests, id: \.id) { request in
                createPendingItemView(request: request)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }

    func createPendingItemView(request: WalletConnectSign.Request) -> some View {
        Button {
            WalletConnectManager.shared.handleRequest(request)
        } label: {
            HStack(spacing: 12) {
                KFImage.url(request.logoURL)
                    .placeholder {
                        Image("placeholder")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                VStack(alignment: .leading) {
                    Text(request.name ?? "")
                        .font(.LL.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.LL.Neutrals.text)

                    Text(request.dappURL?.host ?? "")
                        .font(.LL.footnote)
                        .foregroundColor(Color.LL.Neutrals.neutrals9)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .frame(height: 64)
            .background(.LL.bgForIcon)
            .cornerRadius(16)
            .buttonStyle(ScaleButtonStyle())
        }
    }

    var body: some View {
        if !manager.activeSessions.isEmpty || !manager.pendingRequests.isEmpty {
            ScrollView {
                VStack(spacing: 0) {
                    pendingViews
                        .visibility(!manager.pendingRequests.isEmpty ? .visible : .gone)

                    connectedViews
                        .visibility(!manager.activeSessions.isEmpty ? .visible : .gone)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 18)
            }
            .navigationBarItems(
                center: HStack {
                    Image("walletconnect")
                        .frame(width: 24, height: 24)
                    Text("walletconnect".localized)
                        .font(.LL.body)
                        .fontWeight(.semibold)
                },
                trailing:
                Button {
                    ScanHandler.scan()
                } label: {
                    Image("icon-wallet-scan")
                        .renderingMode(.template)
                        .foregroundColor(.primary)
                }
            )
            .backgroundFill(Color.LL.Neutrals.background)
            .applyRouteable(self)
            .tracedView(self)
        } else {
            WalletConnectView.EmptyView()
                .backgroundFill(Color.LL.Neutrals.background)
                .navigationBarBackButtonHidden(true)
                .navigationBarTitleDisplayMode(navigationBarTitleDisplayMode)
                .navigationBarHidden(isNavigationBarHidden)
                .navigationBarItems(
                    center: HStack {
                        Image("walletconnect")
                            .frame(width: 24, height: 24)
                        Text("walletconnect".localized)
                            .font(.LL.body)
                            .fontWeight(.semibold)
                    },
                    trailing:
                    Button {
                        ScanHandler.scan()
                    } label: {
                        Image("icon-wallet-scan")
                            .renderingMode(.template)
                            .foregroundColor(.primary)
                    }
                )
        }
    }
}

// MARK: WalletConnectView.EmptyView

extension WalletConnectView {
    struct EmptyView: View {
        let animationView = AnimationView(name: "QRScan", bundle: .main)

        var body: some View {
            VStack(alignment: .center, spacing: 18) {
                Spacer()
                ResizableLottieView(
                    lottieView: animationView,
                    color: Color(hex: "#3B99FC")
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())

                Text("Scan to Connect")
                    .foregroundColor(.LL.text)
                    .font(.LL.title2)
                    .fontWeight(.bold)

                Text("With WalletConnect, you can connect your wallet with hundreds of apps")
                    .font(.LL.callout)
                    .foregroundColor(.LL.Neutrals.text3)
                    .multilineTextAlignment(.center)

                Button {
                    ScanHandler.scan()
                } label: {
                    Text("New Connection")
                        .font(.LL.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.white)
                        .padding(15)
                        .background(Color(hex: "#3B99FC"))
                        .cornerRadius(12)
                }
                .padding(.top, 12)

                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                animationView.backgroundBehavior = .pauseAndRestore
                animationView.play(toProgress: .infinity, loopMode: .loop)
            }
        }
    }
}

// MARK: WalletConnectView.ItemCell

extension WalletConnectView {
    struct ItemCell: View {
        // MARK: Lifecycle

        init(title: String, url: String, network: String, icon: String) {
            self.title = title
            self.url = url
            self.network = network
            self.icon = icon
            fetchSVG()
        }

        // MARK: Internal

        let title: String
        let url: String
        let network: String
        let icon: String

        @State
        var svgString: String? = nil

        var color: SwiftUI.Color {
            network == "testnet" ? Color.LL.flow : Color.LL.Primary.salmonPrimary
        }

        var body: some View {
            HStack(spacing: 0) {
                if let svg = svgString {
                    SVGWebView(svg: svg)
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.trailing, 12)
                } else {
                    KFImage.url(URL(string: icon))
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.trailing, 12)
                }

                VStack {
                    Text(title)
                        .font(.LL.body)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(Color.LL.Neutrals.text)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(URL(string: url)?.host ?? url)
                        .font(.LL.footnote)
                        .lineLimit(1)
                        .foregroundColor(Color.LL.Neutrals.neutrals9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                ifLet(network) { _, _ in
                    Text(network)
                        .font(.LL.caption)
                        .textCase(.uppercase)
                        .padding(8)
                        .padding(.horizontal, 5)
                        .foregroundColor(color)
                        .background {
                            Capsule()
                                .fill(color.opacity(0.2))
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }

        func fetchSVG() {
            if icon.lowercased().hasSuffix("svg"), let svgURL = URL(string: icon) {
                Task {
                    if let svg = await SVGCache.cache.getSVG(svgURL) {
                        DispatchQueue.main.async {
                            self.svgString = svg
                        }
                    }
                }
            }
        }
    }
}

// struct Previews_WalletConnectView_Previews: PreviewProvider {
//    static var previews: some View {
//        //        WalletConnectView.ItemCell(title: "NBA Top",
//        //                                   url: "https://google.com",
//        //                                   network: "mainnet",
//        //                                   icon: AppPlaceholder.image)
//        //        .previewLayout(.sizeThatFits)
//
//        WalletConnectView.EmptyView()
//    }
// }
