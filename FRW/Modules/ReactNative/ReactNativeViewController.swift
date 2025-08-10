//
//  ReactNativeViewController.swift
//  FRW
//
//  Created by Claude on 2025-07-06.
//

import UIKit
import Factory

extension ReactNativeViewController {
  enum Route: String {
    case home = "home"
    case selectAssets = "SelectTokens"
    case selectAddress = "SendTo"
    case sendToken = "SendTokens"
  }

}

class ReactNativeViewController: UIViewController {

  var initialProps: RNBridge.InitialProps? = nil
  
    // Static identifier for easy identification
    static let identifier = "ReactNativeViewController"

    // Static container to track all ReactNativeViewController instances
    public static var instances: [ReactNativeViewController] = []

    // Instance identifier for tracking specific instances
    let instanceId = UUID().uuidString

    @Injected(\.wallet)
    private var wallet: WalletManager

    private var reactView: UIView?
  
  init(initialProps: RNBridge.InitialProps? = nil) {
    self.initialProps = initialProps
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
    deinit {
        // Remove from instances when destroyed
        ReactNativeViewController.instances.removeAll { $0 === self }
        print("✅ DEBUG: ReactNativeViewController destroyed: \(instanceId)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set accessibility identifier for easy finding
        view.accessibilityIdentifier = "\(ReactNativeViewController.identifier)_\(instanceId)"

        loadReactNativeView()

      ReactNativeViewController.instances.append(self)
    }

    // Static method to get the most recent instance
    static func getLatestInstance() -> ReactNativeViewController? {
        return instances.last
    }

    // Static method to dismiss all instances
    static func dismissAll() {
        for instance in instances {
            instance.dismiss(animated: true, completion: nil)
        }
        instances.removeAll()
        print("✅ DEBUG: Dismissed all ReactNativeViewController instances")
    }

    // Static method to dismiss the most recent instance
    static func dismissLatest() {
        if let latest = instances.last {
            latest.dismiss(animated: true, completion: nil)
            instances.removeLast()
            print("✅ DEBUG: Dismissed latest ReactNativeViewController: \(latest.instanceId)")
        } else {
            print("❌ DEBUG: No ReactNativeViewController instances found")
        }
    }

    // Static method to debug current state
    static func debugInstances() {
        print("🔍 DEBUG: Current instances count: \(instances.count)")
        for (index, instance) in instances.enumerated() {
            print("  [\(index)] Instance ID: \(instance.instanceId)")
        }
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

        var props: [String: Any] = [
            "address" : wallet.selectedAccount?.address.hexAddr ?? "",
            "network" : wallet.currentNetwork.rawValue,
            "initialRoute" : initialProps?.route.rawValue ?? "SelectTokens",
            "embedded" : false
        ]
        
        // Merge with additional initial props if provided
        let dic = try? initialProps?.toDictionary()
        props["initialProps"] = dic
        

        print("🚀 DEBUG: Creating RCTSurfaceHostingView")

        // Create RCTSurface with proper parameters
        let surfaceView = factory.rootViewFactory.view(
            withModuleName: "FRWRN",
            initialProperties: props
        )

        // Create RCTSurfaceHostingView
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

        self.reactView = surfaceView
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
}

extension RNBridge.InitialProps {
  var route: ReactNativeViewController.Route {
    if screen == .sendAsset {
      guard let config = sendToConfig else {
        return .selectAssets
      }
      if config.targetAddress != nil && config.selectedToken != nil {
        return .sendToken
      } else if config.selectedToken != nil {
        return .selectAddress
      } else if (config.selectedNFTs != nil && ((config.selectedNFTs?.count ?? 0) > 0) )  {
        return .selectAddress
      }
    }
    return .selectAssets
  }
}
