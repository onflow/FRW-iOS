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

    // Instance identifier for tracking specific instances (now managed by coordinator)
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
        print("✅ DEBUG: ReactNativeViewController destroyed: \(instanceId)")
        // Coordinator will automatically clean up weak references
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set accessibility identifier for easy finding
        view.accessibilityIdentifier = "\(ReactNativeViewController.identifier)_\(instanceId)"

        loadReactNativeView()
        
        // Register with coordinator for management
        ReactNativeCoordinator.shared.register(self, id: instanceId)
    }

    // Static method to get the most recent instance (deprecated - use coordinator)
    static func getLatestInstance() -> ReactNativeViewController? {
        let ids = ReactNativeCoordinator.shared.getCurrentInstanceIds()
        guard let latestId = ids.last else { return nil }
        
        // This is a workaround - ideally we'd get the instance directly from coordinator
        // For now, we'll traverse the view hierarchy
        return findInstanceById(latestId)
    }
    
    // Helper method to find instance by ID in view hierarchy
    private static func findInstanceById(_ id: String) -> ReactNativeViewController? {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        return findReactNativeViewController(in: rootVC, withId: id)
    }
    
    private static func findReactNativeViewController(in vc: UIViewController, withId id: String) -> ReactNativeViewController? {
        if let rnVC = vc as? ReactNativeViewController, rnVC.instanceId == id {
            return rnVC
        }
        
        // Check presented controller
        if let presented = vc.presentedViewController {
            if let found = findReactNativeViewController(in: presented, withId: id) {
                return found
            }
        }
        
        // Check navigation controller
        if let navVC = vc as? UINavigationController {
            for childVC in navVC.viewControllers {
                if let found = findReactNativeViewController(in: childVC, withId: id) {
                    return found
                }
            }
        }
        
        // Check child controllers
        for child in vc.children {
            if let found = findReactNativeViewController(in: child, withId: id) {
                return found
            }
        }
        
        return nil
    }

    // Static method to dismiss all instances (now uses coordinator)
    static func dismissAll() {
        ReactNativeCoordinator.shared.closeAll()
        print("✅ DEBUG: Requested dismissal of all ReactNativeViewController instances via coordinator")
    }

    // Static method to dismiss the most recent instance (now uses coordinator)
    static func dismissLatest() {
        ReactNativeCoordinator.shared.closeLatest()
        print("✅ DEBUG: Requested dismissal of latest ReactNativeViewController via coordinator")
    }

    // Static method to debug current state (now uses coordinator)
    static func debugInstances() {
        ReactNativeCoordinator.shared.debugAllInstances()
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
        // zh,en,ru,ja
        let languageCode = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        var props: [String: Any] = [
            "address" : wallet.selectedAccount?.address.hexAddr ?? "",
            "network" : wallet.currentNetwork.rawValue,
            "initialRoute" : initialProps?.route.rawValue ?? "SelectTokens",
            "embedded" : false,
            "instanceId": instanceId,
            "language": languageCode
        ]
        
        // Merge with additional initial props if provided
        let dic = try? initialProps?.toDictionary()
        props["initialProps"] = dic
        
      log.info("props:\(props)")
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
