//
//  BlockedWebsiteView.swift
//  Flow Wallet
//
//  Created by Trae AI on 1/1/2023.
//

import SnapKit
import UIKit

class BlockedWebsiteView: UIView {
    // MARK: - Properties

    var reportAction: (() -> Void)?
    var ignoreAction: (() -> Void)?
    var blockedURL: URL?

    // MARK: - UI Components

    private var bgColor: UIColor = UIColor.Theme.Accent.red!

    private lazy var iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = bgColor.withAlphaComponent(0.1)
        return view
    }()

    private lazy var globeIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "block_icon_web"))
        imageView.tintColor = bgColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var warningIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        imageView.tintColor = bgColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "blocklist_title".localized
        label.font = .interBold(size: 18)
        label.textColor = .Theme.Text.black8
        label.textAlignment = .center
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        let fullText = "blocklist_desc".localized

        let attributedString = NSMutableAttributedString(string: fullText)
        let reportRange = (fullText as NSString).range(of: "blocklist_desc_skip".localized)

        attributedString.addAttributes([
            .font: UIFont.inter(size: 14),
            .foregroundColor: bgColor,
        ], range: NSRange(location: 0, length: fullText.count))

        attributedString.addAttributes([
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.inter(size: 14),
        ], range: reportRange)

        label.attributedText = attributedString
        label.textAlignment = .center
        label.numberOfLines = 0

        // 添加点击手势
        label.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOnDescription(_:)))
        label.addGestureRecognizer(tapGesture)

        return label
    }()

    private lazy var ignoreButton: UIButton = {
        let button = UIButton(type: .system)
        let title = "blocklist_ignore".localized
        let attributedTitle = NSAttributedString(string: title, attributes: [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: UIColor.darkGray,
            .font: UIFont.inter(size: 14),
        ])
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(ignoreButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .Theme.Background.grey

        let containerView = UIView()
        containerView.backgroundColor = bgColor.withAlphaComponent(0.1)
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = bgColor.cgColor
        containerView.layer.cornerRadius = 8.0
        addSubview(containerView)

        containerView.addSubview(iconContainer)
        iconContainer.addSubview(globeIcon)
        iconContainer.addSubview(warningIcon)

        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)

        addSubview(ignoreButton)

        containerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.center.equalToSuperview()
        }

        setupConstraints(in: containerView)
    }

    private func setupConstraints(in containerView: UIView) {
        iconContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(64)
            make.top.equalToSuperview().offset(24)
        }

        globeIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(64)
        }

        warningIcon.snp.makeConstraints { make in
            make.centerX.equalTo(globeIcon.snp.right)
            make.bottom.equalTo(globeIcon.snp.bottom)
            make.width.height.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
            make.left.right.equalToSuperview().inset(16)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
        }

        ignoreButton.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
        }
    }

    // MARK: - Actions

    @objc private func handleTapOnDescription(_ gesture: UITapGestureRecognizer) {
        let label = gesture.view as! UILabel
        let fullText = "blocklist_desc".localized
        let reportRange = (fullText as NSString).range(of: "blocklist_desc_skip".localized)

        if let text = label.attributedText?.string {
            let tapLocation = gesture.location(in: label)
            if let textPosition = getCharacterIndex(at: tapLocation, label: label, text: text) {
                if NSLocationInRange(textPosition, reportRange) {
                    reportAction?()
                }
            }
        }
    }

    private func getCharacterIndex(at point: CGPoint, label: UILabel, text: String) -> Int? {
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        let characterIndex = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        if characterIndex < text.count {
            return characterIndex
        }

        return nil
    }

    @objc private func reportButtonTapped() {
        reportAction?()
    }

    @objc private func ignoreButtonTapped() {
        ignoreAction?()
    }

    // MARK: - Public Methods

    func setBlockedURL(_ url: URL) {
        blockedURL = url
        let title = (url.host() ?? "") + " " + "blocklist_title".localized
        titleLabel.text = title
    }
}
