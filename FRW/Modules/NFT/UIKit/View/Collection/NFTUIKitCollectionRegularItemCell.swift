//
//  NFTUIKitCollectionRegularItemCell.swift
//  Flow Wallet
//
//  Created by Selina on 13/8/2022.
//

import Kingfisher
import SnapKit
import SwiftUI
import UIKit

private let CellHeight: CGFloat = 64
private let IconSize: CGFloat = 48
private let Padding: CGFloat = 8

// MARK: - NFTUIKitCollectionRegularItemCell

class NFTUIKitCollectionRegularItemCell: UICollectionViewCell {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static func calculateSize() -> CGSize {
        let width = Router.coordinator.window.bounds.size.width - 18 * 2
        return CGSize(width: width, height: CellHeight)
    }

    func config(_ item: CollectionItem) {
        self.item = item

        iconImageView.kf.setImage(with: item.iconURL)
        titleLabel.text = item.showName
        descLabel.text = "x_collections".localized(item.count)
        if let info = item.collection, !WalletManager.shared.accessibleManager.isAccessible(info) {
            descLabel.isHidden = true
            inaccessibleLabel.isHidden = false
        } else {
            descLabel.isHidden = false
            inaccessibleLabel.isHidden = true
        }
    }

    // MARK: Private

    private var item: CollectionItem?

    private lazy var iconImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.snp.makeConstraints { make in
            make.width.height.equalTo(IconSize)
        }
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = .montserratBold(size: 14)
        view.textColor = UIColor.LL.neutrals1
        return view
    }()

    private lazy var markIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "Flow")
        view.snp.makeConstraints { make in
            make.width.height.equalTo(12)
        }
        return view
    }()

    private lazy var descLabel: UILabel = {
        let view = UILabel()
        view.font = .inter(size: 14)
        view.textColor = UIColor.LL.note
        return view
    }()

    private lazy var inaccessibleLabel: UIView = {
        let container = UIView()
        container.layer.cornerRadius = 4
        container.backgroundColor = UIColor.Theme.Accent.grey?.withAlphaComponent(0.16)
        container.setContentHuggingPriority(.required, for: .horizontal)

        let view = UILabel()
        view.font = .inter(size: 10)
        view.textAlignment = .center
        view.text = "Inaccessible".localized
        view.textColor = UIColor.Theme.Accent.grey
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)

        container.addSubview(view)
        view.snp.makeConstraints { make in
            make.top.left.equalTo(5)
            make.bottom.right.equalTo(-5)
        }
        container.frame = CGRect(x: 0, y: 0, width: 70, height: 22)
        return container
    }()

    private lazy var hStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, markIcon])
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.spacing = 5
        return stackView
    }()

    private lazy var emptyView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [hStackView, descLabel, inaccessibleLabel])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading
        stackView.spacing = 3
        return stackView
    }()

    private lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "arrow_right_grey")?.withRenderingMode(.alwaysTemplate)
        view.tintColor = UIColor.LL.Primary.salmonPrimary
        return view
    }()

    private func setup() {
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.left.equalTo(Padding)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(Padding)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.left.equalTo(stackView.snp.right).offset(Padding)
        }

        contentView.backgroundColor = UIColor.LL.frontColor
        contentView.layer.cornerRadius = 16
    }
}
