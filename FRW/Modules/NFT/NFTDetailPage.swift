//
//  NFTDetailPage.swift
//  Flow Wallet
//
//  Created by cat on 2022/5/16.
//

import AVKit
import Kingfisher
import SPIndicator
import SwiftUI
import SwiftUIX

// MARK: - NFTDetailPage

struct NFTDetailPage: RouteableView {
    // MARK: Lifecycle

    init(viewModel: NFTTabViewModel, nft: NFTModel, from childAccount: ChildAccount? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _vm = StateObject(wrappedValue: NFTDetailPageViewModel(nft: nft))
        fromChildAccount = childAccount
    }

    // MARK: Internal

    static var ShareNFTView: NFTShareView?

    static var retryCount: Int = 0

    @StateObject
    var viewModel: NFTTabViewModel

    @StateObject
    var vm: NFTDetailPageViewModel

    @State
    var opacity: Double = 0

    @State
    var image: Image?
    @State
    var rect: CGRect = .zero

    @State
    var viewState = CGSize.zero
    @State
    var isDragging = false

    @State
    var showImageViewer = false

    @Namespace
    var heroAnimation: Namespace.ID

    var player = AVPlayer()

    var fromChildAccount: ChildAccount?

    var title: String {
        ""
    }

    var isNavigationBarHidden: Bool {
        true
    }

    var theColor: Color {
//        if let color = viewModel.state.colorsMap[vm.nft.imageURL.absoluteString]?[safe: 1] {
//            return color.adjustbyTheme()
//        }
        Color.LL.Primary.salmonPrimary
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            OffsetScrollViewWithAppBar(title: "") {
                Spacer()
                    .frame(height: 64)
                CalloutView(
                    type: .warning,
                    corners: [.topLeading, .topTrailing, .bottomTrailing, .bottomLeading],
                    content: calloutTitle()
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
                .visibility(
                    WalletManager.shared.accessibleManager
                        .isAccessible(vm.nft) ? .gone : .visible
                )
                VStack(alignment: .leading) {
                    VStack(spacing: 0) {
                        if vm.nft.isSVG {
                            SVGWebView(svg: vm.svgString)
                                .aspectRatio(1.0, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .padding(.horizontal, 18)
                                .onTapGesture {
                                    showImageViewer.toggle()
                                }
                                .onAppear {
                                    fetchColor()
                                }
                        } else if let video = vm.nft.video {
                            VideoPlayer(player: player)
                                .onAppear {
                                    if player.currentItem == nil {
                                        let item = AVPlayerItem(url: video)
                                        player.replaceCurrentItem(with: item)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        player.play()
                                    }
                                }
                                .frame(
                                    width: UIScreen.screenWidth - 16 * 2,
                                    height: UIScreen.screenWidth - 16 * 2
                                )
                        }
//                        else if let base64ImageData = vm.nft.imageData {
//                            let provider = Base64ImageDataProvider.init(base64String: base64ImageData, cacheKey: vm.nft.id)
//                            KFImage.source(.provider(provider))
//                                .placeholder {
//                                    Image("placeholder")
//                                        .resizable()
//                                }
//                                .onSuccess { _ in
//                                    fetchColor()
//                                }
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(alignment: .center)
//                                .cornerRadius(8)
//                                .padding(.horizontal, 18)
//                                .clipped()
//                                .scaleEffect(isDragging ? 0.9 : 1)
//                                .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8), value: isDragging)
//
//                                .rotation3DEffect(Angle(degrees: 5), axis: (x: viewState.width, y: viewState.height, z: 0))
//                                .modifier(DragGestureViewModifier(onStart: nil, onUpdate: { value in
//                                    self.viewState = value.translation
//                                    self.isDragging = true
//                                }, onEnd: {
//                                    self.viewState = .zero
//                                    self.isDragging = false
//                                }, onCancel: {
//                                    self.viewState = .zero
//                                    self.isDragging = false
//                                }))
//                                .coordinateSpace(name: "NFTImage")
//                                .onTapGesture {
//                                    showImageViewer.toggle()
//                                }
//                                .matchedGeometryEffect(id: "imageView", in: heroAnimation)
//                                .visible(!showImageViewer)
//                        }
                        else {
                            KFImage
                                .url(vm.nft.imageURL)
                                .placeholder {
                                    Image("placeholder")
                                        .resizable()
                                }
                                .onSuccess { _ in
                                    fetchColor()
                                }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(alignment: .center)
                                .cornerRadius(8)
                                .padding(.horizontal, 18)
                                .clipped()
                                .scaleEffect(isDragging ? 0.9 : 1)
                                .animation(
                                    .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.8),
                                    value: isDragging
                                )
                                .rotation3DEffect(
                                    Angle(degrees: 5),
                                    axis: (x: viewState.width, y: viewState.height, z: 0)
                                )
                                .modifier(DragGestureViewModifier(onStart: nil, onUpdate: { value in
                                    self.viewState = value.translation
                                    self.isDragging = true
                                }, onEnd: {
                                    self.viewState = .zero
                                    self.isDragging = false
                                }, onCancel: {
                                    self.viewState = .zero
                                    self.isDragging = false
                                }))
                                .coordinateSpace(name: "NFTImage")
                                .onTapGesture {
                                    showImageViewer.toggle()
                                }
                                .matchedGeometryEffect(id: "imageView", in: heroAnimation)
                                .visible(!showImageViewer)
                        }

                        HStack(alignment: .center, spacing: 0) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(vm.nft.title)
                                    .font(.LL.largeTitle3)
                                    .fontWeight(.w700)
                                    .foregroundColor(.LL.Neutrals.text)
                                    .frame(height: 28)

                                Button {
                                    NotificationCenter.default.post(
                                        name: .openNFTCollectionList,
                                        object: vm.nft.collection?.id
                                    )
                                } label: {
                                    HStack(alignment: .center, spacing: 6) {
                                        KFImage
                                            .url(vm.nft.logoUrl)
                                            .placeholder {
                                                Image("placeholder")
                                                    .resizable()
                                            }
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 20, height: 20, alignment: .center)
                                            .cornerRadius(20)
                                            .clipped()
                                        Text(vm.nft.collectionName)
                                            .font(.LL.body)
                                            .fontWeight(.w400)
                                            .lineLimit(1)
                                            .foregroundColor(.LL.Neutrals.text2)
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 26)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        if !vm.nft.tags.isEmpty {
                            NFTTagsView(tags: vm.nft.tags, color: theColor)
                        }

                        Text(vm.nft.declare)
                            .font(Font.inter(size: 14, weight: .w400))
                            .foregroundColor(.LL.Neutrals.text)
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.LL.bgForIcon.opacity(0.5)
                    )
                    .shadow(color: .LL.Shades.front, radius: 16, x: 0, y: 8)
                    .cornerRadius(16)
                }

            } appBar: {
                BackAppBar(rightButton: .share {
                    Task {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        let image = await vm.image()
                        let itemSource = ShareActivityItemSource(
                            shareText: vm.nft.title,
                            shareImage: image
                        )
                        let activityController = UIActivityViewController(
                            activityItems: [image, vm.nft.title, itemSource],
                            applicationActivities: nil
                        )
                        activityController.isModalInPresentation = true
                        UIApplication.shared.windows.first?.rootViewController?.present(
                            activityController,
                            animated: true,
                            completion: nil
                        )
                    }
                }) {
                    viewModel.trigger(.back)
                }
            }
            .halfSheet(showSheet: $vm.isPresentMove, autoResizing: true, backgroundColor: Color.Theme.Background.grey) {
                MoveSingleNFTView(nft: vm.nft, fromChildAccount: fromChildAccount) {
                    withAnimation {
                        DispatchQueue.main.async {
                            vm.isPresentMove = false
                        }
                    }

                    Router.pop()
                }
            }
        }
        .background(
            NFTBlurImageView(
                colors: viewModel.state
                    .colorsMap[vm.nft.imageURL.absoluteString] ?? []
            )
            .ignoresSafeArea()
            .offset(y: -4)
        )
        .safeAreaInset(edge: .bottom, content: {
            HStack(spacing: 8) {
                Spacer()

                Button {
                    vm.sendNFTAction(fromChildAccount: fromChildAccount)
                } label: {
                    HStack {
                        Image(systemName: "paperplane")
                            .font(.system(size: 16))
                            .foregroundColor(theColor.opacity(childOpacity))
                        Text("send".localized)
                            .foregroundColor(.LL.Neutrals.text.opacity(childOpacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .cornerRadius(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: theColor.opacity(0.1), radius: 15, x: 0, y: 5)
                .visibility(vm.showSendButton ? .visible : .gone)
                .disabled(!WalletManager.shared.accessibleManager.isAccessible(vm.nft))

                Button {
                    vm.showMoveAction()
                } label: {
                    HStack {
                        Image("icon_move")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 20, height: 20)
                            .foregroundColor(theColor.opacity(childOpacity))
                        Text("move".localized)
                            .foregroundColor(.LL.Neutrals.text.opacity(childOpacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .cornerRadius(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: theColor.opacity(0.1), radius: 15, x: 0, y: 5)
                .visibility(vm.movable ? .visible : .gone)
                .disabled(!WalletManager.shared.accessibleManager.isAccessible(vm.nft))

                Menu {
                    Button {
                        Task {
                            let image = await vm.image()
                            ImageSaver().writeToPhotoAlbum(image: image)
                        }
                    } label: {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 16))
                            .foregroundColor(theColor)
                        Text("download".localized)
                            .foregroundColor(.LL.Neutrals.text)
                    }

                    if let urlString = vm.nft.response.externalURL,
                       let url = URL(string: urlString)
                    {
                        Button {
                            Router.route(to: RouteMap.Explore.browser(url))
                        } label: {
                            HStack {
                                Text("view_on_web".localized)
                                    .foregroundColor(.LL.Neutrals.text)
                                Image(systemName: "globe.asia.australia")
                                    .font(.system(size: 16))
                                    .foregroundColor(theColor)
                            }
                        }
                    }

                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(theColor)
                    Text("more".localized)
                        .foregroundColor(.LL.Neutrals.text)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .cornerRadius(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: theColor.opacity(0.1), radius: 15, x: 0, y: 5)
            }
            .padding(.trailing, 18)
        })
        .onAppear {
            isFavorited = NFTUIKitCache.cache.isFav(id: vm.nft.id)
            vm.animationView.play()
        }
        .overlay(
            ImageViewer(
                imageURL: vm.nft.imageURL.absoluteString,
                viewerShown: $showImageViewer,
                backgroundColor: viewModel.state.colorsMap[vm.nft.imageURL.absoluteString]?
                    .first ?? .LL.background,
                heroAnimation: heroAnimation
            )
        )
        .animation(.spring(), value: showImageViewer)
        .applyRouteable(self)
    }

    var childOpacity: CGFloat {
        WalletManager.shared.accessibleManager.isAccessible(vm.nft) ? 1 : 0.3
    }

    var date: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("purchase_price".localized)
                        .font(.LL.body)
                        .frame(height: 22)
                        .foregroundColor(.LL.Neutrals.neutrals7)
                    HStack(alignment: .center, spacing: 4) {
                        Image("Flow")
                            .resizable()
                            .frame(width: 12, height: 12)
                        Text("1,289.20")
                            .font(Font.W700(size: 16))
                            .foregroundColor(.LL.Neutrals.text)
                            .frame(height: 24)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text("purchase_date".localized)
                        .font(.LL.body)
                        .frame(height: 22)
                        .foregroundColor(.LL.Neutrals.neutrals7)
                    Text("2022.01.22")
                        .font(Font.W700(size: 16))
                        .foregroundColor(.LL.Neutrals.text)
                        .frame(height: 24)
                }
            }
            .padding(0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
    }

    func fetchColor() {
        viewModel.trigger(.fetchColors(vm.nft.imageURL.absoluteString))
    }

    func share() {
        if let colors = viewModel.state.colorsMap[vm.nft.imageURL.absoluteString] {
            NFTDetailPage.ShareNFTView = NFTShareView(nft: vm.nft, colors: colors)
            let img = NFTDetailPage.ShareNFTView.snapshot()
            image = Image(uiImage: img)
            NFTDetailPage.ShareNFTView = nil
        } else {
            NFTDetailPage.retryCount += 1
            if NFTDetailPage.retryCount < 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    share()
                }
            } else {
                NFTDetailPage.retryCount = 0
                // TODO: share error
            }
        }
    }

    // MARK: Private

    @State
    private var isSharePresented: Bool = false

    @State
    private var isFavorited: Bool = false

    @State
    private var items: [UIImage] = []

    private func calloutTitle() -> String {
        let token = vm.nft.title
        let desc = "accessible_not_x_x".localized(token, "Child")
        return desc
    }
}

// MARK: - NFTDetailPage_Previews

struct NFTDetailPage_Previews: PreviewProvider {
    static var nft = NFTTabViewModel.testNFT()

    static var previews: some View {
        NFTDetailPage(viewModel: NFTTabViewModel(), nft: nft)
    }
}
