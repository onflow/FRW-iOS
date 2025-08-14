//
//  BrowserActionBarView.swift
//  Flow Wallet
//
//  Created by Selina on 1/9/2022.
//

import Hero
import SnapKit
import UIKit

let BrowserActionBarViewHeight: CGFloat = 78
private let BtnWidth: CGFloat = 44
private let BtnHeight: CGFloat = 40
private let ProgressViewHeight: CGFloat = 4

// MARK: - BrowserActionBarView

class BrowserActionBarView: UIView {
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

    var bookmarkAction: ((Bool) -> Void)?
    var clearCookie: EmptyClosure?

    lazy var backBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "icon-btn-back"))
        btn.tintColor = .white
        btn.showsMenuAsPrimaryAction = true

        btn.snp.makeConstraints { make in
            make.width.equalTo(BtnWidth)
            make.height.equalTo(BtnHeight)
        }
        return btn
    }()

    lazy var homeBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "icon-btn-close"))
        btn.tintColor = .white

        btn.snp.makeConstraints { make in
            make.width.equalTo(BtnWidth)
            make.height.equalTo(BtnHeight)
        }
        return btn
    }()

    lazy var moveBtn: UIButton = {
        let btn = UIButton(type: .custom)
      let image = UIImage(named: "icon_token_send")?.withRenderingMode(.alwaysTemplate)
        btn.setImage(image, for: .normal)
        btn.setImage(image,for: .selected)
        btn.tintColor = .white

        btn.snp.makeConstraints { make in
            make.width.equalTo(BtnWidth)
            make.height.equalTo(BtnHeight)
        }

        return btn
    }()

    lazy var reloadBtn: UIButton = {
        let btn = UIButton(type: .custom)
      let image = UIImage(named: "icon-btn-reload-stop")?.withRenderingMode(.alwaysTemplate)
        btn.setImage(image, for: .normal)
        btn.setImage(image,for: .selected)
        btn.tintColor = .white

        btn.snp.makeConstraints { make in
            make.width.equalTo(BtnWidth)
            make.height.equalTo(BtnHeight)
        }

        return btn
    }()

    lazy var menuBtn: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(named: "icon-btn-menu"))
        btn.tintColor = .white

        btn.snp.makeConstraints { make in
            make.width.equalTo(BtnWidth)
            make.height.equalTo(BtnHeight)
        }
        return btn
    }()

    lazy var addressBarContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.heroID = "addressBarContainer"
        return view
    }()

    lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .interSemiBold(size: 14)
        label.text = ""
        return label
    }()

    lazy var progressView: BrowserProgressView = {
        let view = BrowserProgressView()
        view.progress = 0.5

        view.snp.makeConstraints { make in
            make.height.equalTo(ProgressViewHeight)
        }
        return view
    }()

    // MARK: Private

    private lazy var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [
            backBtn,
            moveBtn,
            addressBarContainer,
            menuBtn,
            homeBtn,
        ])
        view.axis = .horizontal
        view.spacing = 0
        return view
    }()

    private lazy var addressBarBgView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.24).cgColor
        view.layer.cornerRadius = 12
        view.alpha = 0.8
//        view.isUserInteractionEnabled = false
        return view
    }()

    private func setup() {
        backgroundColor = .clear

        snp.makeConstraints { make in
            make.height.equalTo(BrowserActionBarViewHeight)
        }

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

//        contentView.addSubview(blurView)
//        blurView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }

        setupAddressBarView()

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.top.equalTo(10)
            make.height.equalTo(BtnHeight)
        }

        contentView.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
    }

    private func setupAddressBarView() {
        addressBarContainer.addSubview(addressBarBgView)
        addressBarBgView.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.right.equalTo(-12)
            make.top.bottom.equalToSuperview()
        }

        addressBarBgView.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }

        addressBarBgView.addSubview(reloadBtn)
        reloadBtn.snp.makeConstraints { make in
            make.left.equalTo(addressLabel.snp.right).offset(0)
            make.centerY.equalToSuperview()
            make.right.equalTo(-0)
        }
    }
}

extension BrowserActionBarView {
    func updateMenu(currentURL: URL?) {
        var children = [UIAction]()

        if let url = currentURL {
            let isBookmarked = DBManager.shared.webBookmarkIsExist(url: url.absoluteString)
            let bookmarkAction = UIAction(
                title: "browser_bookmark".localized,
                image: UIImage(systemName: isBookmarked ? .starFill : .star)
            ) { [weak self] _ in
                guard let self = self else { return }
                self.bookmarkAction?(!isBookmarked)
            }
            let clearCacheAction = UIAction(
                title: "clean cookie".localized,
                image: UIImage(systemName: "trash.slash")
            ) { [weak self] _ in
                guard let self = self else { return }
                self.clearCookie?()
            }

            children.append(bookmarkAction)
            children.append(clearCacheAction)
        }

        menuBtn.showsMenuAsPrimaryAction = true
        menuBtn.menu = UIMenu(title: "", children: children)
    }
}
