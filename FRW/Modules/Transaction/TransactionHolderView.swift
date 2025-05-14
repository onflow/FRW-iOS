//
//  TransactionHolderView.swift
//  Flow Wallet
//
//  Created by Selina on 26/8/2022.
//

import Flow
import Kingfisher
import SnapKit
import SwiftUI
import UIKit
import Combine

private let PanelHolderViewWidth: CGFloat = 48

// MARK: - TransactionHolderView.Status

extension TransactionHolderView {
    enum Status {
        case dragging
        case left
        case right
    }
}

// MARK: - TransactionHolderView

class TransactionHolderView: UIView {
    // MARK: Lifecycle
    
    private var cancellables: Set<AnyCancellable> = []

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

    static func defaultPanelHolderFrame() -> CGRect {
        let size = Router.coordinator.window.bounds.size
        let x = size.width - PanelHolderViewWidth
        let y = size.height * 0.6
        return CGRect(x: x, y: y, width: PanelHolderViewWidth, height: PanelHolderViewWidth)
    }

    static func createView() -> TransactionHolderView {
        TransactionHolderView(
            frame: LocalUserDefaults.shared
                .panelHolderFrame ?? defaultPanelHolderFrame()
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        reloadBgPaths()
    }

    // MARK: Private

    private lazy var bgMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    private lazy var progressView: TransactionProgressView = {
        let view = TransactionProgressView()
        return view
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.LL.Button.text
        return view
    }()

    private var status: TransactionHolderView.Status = .right {
        didSet {
            reloadBgPaths()
        }
    }

    private func setup() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 4)

        addSubviews(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.layer.mask = bgMaskLayer

        contentView.addSubviews(progressView)
        progressView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let gesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(onPanelHolderPan(gesture:))
        )
        addGestureRecognizer(gesture)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tap)

        start()
    }

    private func start() {
        flow.publisher.transactionPublisher
            .filter{ $0.0 == self.model?.transactionId }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] (id, result) in
                self?.refreshView(status: result.status)
            })
            .store(in: &cancellables)
    }

    private func reloadBgPaths() {
        bgMaskLayer.frame = bounds

        var corner: UIRectCorner
        switch status {
        case .dragging:
            corner = [.allCorners]
        case .right:
            corner = [.topLeft, .bottomLeft]
        case .left:
            corner = [.topRight, .bottomRight]
        }

        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corner,
            cornerRadii: CGSize(width: 12.0, height: 12.0)
        )
        bgMaskLayer.path = path.cgPath
    }

    @objc
    private func onTap() {
        TransactionUIHandler.shared.showListView()
    }

    @objc
    private func onPanelHolderPan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            status = .dragging
        case .ended, .cancelled, .failed:
            detectPosition()
        case .changed:
            let location = gesture.location(in: superview)
            center = location
        default:
            break
        }
    }

    private func detectPosition() {
        let window = Router.coordinator.window
        let height = window.bounds.size.height
        let width = window.bounds.size.width
        let midX = frame.midX

        status = midX > width / 2.0 ? .right : .left

        var finalFrame = frame
        finalFrame.origin.x = status == .right ? width - PanelHolderViewWidth : 0

        if finalFrame.origin.y < window.safeAreaInsets.top + 44 {
            finalFrame.origin.y = window.safeAreaInsets.top + 44
        } else if finalFrame.maxY > height - window.safeAreaInsets.bottom - 44 {
            finalFrame.origin.y = height - window.safeAreaInsets.bottom - PanelHolderViewWidth - 44
        }

        UIView.animate(withDuration: 0.25) {
            self.frame = finalFrame
        } completion: { _ in
        }

        saveCurrentFrame(finalFrame)
    }

    private func saveCurrentFrame(_ frame: CGRect) {
        LocalUserDefaults.shared.panelHolderFrame = frame
    }

    private func refreshView(status: Flow.Transaction.Status) {
        if let iconURL = model?.icon() {
            progressView.iconImageView.kf.setImage(
                with: iconURL,
                placeholder: UIImage(named: "placeholder")
            )
        } else {
            progressView.iconImageView.image = UIImage(named: "flow")
        }

        progressView.progress = status.progressPercent
    }
}

extension TransactionHolderView {
    func show(inView _: UIView) {
        alpha = 1
        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 5,
            options: .curveEaseInOut
        ) {
            self.transform = .identity
        } completion: { _ in
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.25) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    func config(model: TransactionManager.TransactionHolder) {
        if let current = self.model, current.transactionId.hex == model.transactionId.hex {
            return
        }

        self.model = model
        refreshView(status: model.status)
    }
}
