//
//  TransferListHandler.swift
//  Flow Wallet
//
//  Created by Selina on 9/9/2022.
//

import UIKit

private let AllTransfersListCacheKey = "AllTransfersListCacheKey"
private let AllTransfersListCountKey = "AllTransfersListCountKey"
private let Limit: Int = 30
private let CellHeight: CGFloat = 66

// MARK: - TransferListHandler

class TransferListHandler: TransactionListBaseHandler {
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
        view.register(FlowTransferItemCell.self, forCellWithReuseIdentifier: "FlowTransferItemCell")
        view.register(
            FlowTransactionViewMoreFooter.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "FlowTransactionViewMoreFooter"
        )
        view.setRefreshingAction { [weak self] in
            guard let self = self else {
                return
            }

            if self.collectionView.isLoading() {
                self.collectionView.stopRefreshing()
                return
            }

            self.requestTransfers()
        }

        view.setLoadingAction { [weak self] in
            guard let self = self else {
                return
            }

            if self.collectionView.isRefreshing() {
                self.collectionView.stopLoading()
                return
            }

            guard let next = self.next else {
                self.collectionView.stopLoading()
                self.collectionView.setNoMoreData(true)
                return
            }

            self.requestTransfers(start: next)
        }

        return view
    }()

    private var dataList: [FlowScanTransfer] = []
    private var next: String?

    private var isRequesting: Bool = false

    private var cacheKey: String {
        if contractId != nil {
            return "transfer_contractId_\(contractId ?? "")_key"
        } else {
            return AllTransfersListCacheKey
        }
    }

    private func setup() {
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        collectionView.beginRefreshing()

        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .accountDataDidUpdate) {
                await self?.collectionView.beginRefreshing()
            }
        }
    }

    private func loadCache() {
        totalCount = UserDefaults.standard.integer(forKey: AllTransfersListCountKey)

        Task {
            if let cacheList = try? await PageCache.cache.get(
                forKey: cacheKey,
                type: [FlowScanTransfer].self
            ) {
                DispatchQueue.main.async {
                    self.dataList = cacheList
                    self.collectionView.reloadData()
                }
            }
        }
    }
}

extension TransferListHandler {
    func requestTransfers(start: String = "") {
        if isRequesting {
            return
        }

        isRequesting = true
        Task {
            do {
                if let contractId = self.contractId {
                    let request = TokenTransfersRequest(
                        address: WalletManager.shared.getPrimaryWalletAddress() ?? "",
                        limit: Limit,
                        after: start,
                        token: contractId
                    )
                    let response: TransfersResponse = try await Network
                        .request(FRWAPI.Account.tokenTransfers(request))
                    await MainActor.run {
                        self.isRequesting = false
                        self.requestSuccess(response, start: start)
                    }
                } else {
                    let request = TransfersRequest(
                        address: WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() ?? "",
                        limit: Limit,
                        after: start
                    )
                    let target = WalletManager.shared.isSelectedEVMAccount ? FRWAPI.Account.evmTransfers(request) : FRWAPI.Account.transfers(request)
                    let response: TransfersResponse = try await Network.request(target)
                    await MainActor.run {
                        self.isRequesting = false
                        self.requestSuccess(response, start: start)
                    }
                }
            } catch {
                debugPrint("TransferListHandler -> requestTransfers failed: \(error)")

                await MainActor.run {
                    self.isRequesting = false
                    self.collectionView.stopRefreshing()
                    self.collectionView.stopLoading()
                    HUD.error(title: "transfer_request_failed".localized)
                }
            }
        }
    }

    private func requestSuccess(_ response: TransfersResponse, start: String) {
        var list = [FlowScanTransfer]()
        if let responseList = response.transactions {
            list = responseList
        }

        if start == "" {
            PageCache.cache.set(value: list, forKey: cacheKey)
        }

        collectionView.stopRefreshing()
        collectionView.stopLoading()

        if start == "" {
            dataList = list
        } else {
            dataList.append(contentsOf: list)
        }

        collectionView.reloadData()

        if let next = response.string {
            self.next = next
            collectionView.setNoMoreData(list.count < Limit)
        } else {
            collectionView.setNoMoreData(true)
        }

        totalCount = response.total ?? dataList.count
        UserDefaults.standard.set(totalCount, forKey: AllTransfersListCountKey)
    }
}

// MARK: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

extension TransferListHandler: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        dataList.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let item = dataList[indexPath.item]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "FlowTransferItemCell",
            for: indexPath
        ) as! FlowTransferItemCell
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

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataList[indexPath.item]
        UISelectionFeedbackGenerator().selectionChanged()
        if let txid = item.txid {
            let network = currentNetwork
            let accountType = AccountType.current
            let url = network.getTransactionHistoryUrl(accountType: accountType, transactionId: txid)

            url.map { Router.route(to: RouteMap.Explore.browser($0)) }
        }
    }

    func collectionView(
        _: UICollectionView,
        layout _: UICollectionViewLayout,
        referenceSizeForFooterInSection _: Int
    ) -> CGSize {
        if WalletManager.shared.isSelectedEVMAccount && dataList.count > 0 {
            return CGSize(width: 0, height: 44)
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
}
