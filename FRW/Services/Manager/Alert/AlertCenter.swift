//
//  AlertCenter.swift
//  FRW
//
//  A lightweight global SwiftUI-driven alert/confirmation sheet center.
//  Use from non-UI code via async APIs to await user decision.
//

import Foundation
import SwiftUI

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

    // Present a fully custom model (including custom content / actions)
    func present(model: AlertModel) async -> String {
        // Cancel any existing alert
        if continuation != nil {
            continuation?.resume(returning: "__cancelled__")
            continuation = nil
        }
        self.model = model

        return await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            self.continuation = cont
        }
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
    }

    // Resolve as cancelled
    func cancel() {
        resolve(selection: "cancel")
    }
}
