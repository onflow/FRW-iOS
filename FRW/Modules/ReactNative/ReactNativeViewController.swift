//
//  ReactNativeViewController.swift
//  FRW
//
//  Created by Claude on 2025-07-06.
//

import UIKit
import React
import Factory

class ReactNativeViewController: UIViewController {
    
    @Injected(\.wallet)
    private var wallet: WalletManager
    
    private var reactView: UIView?
    private var surface: RCTSurface?
    
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
        print("🔧 DEBUG: Starting Modern React Native Loading")
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("❌ DEBUG: Failed to get AppDelegate")
            showErrorView()
            return
        }
        
        // Try the modern RCTSurfaceHostingView approach first
        loadWithSurfaceHostingView(appDelegate: appDelegate)
    }
    
    private func loadWithSurfaceHostingView(appDelegate: AppDelegate) {
        print("🚀 DEBUG: Using RCTSurfaceHostingView approach")
        
        guard let factory = appDelegate.getRCTReactNativeFactory() else {
            print("❌ DEBUG: Failed to get bridge")
            return
        }
        
        let initialProps: [String: Any] = [
            "address" : wallet.selectedAccount?.address.hexAddr ?? "",
            "network" : wallet.currentNetwork.rawValue,
            "initialRoute" : "Profile",
            "embedded" : false
        ]
        
        print("🚀 DEBUG: Creating RCTSurfaceHostingView")
        
        // Create RCTSurface with proper parameters
        let surfaceView = factory.rootViewFactory.view(
            withModuleName: "FRWRN",
            initialProperties: initialProps
        )
        
        // Create RCTSurfaceHostingView
//        let surfaceView = RCTSurfaceHostingView(surface: surface, sizeMeasureMode: .optimistic)
        surfaceView.backgroundColor = UIColor.systemBackground
        
        // Add to view hierarchy
        view.addSubview(surfaceView)
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            surfaceView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            surfaceView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            surfaceView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            surfaceView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Start the surface
//        surface.start()
        
        self.reactView = surfaceView
//        self.surface = surface
        print("✅ DEBUG: RCTSurfaceHostingView setup complete")
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
