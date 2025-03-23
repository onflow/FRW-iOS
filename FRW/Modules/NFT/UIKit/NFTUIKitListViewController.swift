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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
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
    }
    
    func reloadViews() {
        if listStyleHandler.containerView.superview != contentView {
            contentView.addSubview(listStyleHandler.containerView)
            listStyleHandler.containerView.snp.makeConstraints { make in
                make.left.right.top.bottom.equalToSuperview()
            }
            
            listStyleHandler.requestDataIfNeeded()
        }
    }
    
    // MARK: Private
    
    private var cancelSets = Set<AnyCancellable>()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    @objc
    private func didReset() {
        listStyleHandler.collectionView.beginRefreshing()
    }
    
    @objc
    private func onCustomAddressChanged() {
        listStyleHandler.collectionView.beginRefreshing()
    }
    
    @objc
    private func onChildAccountChanged() {
        listStyleHandler.collectionView.beginRefreshing()
    }
    
    @objc
    private func onNFTDidChangedByMoving() {
        log.debug("[NFT] move NFT notification")
        listStyleHandler.refreshAction()
    }
    
    private func walletInfoDidChanged() {
        listStyleHandler.collectionView.beginRefreshing()
    }
    
    private func setupViews() {
        view.backgroundColor = .clear
        hero.isEnabled = true
        
        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.bottom.top.equalToSuperview()
        }
        
        listStyleHandler.setup()
        
        reloadViews()
    }
}
