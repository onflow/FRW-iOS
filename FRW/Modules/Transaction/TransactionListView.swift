//
//  TransactionListView.swift
//  Flow Wallet
//
//  Created by Selina on 29/8/2022.
//

import Flow
import Kingfisher
import SnapKit
import SwiftUI
import UIKit
import Combine

private let CellHeight: CGFloat = 48

// MARK: - TransactionListCell

class TransactionListCell: UIView {
    // MARK: Lifecycle
    
    var cancellables: Set<AnyCancellable> = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("")
    }

    // MARK: Internal

    private(set) var model: TransactionManager.TransactionHolder?

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadBgPaths()
    }

    func config(_ model: TransactionManager.TransactionHolder) {
        self.model = model
        refreshView()
    }

    // MARK: Private

    private lazy var progressView: TransactionProgressView = {
        let view = TransactionProgressView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.LL.Neutrals.text
        label.font = .inter(size: 14)
        label.text = "pending_transaction".localized
        label.snp.contentHuggingHorizontalPriority = 249
        label.snp.contentCompressionResistanceHorizontalPriority = 749
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: .delete), for: .normal)

        btn.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        return btn
    }()

    private lazy var bgMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.LL.Button.text
        return view
    }()

    private func setup() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 3)

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(progressView.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
        }

//        contentView.addSubview(deleteButton)
//        deleteButton.snp.makeConstraints { make in
//            make.left.equalTo(titleLabel.snp.right).offset(5)
//            make.centerY.equalToSuperview()
//            make.right.equalToSuperview().offset(-5)
//        }

        contentView.layer.mask = bgMaskLayer

        snp.makeConstraints { make in
            make.height.equalTo(CellHeight)
        }

        start()

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tap)
    }

    @objc
    private func onTap() {
        if let id = model?.transactionId {
            Router.route(to: RouteMap.Transaction.detail(id))
        }
    }

    private func start() {
        flow.publisher.transactionPublisher
            .filter{ $0.0 == self.model?.transactionId }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (id, result) in
                self?.refreshView()
            })
            .store(in: &cancellables)
    }

    private func reloadBgPaths() {
        bgMaskLayer.frame = bounds

        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .bottomLeft],
            cornerRadii: CGSize(width: 24.0, height: 24.0)
        )
        bgMaskLayer.path = path.cgPath
    }

    private func refreshView() {
        if let iconURL = model?.icon() {
            progressView.iconImageView.kf.setImage(
                with: iconURL,
                placeholder: UIImage(named: "placeholder")
            )
        } else {
            progressView.iconImageView.image = UIImage(named: "flow")
        }

        if model?.internalStatus == .failed {
            progressView.progress = 1
        } else {
            progressView.progress = model?.status.progressPercent ?? 0
        }

        if let strokeColor = model?.internalStatus.statusColor {
            progressView.changeProgressColor(strokeColor)
        }
    }
}

// MARK: - TransactionListView

class TransactionListView: UIView {
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

    func refresh() {
        removeAllCells()

        for holder in TransactionManager.shared.holders {
            let cell = TransactionListCell()
            cell.config(holder)
            stackView.addArrangedSubview(cell)
        }
    }

    // MARK: Private

    private lazy var bgView: UIVisualEffectView = {
        let view = UIVisualEffectView(style: .systemChromeMaterial)
//        view.backgroundColor = .white.withAlphaComponent(0.7)
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [])
        view.axis = .vertical
        view.spacing = 10
        view.alignment = .trailing
        return view
    }()

    private func setup() {
        backgroundColor = .clear

        addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalTo(40)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        let gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(gesture)
    }

    @objc
    private func onTap() {
        TransactionUIHandler.shared.dismissListView()
    }

    private func removeAllCells() {
        while !stackView.arrangedSubviews.isEmpty {
            let view = stackView.arrangedSubviews.first!
            view.removeFromSuperview()
        }
    }
}
