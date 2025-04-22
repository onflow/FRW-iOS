//
//  TransactionListHandler.swift
//  Flow Wallet
//
//  Created by Selina on 9/9/2022.
//

import UIKit

private let Limit: Int = 30
private let CellHeight: CGFloat = 50
private let FooterHeight: CGFloat = 44

private let AllTransactionsListCacheKey = "AllTransactionListCacheKey"
private let AllTransactionListCountKey = "AllTransactionListCountKey"

// MARK: - TransactionListHandler

class TransactionListHandler: TransactionListBaseHandler {
    // MARK: Lifecycle

    override init(contractId: String? = nil) {
        super.init(contractId: contractId)
        setup()
        loadCache()
    }

    // MARK: Internal

    var countChangeCallback: (() -> Void)?

    var totalCount: Int = 0 {
        didSet {
            countChangeCallback?()
        }
    }

    // MARK: Private

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 24
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 24, left: 0, bottom: 0, right: 0)
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = true
        view.dataSource = self
        view.delegate = self
        view.register(
            FlowTransactionItemCell.self,
            forCellWithReuseIdentifier: "FlowTransactionItemCell"
        )
        view.register(
            FlowTransactionViewMoreFooter.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "FlowTransactionViewMoreFooter"
        )

        view.setRefreshingAction { [weak self] in
            guard let self = self else {
                return
            }

            self.requestTransactions()
        }
        return view
    }()

    private var dataList: [FlowScanTransaction] = []
    private var isRequesting: Bool = false
    private var needShowLoadMoreView: Bool = false

    private func setup() {
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        collectionView.beginRefreshing()
    }

    private func loadCache() {
        totalCount = UserDefaults.standard.integer(forKey: AllTransactionListCountKey)

        Task {
            if let cacheList = try? await PageCache.cache.get(
                forKey: AllTransactionsListCacheKey,
                type: [FlowScanTransaction].self
            ) {
                DispatchQueue.main.async {
                    self.dataList = cacheList
                    self.collectionView.reloadData()
                }
            }
        }
    }
}

extension TransactionListHandler {
    func requestTransactions() {
        if isRequesting {
            return
        }

        isRequesting = true
        Task {
            do {
                if let contractId = self.contractId {
                    let results = try await FRWAPI.Account
                        .fetchTokenTransfers(contractId: contractId)
                    DispatchQueue.main.async {
                        self.isRequesting = false
                        self.requestSuccess(results, totalCount: results.count)
                    }
                } else {
                    let results = try await FRWAPI.Account.fetchAccountTransfers()
                    DispatchQueue.main.async {
                        self.isRequesting = false
                        self.requestSuccess(results.0, totalCount: results.1)
                    }
                }
            } catch {
                debugPrint("TransactionListHandler -> requestTransactions failed: \(error)")

                DispatchQueue.main.async {
                    self.isRequesting = false
                    self.collectionView.stopRefreshing()
                    HUD.error(title: "transaction_request_failed".localized)
                }
            }
        }
    }

    private func requestSuccess(_ list: [FlowScanTransaction], totalCount: Int) {
        PageCache.cache.set(value: list, forKey: AllTransactionsListCacheKey)

        var transactions = TransactionManager.shared.holders.map { $0.toFlowScanTransaction }
        transactions.append(contentsOf: list)

        collectionView.stopRefreshing()
        dataList = transactions
        collectionView.reloadData()

        UserDefaults.standard.set(totalCount, forKey: AllTransactionListCountKey)
        self.totalCount = totalCount + TransactionManager.shared.holders.count
        checkIfNeedShowLoadMoreView()
    }

    private func checkIfNeedShowLoadMoreView() {
        needShowLoadMoreView = totalCount >= Limit
        collectionView.reloadData()
    }
}

// MARK: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

extension TransactionListHandler: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        dataList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let item = dataList[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "FlowTransactionItemCell",
            for: indexPath
        ) as! FlowTransactionItemCell
        cell.config(item)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout _: UICollectionViewLayout,
        sizeForItemAt _: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: CellHeight)
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        referenceSizeForFooterInSection _: Int
    ) -> CGSize {
        if needShowLoadMoreView {
            return CGSize(width: 0, height: FooterHeight)
        }

        return .zero
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "FlowTransactionViewMoreFooter",
            for: indexPath
        )
    }

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataList[indexPath.item]
        UISelectionFeedbackGenerator().selectionChanged()
        if let hash = item.hash {
            let network = currentNetwork
            let accountType = AccountType.current
            let url = network.getTransactionHistoryUrl(accountType: accountType, transactionId: hash)
            url.map { Router.route(to: RouteMap.Explore.browser($0)) }
        }
    }
}
