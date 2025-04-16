//
//  NFTViewStyleMenuController.swift
//  Flow Wallet
//
//  Created by Trae AI on 2023/12/01
//

import UIKit

class NFTViewStyleMenuController: UIViewController {
    // MARK: - Properties

    private var menuView: NFTViewStyleMenu!
    var currentStyle: NFTViewStyle = .list
    var styleSelectedCallback: ((NFTViewStyle) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = UIColor.clear

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)

        menuView = NFTViewStyleMenu()
        menuView.delegate = self
        menuView.setCurrentStyle(currentStyle)
        view.addSubview(menuView)

        menuView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(38)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-18)
        }
    }

    // MARK: - Actions

    @objc private func backgroundTapped() {
        dismiss(animated: true)
    }

    // MARK: - Public Methods

    static func show(from viewController: UIViewController,
                     currentStyle: NFTViewStyle,
                     callback: @escaping (NFTViewStyle) -> Void)
    {
        let menuController = NFTViewStyleMenuController()
        menuController.currentStyle = currentStyle
        menuController.styleSelectedCallback = callback
        menuController.modalPresentationStyle = .overFullScreen
        menuController.modalTransitionStyle = .crossDissolve
        viewController.present(menuController, animated: true)
    }
}

// MARK: - NFTViewStyleMenuDelegate

extension NFTViewStyleMenuController: NFTViewStyleMenuDelegate {
    func didSelectViewStyle(_ style: NFTViewStyle) {
        styleSelectedCallback?(style)
        dismiss(animated: true)
    }
}
