//
//  ReactNativeCoordinator.swift
//  FRW
//
//  Created by Claude on 2025-08-15.
//

import UIKit
import Foundation

// MARK: - WeakRef Wrapper
class WeakRef<T: AnyObject> {
    weak var value: T?
    init(_ value: T) {
        self.value = value
    }
}

// MARK: - ReactNativeCoordinator
class ReactNativeCoordinator {
    static let shared = ReactNativeCoordinator()
    
    // Private storage for controllers with weak references
    private var controllers: [String: WeakRef<ReactNativeViewController>] = [:]
    private var stack: [String] = [] // Maintains display order (LIFO - Last In, First Out)
    private let queue = DispatchQueue(label: "com.frw.rn.coordinator", qos: .userInitiated)
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Register a new ReactNativeViewController instance
    /// - Parameters:
    ///   - controller: The ReactNativeViewController instance
    ///   - id: Unique identifier for this instance
    func register(_ controller: ReactNativeViewController, id: String) {
        queue.async { [weak self] in
            self?.controllers[id] = WeakRef(controller)
            self?.stack.append(id)
            self?.cleanup()
            
            DispatchQueue.main.async { [weak self] in
                print("✅ DEBUG: ReactNativeCoordinator registered instance: \(id)")
                self?.printCurrentState()
            }
        }
    }
    
    /// Close the most recently opened ReactNativeViewController
    func closeLatest() {
        queue.async { [weak self] in
            self?.cleanup()
            
            guard let latestId = self?.stack.last,
                  let controller = self?.controllers[latestId]?.value else {
                DispatchQueue.main.async {
                    print("❌ DEBUG: No ReactNativeViewController instances found to close")
                }
                return
            }
            
            DispatchQueue.main.async {
                print("🔄 DEBUG: Closing latest ReactNativeViewController: \(latestId)")
                self?.closeController(controller, id: latestId)
            }
        }
    }
    
    /// Close a specific ReactNativeViewController by ID
    /// - Parameter id: The unique identifier of the controller to close
    func closeById(_ id: String) {
        queue.async { [weak self] in
            guard let controller = self?.controllers[id]?.value else {
                DispatchQueue.main.async {
                    print("❌ DEBUG: ReactNativeViewController with ID \(id) not found")
                }
                return
            }
            
            DispatchQueue.main.async {
                print("🔄 DEBUG: Closing ReactNativeViewController by ID: \(id)")
                self?.closeController(controller, id: id)
            }
        }
    }
    
    /// Close all ReactNativeViewController instances
    func closeAll() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.cleanup()
            
            let controllersToClose = self.controllers.compactMap { $0.value.value }
            let idsToClose = Array(self.controllers.keys)
            
            DispatchQueue.main.async { [weak self] in
                print("🔄 DEBUG: Closing all \(controllersToClose.count) ReactNativeViewController instances")
                
                // Create a mapping of controllers to their IDs
                var controllerIdMap: [ReactNativeViewController: String] = [:]
                for id in idsToClose {
                    if let controller = self?.controllers[id]?.value {
                        controllerIdMap[controller] = id
                    }
                }
                
                for (index, controller) in controllersToClose.enumerated() {
                    if let id = controllerIdMap[controller] {
                        self?.closeController(controller, id: id, animated: index == 0) // Only animate the first one for better UX
                    }
                }
            }
        }
    }
    
    /// Get the count of currently managed instances
    func getInstanceCount() -> Int {
        return queue.sync { [weak self] in
            guard let self = self else { return 0 }
            self.cleanup()
            return self.controllers.count
        }
    }
    
    /// Get all current instance IDs
    func getCurrentInstanceIds() -> [String] {
        return queue.sync { [weak self] in
            guard let self = self else { return [] }
            self.cleanup()
            return Array(self.controllers.keys)
        }
    }
    
    /// Check if a specific instance ID is currently managed
    /// - Parameter id: The instance ID to check
    /// - Returns: True if the instance exists and is alive
    func hasInstance(id: String) -> Bool {
        return queue.sync { [weak self] in
            guard let self = self else { return false }
            self.cleanup()
            return self.controllers[id]?.value != nil
        }
    }
    
    // MARK: - Private Methods
    
    /// Close a ReactNativeViewController using the appropriate method (dismiss vs pop)
    /// - Parameters:
    ///   - controller: The controller to close
    ///   - id: The controller's ID for unregistration
    ///   - animated: Whether to animate the transition
    private func closeController(_ controller: ReactNativeViewController, id: String, animated: Bool = true) {
        // Check if controller is presented modally
        if controller.presentingViewController != nil {
            print("🔄 DEBUG: Controller \(id) is presented modally - using dismiss")
            controller.dismiss(animated: animated) { [weak self] in
                self?.unregister(id: id)
            }
            return
        }
        
        // Check if controller is in a navigation stack
        if let navigationController = controller.navigationController {
            print("🔄 DEBUG: Controller \(id) is in navigation stack - using pop")
            
            // Check if this is the top view controller in the navigation stack
            if navigationController.topViewController == controller {
                // Pop from navigation stack
                navigationController.popViewController(animated: animated)
                // Unregister after a delay to allow the pop animation to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.35 : 0.0)) { [weak self] in
                    self?.unregister(id: id)
                }
            } else {
                // Controller is somewhere in the middle of the stack
                print("🔄 DEBUG: Controller \(id) is in middle of navigation stack - removing from stack")
                var viewControllers = navigationController.viewControllers
                if let index = viewControllers.firstIndex(of: controller) {
                    viewControllers.remove(at: index)
                    navigationController.setViewControllers(viewControllers, animated: animated)
                }
                self.unregister(id: id)
            }
            return
        }
        
        // Check if controller is a child view controller
        if controller.parent != nil {
            print("🔄 DEBUG: Controller \(id) is a child controller - removing from parent")
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
            self.unregister(id: id)
            return
        }
        
        // Fallback: try to dismiss anyway (this handles edge cases)
        print("⚠️ DEBUG: Controller \(id) has unclear presentation context - attempting dismiss")
        controller.dismiss(animated: animated) { [weak self] in
            self?.unregister(id: id)
        }
    }
    
    /// Unregister a ReactNativeViewController instance
    /// - Parameter id: The unique identifier of the controller to unregister
    private func unregister(id: String) {
        queue.async { [weak self] in
            self?.controllers.removeValue(forKey: id)
            self?.stack.removeAll { $0 == id }
            
            DispatchQueue.main.async { [weak self] in
                print("✅ DEBUG: ReactNativeCoordinator unregistered instance: \(id)")
                self?.printCurrentState()
            }
        }
    }
    
    /// Clean up any nil weak references
    private func cleanup() {
        // Remove controllers with nil values
        controllers = controllers.filter { $0.value.value != nil }
        // Remove stack entries that no longer have corresponding controllers
        stack = stack.filter { controllers[$0]?.value != nil }
    }
    
    /// Print current state for debugging
    private func printCurrentState() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.cleanup()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("🔍 DEBUG: ReactNativeCoordinator State:")
                print("  - Active instances: \(self.controllers.count)")
                print("  - Stack order: \(self.stack)")
                
                for (index, id) in self.stack.enumerated() {
                    let status = self.controllers[id]?.value != nil ? "✅ Active" : "❌ Released"
                    print("    [\(index)] \(id): \(status)")
                }
            }
        }
    }
}

// MARK: - Debug Extension
extension ReactNativeCoordinator {
    /// Print detailed debug information about all managed instances
    func debugAllInstances() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.cleanup()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("🔍 DEBUG: Detailed ReactNativeCoordinator State:")
                print("================================================")
                print("Total managed instances: \(self.controllers.count)")
                print("Stack order (newest first): \(self.stack.reversed())")
                print("================================================")
                
                if self.controllers.isEmpty {
                    print("No active ReactNativeViewController instances")
                } else {
                    for (index, id) in self.stack.enumerated() {
                        if let controller = self.controllers[id]?.value {
                            print("[\(index)] ID: \(id)")
                            print("    - Controller: \(controller)")
                            print("    - Is presented: \(controller.presentingViewController != nil)")
                            print("    - View loaded: \(controller.isViewLoaded)")
                            print("    - Memory address: \(Unmanaged.passUnretained(controller).toOpaque())")
                        }
                    }
                }
                print("================================================")
            }
        }
    }
}
