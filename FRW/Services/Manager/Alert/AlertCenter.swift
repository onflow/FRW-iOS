//
//  AlertCenter.swift
//  FRW
//
//  A lightweight global SwiftUI-driven alert/confirmation sheet center.
//  Use from non-UI code via async APIs to await user decision.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Models

enum AlertButtonStyleKind {
    case primary
    case secondary
    case destructive
}

struct AlertAction: Identifiable, Equatable {
    let id: String
    let title: String
    let style: AlertButtonStyleKind

    init(id: String, title: String, style: AlertButtonStyleKind = .primary) {
        self.id = id
        self.title = title
        self.style = style
    }
}

struct AlertModel {
    var title: String?
    var message: String?
    var actions: [AlertAction]
    var customContent: AnyView? = nil
    var wrapsInDefaultContainer: Bool = true
}

// MARK: - AlertCenter

@MainActor
final class AlertCenter: ObservableObject {
    static let shared = AlertCenter()

    // Published model drives the overlay
    @Published var model: AlertModel? = nil

    private var continuation: CheckedContinuation<String, Never>? = nil
    private var overlayWindow: UIWindow?
    private var hostingController: UIHostingController<AlertOverlayView>?

    // Present a fully custom model (including custom content / actions)
    func present(model: AlertModel) async -> String {
        // Cancel any existing alert
        if continuation != nil {
            continuation?.resume(returning: "__cancelled__")
            continuation = nil
        }

        // Ensure we have a window to display the alert
        ensureOverlayWindow()

        self.model = model

        return await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            self.continuation = cont
        }
    }

    private func ensureOverlayWindow() {
        guard overlayWindow == nil else { return }

        // Find the key window
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            log.error("[AlertCenter] No active window scene found")
            return
        }

        // Create a new window for the overlay
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert
        window.backgroundColor = .clear

        // Create the hosting controller
        let overlayView = AlertOverlayView()
        let hosting = UIHostingController(rootView: overlayView)
        hosting.view.backgroundColor = .clear

        window.rootViewController = hosting
        window.isHidden = false

        self.overlayWindow = window
        self.hostingController = hosting

        log.info("[AlertCenter] Overlay window created and shown")
    }

    private func hideOverlayWindow() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
        hostingController = nil
    }

    // Convenience: custom content with actions
    func presentCustom(content: AnyView, actions: [AlertAction]) async -> String {
        let model = AlertModel(
            title: nil,
            message: nil,
            actions: actions,
            customContent: content,
            wrapsInDefaultContainer: false
        )
        return await present(model: model)
    }

    // Convenience: standard confirmation returning Bool
    func presentConfirmation(
        title: String,
        message: String? = nil,
        confirmTitle: String = "OK",
        cancelTitle: String? = "Cancel"
    ) async -> Bool {
        var acts: [AlertAction] = []
        if let cancelTitle = cancelTitle {
            acts.append(AlertAction(id: "cancel", title: cancelTitle, style: .secondary))
        }
        acts.append(AlertAction(id: "confirm", title: confirmTitle, style: .primary))
        let selection = await present(model: AlertModel(title: title, message: message, actions: acts, customContent: nil))
        return selection == "confirm"
    }

    // Convenience: surge pricing confirmation card
    func presentSurgePricingConfirmation(
        feeAmount: String,
        networkDescription: String
    ) async -> Bool {
        let view = SurgePricingAlertView(
            feeAmount: feeAmount,
            networkLoadDescription: networkDescription,
            onAgree: { [weak self] in
                self?.resolve(selection: "agree")
            },
            onClose: { [weak self] in
                self?.cancel()
            }
        )

        let selection = await presentCustom(content: AnyView(view), actions: [])
        return selection == "agree"
    }

    // Resolve with selected action id
    func resolve(selection id: String) {
        model = nil
        continuation?.resume(returning: id)
        continuation = nil

        // Hide the overlay window after a short delay to allow animation
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            hideOverlayWindow()
        }
    }

    // Resolve as cancelled
    func cancel() {
        resolve(selection: "cancel")
    }
}

extension AlertCenter {
  func presentSurge(data: PayerStatusData) async -> Bool {
    let multiplierValue = data.surge?.multiplier?.doubleValue ?? 0
    let maxFee = data.surge?.maxFee ?? 0
    let amount = maxFee
    let multiDisplay = multiplierValue.truncatingRemainder(dividingBy: 1) == 0
      ? String(Int(multiplierValue))
      : String(format: "%.1f", multiplierValue)
    return await presentSurgePricingConfirmation(
      feeAmount: String(format: "%.3f", amount),
      networkDescription: "Due to high network activity, transaction fees are elevated, and Flow Wallet is temporarily not paying for your gas. Current network fees are \(multiDisplay)× higher than usual."
    )
  }
  
  func presentAccountNotFound(onCreate: @escaping EmptyClosure, onCancel: @escaping EmptyClosure) async {
    let view = AccountNotFoundAlertView(onCreateWallet: { [weak self] in
      onCreate()
      self?.resolve(selection: "agree")
    }, onCancel: { [weak self] in
      onCancel()
      self?.cancel()
    })
    _ = await presentCustom(content: AnyView(view), actions: [])
  }

  func presentCOACopy(address: String) async {
    let view = EVMCopyAlertView(address: address) { [weak self] in
      self?.resolve(selection: "agree")
    } onCancel: { [weak self] in
      self?.cancel()
    }
    _ = await presentCustom(content: AnyView(view), actions: [])
  }
}
