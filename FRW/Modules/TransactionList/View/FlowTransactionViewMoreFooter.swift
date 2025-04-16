//
//  FlowTransactionViewMoreFooter.swift
//  Flow Wallet
//
//  Created by Selina on 13/9/2022.
//

import SwiftUI
import UIKit

class FlowTransactionViewMoreFooter: UICollectionReusableView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        let stackView = UIStackView(arrangedSubviews: [titleLabel, arrowImageView])
        stackView.axis = .horizontal
        stackView.spacing = 5

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(gesture)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    // MARK: Private

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.LL.Neutrals.text
        label.font = .inter(size: 14)
        label.text = "view_more_transactions".localized
        return label
    }()

    private lazy var arrowImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 12)
        let imageView = UIImageView(image: UIImage(systemName: .arrowRight, withConfiguration: config))
        imageView.tintColor = UIColor.LL.Neutrals.text
        return imageView
    }()

    @objc
    private func onTap() {
        guard let address = WalletManager.shared.getWatchAddressOrChildAccountAddressOrPrimaryAddress() else {
            return
        }
        let accountType = AccountType.current
        let url = currentNetwork.getAccountUrl(accountType: accountType, address: address)

        url.map { UIApplication.shared.open($0) }
    }
}
