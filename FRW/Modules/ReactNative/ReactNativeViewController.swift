//
//  ReactNativeViewController.swift
//  FRW
//
//  Created by Claude on 2025-07-06.
//

import UIKit
import React

class ReactNativeViewController: UIViewController {
    
    private var reactView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        loadReactNativeView()
    }
    
    private func setupNavigationBar() {
        title = "React Native View"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        navigationItem.leftBarButtonItem = closeButton
    }
    
    private func loadReactNativeView() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let bridge = appDelegate.getRCTBridge() else {
            showErrorView()
            return
        }
        
        let initialProps: [String: Any] = [:]
        
        let reactView = RCTRootView(
            bridge: bridge,
            moduleName: "FRWRN",
            initialProperties: initialProps
        )
        
        reactView.backgroundColor = UIColor.white
        
        view.addSubview(reactView)
        reactView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            reactView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            reactView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reactView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            reactView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.reactView = reactView
    }
    
    private func showErrorView() {
        let errorLabel = UILabel()
        errorLabel.text = "Failed to load React Native view"
        errorLabel.textAlignment = .center
        errorLabel.textColor = .red
        errorLabel.font = UIFont.systemFont(ofSize: 16)
        
        view.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
