//
//  NFTUIKitListViewController.swift
//  Flow Wallet
//
//  Created by Selina on 11/8/2022.
//

import Combine
import Hero
import SnapKit
import SwiftUI
import UIKit

class NFTUIKitListViewController: UIViewController {
    // MARK: Internal

    var listStyleHandler = NFTUIKitListStyleHandler()
    var gridStyleHandler = NFTUIKitGridStyleHandler()

    var currentViewStyle: NFTViewStyle = .list

    var style: NFTTabScreen.ViewStyle = .normal {
        didSet {
            reloadViews()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateUI(with: 0)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCustomAddressChanged),
            name: .watchAddressDidChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReset),
            name: .didResetWallet,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onChildAccountChanged),
            name: .childAccountChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onNFTDidChangedByMoving),
            name: .nftDidChangedByMoving,
            object: nil
        )

        WalletManager.shared.$walletInfo
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                log.debug("[NFT] wallet info refresh triggerd a upload token action")
                self.walletInfoDidChanged()
            }.store(in: &cancelSets)
        EVMAccountManager.shared.$selectedAccount
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .map { $0 }
            .sink { _ in
                log.debug("[NFT] refresh NFTs when EVM account did change ")
                self.walletInfoDidChanged()
            }.store(in: &cancelSets)
        listStyleHandler.refreshAction()
        gridStyleHandler.refreshAction()

        addButton.isHidden = ChildAccountManager.shared.selectedChildAccount != nil
    }

    func reloadViews() {
        switch style {
        case .normal:
            gridStyleHandler.containerView.removeFromSuperview()
            if listStyleHandler.containerView.superview != contentView {
                contentView.addSubview(listStyleHandler.containerView)
                listStyleHandler.containerView.snp.makeConstraints { make in
                    make.left.right.top.bottom.equalToSuperview()
                }

                listStyleHandler.requestDataIfNeeded()
            }

            offsetDidChanged(max(0.0, listStyleHandler.collectionView.contentOffset.y))
        case .grid:
            listStyleHandler.containerView.removeFromSuperview()

            if gridStyleHandler.containerView.superview != contentView {
                contentView.addSubview(gridStyleHandler.containerView)
                gridStyleHandler.containerView.snp.makeConstraints { make in
                    make.left.right.top.bottom.equalToSuperview()
                }

                gridStyleHandler.requestDataIfNeeded()
            }

            offsetDidChanged(0)
        }
    }

    // MARK: Private

    private var cancelSets = Set<AnyCancellable>()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.LL.Neutrals.background
        return view
    }()

    private lazy var headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear

        view.snp.makeConstraints { make in
            make.height.equalTo(Router.coordinator.window.safeAreaInsets.top + 44)
        }
        return view
    }()

    private lazy var headerBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.LL.Neutrals.background
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var headerContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.Theme.Text.black8
        label.font = .inter(size: 20, weight: .semibold)
        label.textAlignment = .left
        label.text = "NFT Collections".localized
        return label
    }()

    private lazy var addButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "icon-nft-add"), for: .normal)

        let bgColor = UIColor.LL.Neutrals.neutrals3.withAlphaComponent(0.24)
        btn.setBackgroundImage(UIImage.image(withColor: bgColor), for: .normal)

        btn.clipsToBounds = true
        btn.layer.cornerRadius = 16

        btn.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        btn.addTarget(self, action: #selector(onAddButtonClick), for: .touchUpInside)

        return btn
    }()

    private lazy var menuButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "icon-nft-dot"), for: .normal)

        let bgColor = UIColor.LL.Neutrals.neutrals3.withAlphaComponent(0.24)
        btn.setBackgroundImage(UIImage.image(withColor: bgColor), for: .normal)

        btn.clipsToBounds = true
        btn.layer.cornerRadius = 16

        btn.snp.makeConstraints { make in
            make.width.height.equalTo(32)
        }

        btn.addTarget(self, action: #selector(onClickMenu), for: .touchUpInside)

        return btn
    }()

    @objc
    private func didReset() {
        listStyleHandler.collectionView.beginRefreshing()
        gridStyleHandler.collectionView.beginRefreshing()
    }

    @objc
    private func onCustomAddressChanged() {
        listStyleHandler.collectionView.beginRefreshing()
        gridStyleHandler.collectionView.beginRefreshing()
    }

    @objc
    private func onChildAccountChanged() {
        addButton.isHidden = ChildAccountManager.shared.selectedChildAccount != nil
        listStyleHandler.collectionView.beginRefreshing()
        gridStyleHandler.collectionView.beginRefreshing()
    }

    @objc
    private func onNFTDidChangedByMoving() {
        log.debug("[NFT] move NFT notification")
        listStyleHandler.refreshAction()
        gridStyleHandler.refreshAction()
    }

    private func walletInfoDidChanged() {
        addButton.isHidden = !WalletManager.shared.isSelectedFlowAccount
        listStyleHandler.collectionView.beginRefreshing()
        gridStyleHandler.collectionView.beginRefreshing()
    }

    private func setupViews() {
        view.backgroundColor = UIColor.LL.Neutrals.background
        hero.isEnabled = true
        setupHeaderView()

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerContainerView.snp.bottom)
        }

        listStyleHandler.setup()
        gridStyleHandler.setup()

        listStyleHandler.offsetCallback = { [weak self] offset in
            self?.offsetDidChanged(offset)
        }

        listStyleHandler.dataDidUpdate = { [weak self] count in
            if self?.style == .normal {
                self?.updateUI(with: count)
            }
        }
        gridStyleHandler.dataDidUpdate = { [weak self] count in
            if self?.style == .grid {
                self?.updateUI(with: count)
            }
        }

        view.bringSubviewToFront(headerContainerView)

        reloadViews()
    }

    private func updateUI(with count: Int) {
        menuButton.snp.updateConstraints { make in
            make.width.height.equalTo(count > 0 ? 32 : 0)
        }
        addButton.snp.updateConstraints { make in
            make.right.equalTo(menuButton.snp.left).offset(count > 0 ? -10 : 0)
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.headerContentView.layoutIfNeeded()
        }
    }

    private func offsetDidChanged(_ offset: CGFloat) {
        let alpha = max(0, min(1, offset / 50.0))
        headerBgView.alpha = alpha
    }

    private func setupHeaderView() {
        view.addSubview(headerContainerView)
        headerContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(-Router.coordinator.window.safeAreaInsets.top)
        }

        headerContainerView.addSubview(headerBgView)
        headerBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerContainerView.addSubview(headerContentView)
        headerContentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        headerContentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(18)
            make.centerY.equalToSuperview()
        }

        headerContentView.addSubview(menuButton)
        menuButton.snp.makeConstraints { make in
            make.right.equalTo(-18)
            make.centerY.equalToSuperview()
        }

        headerContentView.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.right.equalTo(menuButton.snp.left).offset(-10)
            make.centerY.equalToSuperview()
        }

        offsetDidChanged(0)
    }

    @objc
    private func onAddButtonClick() {
        Router.route(to: RouteMap.NFT.addCollection)
    }

    @objc
    private func onClickMenu() {
        NFTViewStyleMenuController.show(
            from: self,
            currentStyle: currentViewStyle
        ) { [weak self] newStyle in
            self?.currentViewStyle = newStyle
            self?.updateViewStyle(newStyle)
        }
    }

    private func updateViewStyle(_ style: NFTViewStyle) {
        switch style {
        case .list:
            self.style = .normal
        case .grid:
            self.style = .grid
        }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        feedbackGenerator.impactOccurred()

        reloadViews()
    }
}
