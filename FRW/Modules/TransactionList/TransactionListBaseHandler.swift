//
//  TransactionListBaseHandler.swift
//  Flow Wallet
//
//  Created by Selina on 9/9/2022.
//

import SnapKit
import UIKit

// MARK: - TransactionListBaseHandler

class TransactionListBaseHandler: NSObject {
    // MARK: Lifecycle

    init(contractId: String? = nil) {
        self.contractId = contractId
    }

    // MARK: Internal

    private(set) var contractId: String?

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
}

// MARK: JXSegmentedListContainerViewListDelegate

extension TransactionListBaseHandler: JXSegmentedListContainerViewListDelegate {
    func listView() -> UIView {
        containerView
    }
}
