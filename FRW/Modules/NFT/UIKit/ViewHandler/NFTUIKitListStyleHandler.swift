//
//  NFTUIKitListStyleHandler.swift
//  Flow Wallet
//
//  Created by Selina on 15/8/2022.
//

import Kingfisher
import SnapKit
import SwiftUI
import UIKit

private let PinnedHeaderHeight: CGFloat = 80
private let CollecitonTitleViewHeight: CGFloat = 32

// MARK: - NFTUIKitListStyleHandler.Section

extension NFTUIKitListStyleHandler {
    enum Section: Int {
        case other
        case nft
    }
}

// MARK: - NFTUIKitListStyleHandler

class NFTUIKitListStyleHandler: NSObject {
    // MARK: Internal

    lazy var dataModel: NFTUIKitListNormalDataModel = {
        let dm = NFTUIKitListNormalDataModel()
        dm.reloadCallback = { [weak self] in
            self?.reloadViews()
            self?.dataDidUpdate?(self?.dataModel.items.count ?? 0)
        }

        return dm
    }()

    var offsetCallback: ((CGFloat) -> Void)?
    var dataDidUpdate: ((Int) -> Void)?

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.LL.Neutrals.background
        return view
    }()

    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.contentInsetAdjustmentBehavior = .never
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.register(
            NFTUIKitCollectionPinnedSectionView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "PinHeader"
        )
        view.register(
            NFTUIKitCollectionPinnedSectionView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "PinFooter"
        )
        view.register(NFTUIKitItemCell.self, forCellWithReuseIdentifier: "NFTUIKitItemCell")
        view.register(
            NFTUIKitCollectionRegularItemCell.self,
            forCellWithReuseIdentifier: "NFTUIKitCollectionRegularItemCell"
        )
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")

        view.setRefreshingAction { [weak self] in
            guard let self = self else {
                return
            }

            self.refreshAction()
        }

        return view
    }()

    var vm: NFTTabViewModel? {
        didSet {
            favContainerView.vm = vm
        }
    }

    func setup() {
        setupBlurBgView()

        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }

        let offset = Router.coordinator.window.safeAreaInsets.top + 44.0
        containerView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(-offset)
        }
        emptyView.isHidden = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadViews),
            name: .nftFavDidChanged,
            object: nil
        )
        reloadBgView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCollectionsDidChanged),
            name: .nftCollectionsDidChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openCollectionListNoti(noti:)),
            name: .openNFTCollectionList,
            object: nil
        )
    }

    // MARK: Private

    private var isInitRequested: Bool = false
    private var isRequesting: Bool = false

    private lazy var emptyView: NFTUIKitListStyleHandler.EmptyView = {
        let view = NFTUIKitListStyleHandler.EmptyView()
        view.button.addTarget(self, action: #selector(onAddButtonClick), for: .touchUpInside)
        return view
    }()

    private lazy var blurBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var bgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        return imageView
    }()

    private lazy var blurEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        return view
    }()

    private lazy var blurMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        layer.startPoint = CGPoint(x: 0.5, y: 0)
        layer.endPoint = CGPoint(x: 0.5, y: 1)
        return layer
    }()

    private lazy var collectionHContainer: NFTUIKitCollectionHContainerView = {
        let view = NFTUIKitCollectionHContainerView()
        view.items = dataModel.items
        view.didSelectIndexCallback = { [weak self] newIndex in
            guard let self = self else {
                return
            }

            self.changeSelectCollectionIndexAction(newIndex)
        }

        view.reloadViews()
        return view
    }()

    private lazy var favContainerView: NFTUIKitFavContainerView = {
        let view = NFTUIKitFavContainerView()
        view.pageChangeCallback = { [weak self] _ in
            self?.reloadBgView()
        }
        return view
    }()

    private lazy var layout: UICollectionViewFlowLayout = {
        let viewLayout = UICollectionViewFlowLayout()
        viewLayout.scrollDirection = .vertical
        viewLayout.sectionHeadersPinToVisibleBounds = true
        return viewLayout
    }()

    private func setupBlurBgView() {
        let offset = Router.coordinator.window.safeAreaInsets.top + 44.0

        containerView.addSubview(blurBgView)
        blurBgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(-offset)
            make.height.equalTo(offset + NFTUIKitFavContainerView.calculateViewHeight())
        }

        blurBgView.addSubview(bgImageView)
        bgImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurBgView.addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurMaskLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: Router.coordinator.window.bounds.size.width,
            height: offset + NFTUIKitFavContainerView.calculateViewHeight()
        )
        blurBgView.layer.mask = blurMaskLayer
    }

    @objc
    private func onCollectionsDidChanged() {
        collectionView.beginRefreshing()
    }

    @objc
    private func reloadViews() {
        if dataModel.items.isEmpty {
            showEmptyView()
        } else {
            hideEmptyView()
        }

        reloadBgView()

        collectionView.reloadData()
        collectionView.setNoMoreData(dataModel.selectedCollectionItem?.isEnd ?? true)

        setupLoadingActionIfNeeded()
    }

    private func reloadBgView() {
        blurBgView.isHidden = NFTUIKitCache.cache.favList.isEmpty

        if !blurBgView.isHidden, favContainerView.currentIndex < NFTUIKitCache.cache.favList.count {
            let model = NFTUIKitCache.cache.favList[favContainerView.currentIndex]
            bgImageView.kf.setImage(
                with: model.imageURL,
                placeholder: UIImage(named: "placeholder"),
                options: [.transition(.fade(0.25)), .forceTransition]
            )
        }
    }

    private func setupLoadingActionIfNeeded() {
        if dataModel.isCollectionListStyle {
            collectionView.removeLoadingAction()
            return
        }

        if collectionView.mj_footer == nil {
            collectionView.setLoadingAction { [weak self] in
                guard let self = self else {
                    return
                }

                self.loadMoreAction()
            }
        }
    }

    @objc
    private func onAddButtonClick() {
        Router.route(to: RouteMap.NFT.addCollection)
    }

    @objc
    private func openCollectionListNoti(noti: Notification) {
        if let id = noti.object as? String, let vm = vm {
            for item in dataModel.items {
                if item.collectionId == id {
                    Router.route(to: RouteMap.NFT.collection(vm, item))
                    return
                }
            }
        }
    }
}

extension NFTUIKitListStyleHandler {
    func requestDataIfNeeded() {
        if dataModel.items.isEmpty, !isRequesting, !isInitRequested {
            collectionView.beginRefreshing()
        }
    }

    func refreshAction() {
        if isRequesting {
            collectionView.stopRefreshing()
            return
        }

        guard WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() != nil
        else {
            showEmptyView()
            return
        }

        isRequesting = true

        hideErrorView()
        hideEmptyView()

        NFTUIKitCache.cache.requestFav()

        Task {
            do {
                try await dataModel.refreshCollectionAction()
                try? await WalletManager.shared.accessibleManager.fetchNFT()
                await MainActor.run {
                    self.isRequesting = false
                    self.isInitRequested = true

                    if self.collectionView.isRefreshing() {
                        self.collectionView.stopRefreshing()
                    }

                    if !self.dataModel.items.isEmpty {
                        self.changeSelectCollectionIndexAction(0)
                    } else {
                        self.reloadViews()
                    }
                }

            } catch {
                log.debug("[NFT] \(error)")
                await MainActor.run {
                    self.isRequesting = false
                    self.isInitRequested = true

                    if self.collectionView.isRefreshing() {
                        self.collectionView.stopRefreshing()
                    }

                    if self.dataModel.items.isEmpty {
                        self.showErrorView()
                    } else {
                        HUD.error(title: "request_failed".localized)
                    }
                }
            }
        }
    }

    private func loadMoreAction() {
        guard let collectionItem = dataModel.selectedCollectionItem else {
            return
        }

        if collectionItem.isEnd {
            if collectionView.isLoading() {
                collectionView.stopLoading()
            }

            collectionView.setNoMoreData(true)
            return
        }

        let snapshotIndex = dataModel.selectedIndex
        collectionItem.loadCallback = { [weak self] result in
            guard let self = self else {
                return
            }

            if snapshotIndex != self.dataModel.selectedIndex {
                // invalid callback
                return
            }

            if self.dataModel.isCollectionListStyle == true {
                // invalid callback
                return
            }

            if self.collectionView.isLoading() {
                self.collectionView.stopLoading()
            }

            if result {
                self.reloadViews()
            } else {
                HUD.error(title: "request_failed".localized)
            }
        }

        collectionItem.load()
    }
}

extension NFTUIKitListStyleHandler {
    private func changeSelectCollectionIndexAction(_ newIndex: Int) {
        dataModel.selectedIndex = newIndex
        collectionHContainer.items = dataModel.items
        collectionHContainer.selectedIndex = dataModel.selectedIndex
        collectionHContainer.reloadViews()
        reloadViews()

        DispatchQueue.main.async {
            self.loadCurrentCollectionNFTsIfNeeded()
        }
    }

    private func loadCurrentCollectionNFTsIfNeeded() {
        if let item = dataModel.selectedCollectionItem, !dataModel.isCollectionListStyle,
           item.nfts.isEmpty, !item.isRequesting, !item.isEnd
        {
            collectionView.beginLoading()
        }
    }

    @objc
    private func onSwitchButtonClick() {
        collectionView.scrollToTop(animated: false)

        dataModel.isCollectionListStyle.toggle()
        reloadViews()
    }
}

extension NFTUIKitListStyleHandler {
    private func showLoadingView() {}

    private func hideLoadingView() {}

    private func showEmptyView() {
        emptyView.isHidden = false
    }

    private func hideEmptyView() {
        emptyView.isHidden = true
    }

    private func showErrorView() {}

    private func hideErrorView() {}
}

// MARK: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

extension NFTUIKitListStyleHandler: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offsetY = scrollView.contentOffset.y
        if offsetY <= 0 {
            offsetY = 0
        }

        blurBgView.transform = CGAffineTransform(translationX: 0, y: -offsetY)

        offsetCallback?(offsetY)
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        2
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == Section.other.rawValue {
            return NFTUIKitCache.cache.favList.isEmpty ? 0 : 1
        }

        if dataModel.isCollectionListStyle {
            return dataModel.items.count
        }

        return dataModel.selectedCollectionItem?.nfts.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.section == Section.other.rawValue {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "UICollectionViewCell",
                for: indexPath
            )
            cell.contentView.backgroundColor = .clear

            if favContainerView.superview != cell.contentView {
                cell.contentView.addSubview(favContainerView)
                favContainerView.snp.makeConstraints { make in
                    make.left.right.top.bottom.equalToSuperview()
                }
            }

            return cell
        }

        if dataModel.isCollectionListStyle {
            let collection = dataModel.items[indexPath.item]
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "NFTUIKitCollectionRegularItemCell",
                for: indexPath
            ) as! NFTUIKitCollectionRegularItemCell
            cell.config(collection)
            return cell
        }

        if let nftList = dataModel.selectedCollectionItem?.nfts, indexPath.item < nftList.count {
            let nft = nftList[indexPath.item]
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "NFTUIKitItemCell",
                for: indexPath
            ) as! NFTUIKitItemCell
            cell.config(nft)
            return cell
        } else {
            log.info("[NFT] data may be is invalid.")
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "UICollectionViewCell",
                for: indexPath
            )
            cell.contentView.backgroundColor = .clear
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath.section == Section.other.rawValue {
            return CGSize(
                width: collectionView.bounds.size.width,
                height: NFTUIKitFavContainerView.calculateViewHeight()
            )
        }

        if dataModel.isCollectionListStyle {
            return NFTUIKitCollectionRegularItemCell.calculateSize()
        }

        return NFTUIKitItemCell.calculateSize()
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        referenceSizeForHeaderInSection _: Int
    ) -> CGSize {
        return .zero
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        referenceSizeForFooterInSection _: Int
    ) -> CGSize {
        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if indexPath.section == Section.other.rawValue {
            if !dataModel.isCollectionListStyle, kind == UICollectionView.elementKindSectionFooter {
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "PinFooter",
                    for: indexPath
                )

                return footer
            }
        }

        if kind != UICollectionView.elementKindSectionHeader {
            return UICollectionReusableView()
        }

        if dataModel.isCollectionListStyle {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "PinHeader",
                for: indexPath
            )
            header.removeSubviews()

            return header
        }

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "PinHeader",
            for: indexPath
        )
        header.removeSubviews()
        collectionHContainer.removeFromSuperview()
        header.addSubview(collectionHContainer)
        collectionHContainer.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }

        return header
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        minimumLineSpacingForSectionAt _: Int
    ) -> CGFloat {
        if dataModel.isCollectionListStyle {
            return 12
        }

        return 18
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt _: Int
    ) -> CGFloat {
        if dataModel.isCollectionListStyle {
            return 12
        }

        return 18
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        if section == Section.other.rawValue {
            return .zero
        }

        return UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section != Section.nft.rawValue {
            return
        }

        guard let vm = vm else {
            return
        }

        if !dataModel.isCollectionListStyle, let nftList = dataModel.selectedCollectionItem?.nfts,
           indexPath.item < nftList.count
        {
            let nft = nftList[indexPath.item]
            Router.route(to: RouteMap.NFT.detail(vm, nft, nil))
            return
        }

        if dataModel.isCollectionListStyle, indexPath.item < dataModel.items.count {
            let collectionItem = dataModel.items[indexPath.item]
            Router.route(to: RouteMap.NFT.collection(vm, collectionItem))
        }
    }
}

// MARK: NFTUIKitListStyleHandler.EmptyView

extension NFTUIKitListStyleHandler {
    class EmptyView: UIView {
        // MARK: Lifecycle

        override init(frame: CGRect) {
            super.init(frame: frame)
            setup()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("")
        }

        // MARK: Internal

        lazy var button: UIButton = {
            let btn = UIButton(type: .custom)
            let bg = UIImage.image(withColor: UIColor.LL.Secondary.mango4.withAlphaComponent(0.08))
            btn.setBackgroundImage(bg, for: .normal)

            btn.setTitle("get_new_nft".localized, for: .normal)
            btn.setTitleColor(UIColor.LL.Secondary.mangoNFT, for: .normal)
            btn.titleLabel?.font = .interSemiBold(size: 14)

            btn.contentEdgeInsets = UIEdgeInsets(top: 10, left: 43, bottom: 10, right: 43)

            btn.clipsToBounds = true
            btn.layer.cornerRadius = 12

            return btn
        }()

        // MARK: Private

        private lazy var bgImageView: UIView = {
            let view = UIHostingController(rootView: NFTEmptyView()).view ?? UIView()
//            UIImageView(image: UIImage(named: "nft_empty_bg"))
            view.contentMode = .scaleAspectFill
            view.clipsToBounds = true
            return view
        }()

        private lazy var iconImageView: UIImageView = {
            let view = UIImageView(image: UIImage(named: "icon-empty"))
            return view
        }()

        private lazy var titleLabel: UILabel = {
            let view = UILabel()
            view.font = .inter(size: 16, weight: .semibold)
            view.textColor = UIColor.Theme.Text.black3
            view.text = "nft_empty_v2".localized
            return view
        }()

        private lazy var detailLabel: UILabel = {
            let view = UILabel()
            view.font = .inter(size: 14)
            view.textColor = UIColor.Theme.Text.black3
            view.text = "nft_empty_detail".localized
            return view
        }()

        private func setup() {
            addSubview(bgImageView)
            bgImageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            addSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview().offset(-70)
            }

            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(iconImageView.snp.bottom).offset(16)
            }

            addSubviews(detailLabel)
            detailLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
            }

            // Hide it for now
//            addSubview(button)
//            button.snp.makeConstraints { make in
//                make.centerX.equalToSuperview()
//                make.top.equalTo(descLabel.snp.bottom).offset(36)
//            }
        }
    }
}
