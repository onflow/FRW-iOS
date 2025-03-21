//
//  WalletHomeView.swift
//  FRW
//
//  Created by cat on 2024/3/28.
//

import CollectionViewPagingLayout
import FirebaseAuth
import Flow
import Kingfisher
import LogView
import SPConfetti
import SwiftUI
import SwiftUIPager
import SwiftUIX

// MARK: - WalletHomeView + AppTabBarPageProtocol

extension WalletHomeView: AppTabBarPageProtocol {
    static func tabTag() -> AppTabType {
        .wallet
    }

    static func iconName() -> String {
        "tabler-icon-home"
    }

    static func title() -> String {
        "home".localized
    }
}

// MARK: - WalletHomeView

struct WalletHomeView: View {
    @State
    var safeArea: EdgeInsets = .zero
    @State
    var size: CGSize = .zero

    @StateObject
    var um = UserManager.shared
    @StateObject
    var wm = WalletManager.shared
    @StateObject
    private var vm = WalletViewModel()
    @StateObject
    var newsHandler = WalletNewsHandler.shared
    @State
    var isRefreshing: Bool = false
    @State
    private var showActionSheet = false
    @AppStorage("WalletCardBackrgound")
    private var walletCardBackrgound: String = "fade:0"

    @State
    var selectedNewsId: String?
    @State
    var scrollNext: Bool = false

    private let scrollName: String = "WALLETSCROLL"

    @State
    private var logViewPresented: Bool = false

//    @State private var forcedColorScheme: ColorScheme? = nil
//    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { proxy in

            ZStack {
                NormalView().visibility(um.isLoggedIn ? .visible : .gone)
            }
            .halfSheet(
                showSheet: $vm.backupTipsPresent,
                autoResizing: true,
                backgroundColor: Color.LL.Neutrals.background
            ) {
                BackupTipsView(closeAction: {
                    vm.backupTipsPresent = false
                })
            }
            .onAppear {
                safeArea = proxy.safeAreaInsets
                size = proxy.size
                self.vm.viewWillAppear()
            }
//            .preferredColorScheme(forcedColorScheme)
//            .onChange(of: colorScheme, perform: { newValue in
//                if ThemeManager.shared.style == nil {
//                    ThemeManager.shared.setStyle(style: newValue)
//                }
//            })
            .navigationBarHidden(true)
            .ignoresSafeArea(.container, edges: .top)
        }
    }

    var headerHeight: CGFloat {
        size.height * 0.3
    }

    @ViewBuilder
    func NormalView() -> some View {
        RefreshableScrollView(showsIndicators: false, loadingViewBackgroundColor: .clear) { done in
            if isRefreshing {
                return
            }
            isRefreshing = true
            vm.reloadWalletData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                done()
                isRefreshing = false
            }
        } progress: { state in
            ImageAnimated(
                imageSize: CGSize(width: 60, height: 60),
                imageNames: ImageAnimated.appRefreshImageNames(),
                duration: 1.6,
                isAnimating: state == .loading || state == .primed
            )
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .transition(
                AnyTransition.move(edge: .bottom).combined(with: .scale)
                    .combined(with: .opacity)
            )
            .visibility(state == .waiting ? .gone : .visible)
            .zIndex(2)
            .offset(y: headerHeight + 20)
        } content: {
            VStack(spacing: 0) {
                JailbreakTipsView()
                    .visibility(UIDevice.isJailbreak ? .visible : .gone)
                HeaderView()
                    .zIndex(1)
                WalletInfo()
                    .zIndex(10)

                CoinListView()
                    .zIndex(20)
            }
            .overlay(alignment: .top) {
                TopMenuView()
            }
        }
        .coordinateSpace(name: scrollName)
        .environmentObject(vm)
        .mockPlaceholder(vm.needShowPlaceholder)
    }

    @ViewBuilder
    func TopMenuView() -> some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .named(scrollName)).minY
            let progress = minY /
                (headerHeight * (minY > 0 ? 0.5 : 0.8) + proxy.safeAreaInsets.top - 33)

            HStack {
                Button {
                    vm.sideToggleAction()
                } label: {
                    HStack {
                        if let url = ChildAccountManager.shared.selectedChildAccount?.icon {
                            KFImage.url(URL(string: url.convertedAvatarString()))
                                .placeholder {
                                    Image("placeholder")
                                        .resizable()
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 28, height: 28)
                                .cornerRadius(14)
                        } else {
                            wm.currentAccount.emoji.icon(size: 24)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.Theme.Text.white9.opacity(0.9))
                    .cornerRadius(20)
                }

                Spacer()

                HStack {
                    Button {
                        vm.scanAction()
                    } label: {
                        HStack {
                            Image("icon-wallet-scan")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundStyle(Color.Theme.Text.black8)
                                .frame(width: 24, height: 24)
                            Text("scan".localized)
                                .font(.inter(size: 14, weight: .regular))
                                .foregroundStyle(Color.Theme.Text.black8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.Theme.BG.bg2.opacity(0.6))
                .cornerRadius(12)
            }
            .padding(.top, safeArea.top)
            .padding([.horizontal, .bottom], 15)
            .background {
                Color.Theme.Text.white9
                    .opacity(-progress)
            }
            .offset(y: -minY)
        }
        .frame(height: 40)
    }

    @ViewBuilder
    func JailbreakTipsView() -> some View {
        Button {
            Router.route(to: RouteMap.Wallet.jailbreakAlert)
        } label: {
            HStack(spacing: 8) {
                Image("icon-warning-mark")
                    .renderingMode(.template)
                    .foregroundColor(Color.LL.Warning.warning2)

                Text("jailbreak_alert_msg".localized)
                    .font(.inter(size: 16, weight: .medium))
                    .foregroundColor(Color.LL.Warning.warning2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                Image("icon-account-arrow-right")
                    .renderingMode(.template)
                    .foregroundColor(Color.LL.Warning.warning2)
            }
            .padding(.all, 18)
            .background(Color.LL.Warning.warning5)
            .cornerRadius(16)
            .padding(.horizontal, 18)
        }
    }

    @ViewBuilder
    func HeaderView() -> some View {
        GeometryReader { proxy in
            let size = proxy.size
            let minY = proxy.frame(in: .named(scrollName)).minY
            let progress = minY / (headerHeight * (minY > 0 ? 0.5 : 0.8))
            ZStack(alignment: .bottom) {
                HStack {
                    CardBackground(value: walletCardBackrgound).renderView()
                }
                .overlay {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: .white.opacity(0), location: 0.00),
                            Gradient.Stop(color: .black.opacity(0.3), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.5, y: 0),
                        endPoint: UnitPoint(x: 0.5, y: 1)
                    )
                    .visibility(vm.showHeaderMask ? .visible : .gone)
                }
                .onLongPressGesture {
                    if showActionSheet {
                        return
                    }
                    self.showActionSheet = true
                }

                VStack(alignment: .trailing) {
                    Spacer()

                    StackPageView(newsHandler.list, selection: $selectedNewsId) { news in
                        WalletNotificationView(item: news) { idStr in
//                            if let nextId = newsHandler.nextItem(idStr) {
//                                selectedNewsId =  nextId
//                            }
                            selectedNewsId = idStr
                            newsHandler.onCloseItem(idStr)
                        } onAction: { _ in
                        }
                    }
                    .options(.flowStack)
                    .scrollToSelectedPage(false)
                    .numberOfVisibleItems(2)
                    .pagePadding(
                        horizontal: .absolute(16)
                    )
                    .onTapPage { idStr in
                        newsHandler.onClickItem(idStr)
                    }
                    .valueChanged(value: selectedNewsId ?? "", onChange: { id in
                        newsHandler.onShowItem(id)
                    })
                    .frame(height: 104) // 72 + 16* 2
                    .padding(.bottom, 16)
                }
            }
            .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
            .clipped()
            .overlay {
                Color.Theme.Text.white9
                    .opacity(-progress)
            }
            .offset(y: -minY)
            .confirmationDialog(
                "Select a color",
                isPresented: $showActionSheet,
                titleVisibility: .hidden
            ) {
                Button("change wallpaper") {
                    showWallpaper()
                }
            }
            .onAppear {
                newsHandler.checkFirstNews()
            }
            .visibility(vm.needShowPlaceholder ? .gone : .visible)
        }
        .frame(height: headerHeight + safeArea.top)
    }

    private func showWallpaper() {
        Router.route(to: RouteMap.Profile.wallpaper)
    }

    private var childAccountBackground: some View {
        ZStack {
            KFImage.url(URL(string: WalletManager.shared.selectedAccountIcon))
                .placeholder {
                    Image("placeholder")
                        .resizable()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 6)

            LinearGradient(
                colors:
                [
                    Color(hex: "#333333"),
                    Color(hex: "#333333"),
                    Color(hex: "#333333").opacity(0.88),
                    Color(hex: "#333333").opacity(0.32),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    @ViewBuilder
    func IndicatorBar() -> some View {
        HStack {
            Spacer()
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 71, height: 5)
                .background(.Theme.Background.pureWhite)
                .cornerRadius(8)
            Spacer()
        }
    }

    @ViewBuilder
    func WalletInfo() -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                HStack {
                    Text(
                        vm
                            .isHidden ? "****" :
                            "\(CurrencyCache.cache.currencySymbol)\(vm.balance.formatCurrencyStringForDisplay(digits: 2, considerCustomCurrency: true))"
                    )
                    .font(.Ukraine(size: 30, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.black)

                    Spacer()

                    Button {
                        vm.toggleHiddenStatusAction()
                    } label: {
                        Image(vm.isHidden ? "icon-wallet-hidden-on" : "icon-wallet-hidden-off")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fill)
                            .foregroundColor(Color.Theme.Text.black3)
                            .frame(width: 24, height: 24)
                            .padding(4)
                    }
                    .clipped()
                }
                .frame(height: 44)

                HStack {
                    Text(WalletManager.shared.selectedAccountAddress)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.inter(size: 16))
                        .foregroundStyle(Color.LL.text)
                    Spacer()

                    Button {
                        vm.copyAddressAction()
                    } label: {
                        HStack {
                            Image("icon_copy")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color.Theme.Text.black3)
                                .frame(width: 24, height: 24)
                                .padding(4)
                        }
                    }
                }
                .frame(height: 44)
                .padding(.bottom, 12)
            }
            .padding(.top, 18)
            .padding(.horizontal, 24)
            .background(Color.Theme.Background.white)
            .background(content: {
                VisualEffectBlur(effect: .systemMaterial)
            })
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: -5)

            walletActionBar()
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .background(.Theme.Background.white)
                .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .top) {
            IndicatorBar()
                .offset(y: -12)
        }
    }

    private func walletActionBar() -> some View {
        WalletActionBar {
            WalletActionButton(
                event: .send,
                allowClick: !wm.isSelectedChildAccount
            ) {
                LocalUserDefaults.shared.recentToken = nil
                Router.route(to: RouteMap.Wallet.send())
            }

            WalletActionButton(
                event: .receive,
                allowClick: true
            ) {
                Router.route(to: RouteMap.Wallet.receiveQR)
            }

            WalletActionButton(
                event: .swap,
                allowClick: true
            ) {
                Router.route(to: RouteMap.Wallet.swapProvider(nil))
            }
            .visibility(vm.showSwapButton ? .visible : .gone)

            WalletActionButton(
                event: .stake,
                allowClick: !wm.isSelectedChildAccount
            ) {
                if !LocalUserDefaults.shared.stakingGuideDisplayed && !StakingManager.shared
                    .isStaked
                {
                    Router.route(to: RouteMap.Wallet.stakingSelectProvider)
                    return
                }

                Router.route(to: RouteMap.Wallet.stakingList)
            }
            .visibility(vm.showStakeButton ? .visible : .gone)
        }
    }

    @ViewBuilder
    func CoinListView() -> some View {
        VStack(spacing: 16) {
            HStack {
                Text((!vm.mCoinItems.isEmpty ? "\(vm.mCoinItems.count) " : "") + "tokens".localized)
                    .font(.inter(size: 18, weight: .bold))
                    .foregroundStyle(Color.Theme.Text.black3)
                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    Router.route(to: RouteMap.Wallet.buyCrypto)
                } label: {
                    HStack(spacing: 4) {
                        Image("icon_wallet_action_buy")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color.Theme.Text.black3)
                            .background(.clear)
                            .frame(width: 24, height: 24)

                        Text("buy_uppercase".localized)
                            .font(.inter(size: 14, weight: .semibold))
                            .foregroundColor(Color.Theme.Text.black3)
                    }
                    .padding(.horizontal, 8)
                    .background(Color.Theme.Background.grey)
                    .cornerRadius(12)
                }
                .buttonStyle(ScaleButtonStyle())
                .visibility(vm.showBuyButton ? .visible : .gone)

                Button {
                    vm.onAddToken()
                } label: {
                    Image("icon-wallet-coin-add")
                        .renderingMode(.template)
                        .foregroundColor(Color.Theme.Text.black3)
                        .frame(width: 24, height: 24)
                }
                .visibility(vm.showAddTokenButton ? .visible : .gone)
                .buttonStyle(ScaleButtonStyle())
            }

            VStack(spacing: 5) {
                ForEach(vm.mCoinItems, id: \.token.symbol) { coin in
                    Button {
                        Router.route(to: RouteMap.Wallet.tokenDetail(
                            coin.token,
                            WalletManager.shared.accessibleManager.isAccessible(coin.token)
                        ))
                    } label: {
                        WalletHomeView.CoinCell(coin: coin)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            Spacer(minLength: headerHeight + safeArea.top)
        }
        .padding(.horizontal, 16)
        .background(.Theme.Background.white)
    }

    @ViewBuilder
    func ErrorView() -> some View {
        Text("error")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .backgroundFill(.LL.Neutrals.background)
    }
}

private let CoinIconHeight: CGFloat = 44
private let CoinCellHeight: CGFloat = 76

// MARK: WalletHomeView.CoinCell

extension WalletHomeView {
    struct CoinCell: View {
        let coin: WalletViewModel.WalletCoinItemModel
        @EnvironmentObject
        var vm: WalletViewModel
        @StateObject
        var stakingManager = StakingManager.shared

        var body: some View {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 18) {
                    KFImage.url(coin.token.iconURL)
                        .placeholder {
                            Image("placeholder")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: CoinIconHeight, height: CoinIconHeight)
                        .clipShape(Circle())

                    VStack(spacing: 7) {
                        HStack {
                            Text(coin.token.name)
                                .foregroundColor(.LL.Neutrals.text)
                                .font(.inter(size: 14, weight: .bold))

                            Spacer()

                            Text(
                                "\(vm.isHidden ? "****" : coin.balance.formatCurrencyStringForDisplay(digits: 2)) \(coin.token.symbol?.uppercased() ?? "?")"
                            )
                            .foregroundColor(.LL.Neutrals.text)
                            .font(.inter(size: 14, weight: .medium))
                        }

                        HStack {
                            if WalletManager.shared.accessibleManager.isAccessible(coin.token) {
                                if let priceValue = coin.priceValue {
                                    HStack {
                                        Text(priceValue)
                                            .foregroundColor(.LL.Neutrals.neutrals7)
                                            .font(.inter(size: 14, weight: .regular))

                                        Text(coin.changeString)
                                            .foregroundColor(coin.changeColor)
                                            .font(.inter(size: 12, weight: .semibold))
                                            .frame(height: 22)
                                            .padding(.horizontal, 6)
                                            .background(coin.changeBG)
                                            .cornerRadius(11, style: .continuous)
                                    }
                                }
                            } else {
                                Text("Inaccessible".localized)
                                    .foregroundStyle(Color.Flow.Font.inaccessible)
                                    .font(Font.inter(size: 10, weight: .semibold))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 5)
                                    .background(.Flow.Font.inaccessible.opacity(0.16))
                                    .cornerRadius(4, style: .continuous)
                            }

                            Spacer()

                            if coin.priceValue != nil {
                                Text(
                                    vm
                                        .isHidden ? "****" :
                                        "\(CurrencyCache.cache.currencySymbol)\(coin.balanceAsCurrentCurrency)"
                                )
                                .foregroundColor(.LL.Neutrals.neutrals7)
                                .font(.inter(size: 14, weight: .regular))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(minHeight: CoinCellHeight)

                if EVMAccountManager.shared.selectedAccount == nil && ChildAccountManager.shared
                    .selectedChildAccount == nil
                {
                    HStack(spacing: 0) {
                        Divider()
                            .frame(width: 1, height: 10)
                            .foregroundColor(Color.LL.Neutrals.neutrals4)

                        Spacer()
                    }
                    .padding(.leading, 24)
                    .offset(y: -5)
                    .visibility(coin.token.isFlowCoin && stakingManager.isStaked ? .visible : .gone)

                    Button {
                        StakingManager.shared.goStakingAction()
                    } label: {
                        HStack(spacing: 0) {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(Color.LL.Neutrals.neutrals4)

                            Text("staked_flow".localized)
                                .foregroundColor(.LL.Neutrals.text)
                                .font(.inter(size: 14, weight: .semibold))
                                .padding(.leading, 31)

                            Spacer()

                            Text(
                                "\(vm.isHidden ? "****" : stakingManager.stakingCount.formatCurrencyStringForDisplay(digits: 2)) FLOW"
                            )
                            .foregroundColor(.LL.Neutrals.text)
                            .font(.inter(size: 14, weight: .medium))
                        }
                    }
                    .padding(.leading, 19)
                    .padding(.bottom, 12)
                    .visibility(coin.token.isFlowCoin && stakingManager.isStaked ? .visible : .gone)
                }
            }
            .padding(.horizontal, 16)
            .background(.clear)
            .cornerRadius(16)
        }
    }
}

// MARK: - WalletActionButton

struct WalletActionButton: View {
    enum Action: String {
        case send, receive, swap, stake, buy

        // MARK: Internal

        var icon: String {
            switch self {
            case .send:
                return "icon_token_send"
            case .receive:
                return "icon_token_recieve"
            case .swap:
                return "wallet-swap-stroke"
            case .stake:
                return "icon_wallet_action_stake"
            case .buy:
                return "WalletIconBuy"
            }
        }

        // MARK: Private

        private func incrementUrl() -> String {
            if LocalUserDefaults.shared.flowNetwork == .mainnet {
                return "https://app.increment.fi/swap"
            } else {
                return "https://demo.increment.fi/swap"
            }
        }
    }

    let event: Action
    let allowClick: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack {
                HStack(alignment: .center) {
                    VStack {
                        Image(event.icon)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.white.opacity(allowClick ? 1 : 0.3))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.vertical, 10)
                .frame(width: 50, height: 50, alignment: .center)
                .background(Color.Theme.Accent.green)
                .cornerRadius(25)

                Text(event.rawValue.localized.capitalized)
                    .font(.inter(size: 12))
                    .foregroundStyle(Color.Theme.Text.black8.opacity(allowClick ? 1 : 0.3))
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!allowClick)
    }
}

// MARK: - VisualEffectView

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context _: UIViewRepresentableContext<Self>)
        -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context _: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

#Preview {
    Group {
        WalletHomeView.CoinCell(coin: WalletViewModel.WalletCoinItemModel.mock())
            .environmentObject(WalletViewModel())
            .preferredColorScheme(.dark)
    }
}

#Preview {
    Group {
        WalletHomeView()
            .preferredColorScheme(.dark)
    }
}

// MARK: - VisualEffectBlur

struct VisualEffectBlur: UIViewRepresentable {
    var effect: UIBlurEffect.Style

    func makeUIView(context _: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: effect))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        uiView.effect = UIBlurEffect(style: effect)
    }
}

extension StackTransformViewOptions {
    static let flowStack: StackTransformViewOptions = .init(
        scaleFactor: 0.06,
        minScale: 0.00,
        maxScale: 1.00,
        maxStackSize: 4,
        spacingFactor: 0.12,
        maxSpacing: nil,
        alphaFactor: 0.05,
        bottomStackAlphaSpeedFactor: 10.00,
        topStackAlphaSpeedFactor: 0.10,
        perspectiveRatio: 0.00,
        shadowEnabled: true,
        shadowColor: .black,
        shadowOpacity: 0.06,
        shadowOffset: .zero,
        shadowRadius: 10.00,
        stackRotateAngel: 0.00,
        popAngle: 0.00,
        popOffsetRatio: .init(width: -0.50, height: 0.30),
        stackPosition: .init(x: -0.08, y: 1.00),
        reverse: false,
        blurEffectEnabled: false,
        maxBlurEffectRadius: 0.00,
        blurEffectStyle: .light
    )
}
