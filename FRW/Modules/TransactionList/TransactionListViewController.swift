//
//  TransactionListViewController.swift
//  Flow Wallet
//
//  Created by Selina on 9/9/2022.
//

import SnapKit
import SwiftUI
import UIKit

// MARK: - TransactionListViewController

class TransactionListViewController: UIViewController {
    // MARK: Lifecycle

    init(contractId: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.contractId = contractId
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    private(set) var contractId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        reloadCounts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: Private

    private lazy var transferHandler: TransferListHandler = {
        let handler = TransferListHandler(contractId: contractId)
        handler.countChangeCallback = { [weak self] in
            self?.reloadCounts()
        }
        return handler
    }()

    private lazy var segmentDataSource: JXSegmentedTitleDataSource = {
        let ds = JXSegmentedTitleDataSource()
//        ds.titles = [ "transaction_list_transfer_x".localized()]
        let textColor = UIColor(named: "text.black.8")!
        ds.titleNormalColor = textColor
        ds.titleSelectedColor = textColor
        ds.titleNormalFont = .interMedium(size: 14)
        ds.titleSelectedFont = .interMedium(size: 14)
        ds.isTitleColorGradientEnabled = true
        ds.itemSpacing = 0
        ds.itemWidth = Router.coordinator.window.bounds.size.width
        return ds
    }()

    private lazy var indicator: JXSegmentedIndicatorLineView = {
        let view = JXSegmentedIndicatorLineView()
        view.indicatorCornerRadius = 0
        view.indicatorHeight = 2
        view.indicatorColor = UIColor(named: "line.black")!
        return view
    }()

    private lazy var segmentView: JXSegmentedView = {
        let view = JXSegmentedView()
        view.delegate = self
        view.dataSource = segmentDataSource
        view.indicators = [indicator]
        view.contentEdgeInsetLeft = 0
        view.contentEdgeInsetRight = 0
        return view
    }()

    private lazy var listContainer: JXSegmentedListContainerView = {
        let view = JXSegmentedListContainerView(dataSource: self)
        return view
    }()

    private func setup() {
        view.backgroundColor = UIColor.LL.Neutrals.background

        navigationItem.hidesBackButton = true
        navigationItem.title = "wallet_transactions".localized

        if (navigationController?.viewControllers.firstIndex(of: self) ?? 0) > 0 {
            let backItem = UIBarButtonItem(
                image: UIImage(systemName: "arrow.backward"),
                style: .plain,
                target: self,
                action: #selector(onBackButtonAction)
            )
            backItem.tintColor = UIColor(named: "button.color")
            navigationItem.leftBarButtonItem = backItem
        }

        view.addSubview(segmentView)
        segmentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.height.equalTo(0)
        }

        view.addSubview(listContainer)
        listContainer.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(segmentView.snp.bottom)
        }

        segmentView.listContainer = listContainer
    }
    
    @objc private func onBackButtonAction() {
        Router.pop()
    }
}

extension TransactionListViewController {
    private func reloadCounts() {
//        segmentDataSource.titles = ["transaction_list_transfer_x".localized()]
        segmentView.reloadData()
    }
}

// MARK: JXSegmentedListContainerViewDataSource

extension TransactionListViewController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in _: JXSegmentedListContainerView) -> Int {
        1
    }

    func listContainerView(
        _: JXSegmentedListContainerView,
        initListAt _: Int
    ) -> JXSegmentedListContainerViewListDelegate {
        transferHandler
    }
}

// MARK: JXSegmentedViewDelegate

extension TransactionListViewController: JXSegmentedViewDelegate {}

// MARK: AppTabBarPageProtocol

extension TransactionListViewController: AppTabBarPageProtocol {
    static func tabTag() -> AppTabType {
        .txhistory
    }

    static func iconName() -> String {
        "tabler-icon-clock"
    }
    
    static func title() -> String {
        "Activity::message".localized
    }
}
