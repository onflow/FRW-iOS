//
//  NFTViewStyleMenu.swift
//  Flow Wallet
//
//  Created by Trae AI on 2023/12/01
//

import SnapKit
import UIKit

protocol NFTViewStyleMenuDelegate: AnyObject {
    func didSelectViewStyle(_ style: NFTViewStyle)
}

enum NFTViewStyle {
    case list
    case grid
}

class NFTViewStyleMenu: UIView {
    // MARK: - Properties

    weak var delegate: NFTViewStyleMenuDelegate?
    private var currentStyle: NFTViewStyle = .list

    // MARK: - UI Components

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "View as"
        label.textColor = .Theme.Text.black3
        label.font = .inter(size: 9, weight: .semibold)
        return label
    }()

    private lazy var listOptionView: NFTViewStyleOptionView = {
        let view = NFTViewStyleOptionView(
            title: "seg_list".localized,
            iconName: "icon-layout-list",
            isSelected: true
        )
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(listOptionTapped)))
        return view
    }()

    private lazy var gridOptionView: NFTViewStyleOptionView = {
        let view = NFTViewStyleOptionView(
            title: "seg_grid".localized,
            iconName: "nft_logo_grid_layout",
            isSelected: false
        )
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(gridOptionTapped)))
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        backgroundColor = .clear

        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(100)
        }

        containerView.addSubview(titleLabel)
        containerView.addSubview(listOptionView)
        containerView.addSubview(gridOptionView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(16)
        }

        listOptionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(0)
            make.left.right.equalToSuperview()
            make.height.equalTo(32)
        }

        gridOptionView.snp.makeConstraints { make in
            make.top.equalTo(listOptionView.snp.bottom).offset(4)
            make.left.right.equalToSuperview()
            make.height.equalTo(32)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Public Methods

    func setCurrentStyle(_ style: NFTViewStyle) {
        currentStyle = style
        updateOptionViews()
    }

    // MARK: - Private Methods

    private func updateOptionViews() {
        listOptionView.setSelected(currentStyle == .list)
        gridOptionView.setSelected(currentStyle == .grid)
    }

    // MARK: - Actions

    @objc private func listOptionTapped() {
        if currentStyle != .list {
            currentStyle = .list
            updateOptionViews()
            delegate?.didSelectViewStyle(.list)
        }
    }

    @objc private func gridOptionTapped() {
        if currentStyle != .grid {
            currentStyle = .grid
            updateOptionViews()
            delegate?.didSelectViewStyle(.grid)
        }
    }
}

// MARK: - NFTViewStyleOptionView

class NFTViewStyleOptionView: UIView {
    // MARK: - UI Components

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .inter(size: 14, weight: .medium)
        return label
    }()

    // MARK: - Properties

    private var iconName: String
    private var isSelected: Bool = false

    // MARK: - Initialization

    init(title: String, iconName: String, isSelected: Bool = false) {
        self.iconName = iconName
        super.init(frame: .zero)

        titleLabel.text = title
        self.isSelected = isSelected

        setupViews()
        updateAppearance()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        addSubview(iconImageView)
        addSubview(titleLabel)

        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
        }
    }

    // MARK: - Public Methods

    func setSelected(_ selected: Bool) {
        isSelected = selected
        updateAppearance()
    }

    // MARK: - Private Methods

    private func updateAppearance() {
        let selectedColor = UIColor.Theme.Accent.green
        let normalColor = UIColor.Theme.Text.black

        iconImageView.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = isSelected ? selectedColor : normalColor
        titleLabel.textColor = isSelected ? selectedColor : normalColor
    }
}
